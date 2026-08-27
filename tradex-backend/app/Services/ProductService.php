<?php

namespace App\Services;

use App\Contracts\Repositories\ProductRepositoryInterface;
use App\Contracts\Services\ProductServiceInterface;
use App\Models\Product;
use App\Models\User;
use App\Models\StoreFollow;
use App\Contracts\Services\UserNotificationServiceInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ProductService implements ProductServiceInterface
{
    public function __construct(
        private readonly ProductRepositoryInterface $productRepository,
        private readonly UserNotificationServiceInterface $notificationService,
    ) {}

    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public function listForMerchant(User $user, array $filters): LengthAwarePaginator
    {
        return $this->productRepository->getForMerchant($user, $filters);
    }

    public function listAll(array $filters): LengthAwarePaginator
    {
        return $this->productRepository->getAllPaginated($filters);
    }

    public function findForMerchant(int $id, User $user): Product
    {
        $product = $this->productRepository->findByIdForMerchant($id, $user);

        if (! $product) {
            throw new ModelNotFoundException("Product #{$id} not found.");
        }

        return $product;
    }

    public function findById(int $id): Product
    {
        $product = $this->productRepository->findById($id);

        if (! $product) {
            throw new ModelNotFoundException("Product #{$id} not found.");
        }

        return $product;
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    public function create(User $user, array $data, array $imageFiles = []): Product
    {
        $product = $this->productRepository->create([
            'store_id'    => $data['store_id'],
            'category_id' => $data['category_id'] ?? null,
            'name'        => $data['name'],
            'description' => $data['description'] ?? null,
            'price'       => $data['price'],
            'quantity'    => $data['quantity'],
            'status'      => $data['status'] ?? 'active',
            'image'       => null, // will be set by syncImages if files provided
        ]);

        if (! empty($imageFiles)) {
            $this->storeImages($product, $imageFiles);

            // Set the product's primary image field to the first stored path
            // so clients have a quick-access thumbnail without joining product_images.
            $product->refresh();
            $firstImage = $product->images()->orderBy('sort_order')->first();
            if ($firstImage) {
                $product->image = $firstImage->path;
                $product->save();
            }
        }

        $product = $product->load(['category', 'images', 'store']);

        try {
            StoreFollow::query()
                ->where('store_id', $product->store_id)
                ->with('user')
                ->get()
                ->each(function (StoreFollow $follow) use ($product): void {
                    if ($follow->user) {
                        try {
                            $this->notificationService->create(
                                $follow->user,
                                'new_product',
                                'منتج جديد في متجر تتابعه',
                                "أضاف متجر {$product->store->store_name} المنتج {$product->name}.",
                                [
                                    'store_id' => $product->store_id,
                                    'product_id' => $product->id,
                                ],
                            );
                        } catch (\Throwable) {
                            // A single failed notification must not block other followers.
                        }
                    }
                });
        } catch (\Throwable) {
            // Notification delivery must never roll back a valid product creation.
        }

        return $product;
    }

    public function update(Product $product, array $data, array $imageFiles = []): Product
    {
        $updatable = array_intersect_key($data, array_flip([
            'category_id',
            'name',
            'description',
            'price',
            'quantity',
            'status',
        ]));

        $product = $this->productRepository->update($product, $updatable);

        // Handle image update
        if (! empty($imageFiles)) {
            // Delete old images from disk when replacing
            $this->deleteStoredImages($product);
            $this->storeImages($product, $imageFiles);
            $product->refresh();
            $firstImage = $product->images()->orderBy('sort_order')->first();
            $product->image = $firstImage?->path;
            $product->save();
        } elseif (! empty($data['clear_images'])) {
            $this->deleteStoredImages($product);
            $this->productRepository->syncImages($product, []);
            $product->image = null;
            $product->save();
        }

        return $product->load(['category', 'images']);
    }

    public function delete(Product $product): bool
    {
        // Remove images from disk before deleting the model
        $this->deleteStoredImages($product);

        return $this->productRepository->delete($product);
    }

    // ── Client marketplace ────────────────────────────────────────────────────

    public function listForClient(array $filters): LengthAwarePaginator
    {
        return $this->productRepository->getForClient($filters);
    }

    public function findActiveById(int $id): Product
    {
        $product = $this->productRepository->findActiveById($id);

        if (! $product) {
            throw new ModelNotFoundException("Product #{$id} not found.");
        }

        return $product;
    }

    // -------------------------------------------------------------------------
    // Image helpers
    // -------------------------------------------------------------------------

    /**
     * Store uploaded files under products/{product_id}/ and sync the DB records.
     *
     * @param  UploadedFile[]  $files
     */
    private function storeImages(Product $product, array $files): void
    {
        $images = [];

        foreach ($files as $index => $file) {
            $path = $file->store("products/{$product->id}", 'public');

            $images[] = [
                'path'       => $path,
                'sort_order' => $index,
            ];
        }

        $this->productRepository->syncImages($product, $images);
    }

    /**
     * Delete all stored image files for a product from disk.
     * DB rows are handled separately (via syncImages or cascade delete).
     */
    private function deleteStoredImages(Product $product): void
    {
        $product->load('images');

        foreach ($product->images as $image) {
            Storage::disk('public')->delete($image->path);
        }
    }
}
