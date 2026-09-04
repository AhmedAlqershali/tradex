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
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

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
            $images = $this->storeImages($product, $imageFiles);
            $this->productRepository->syncImages($product, $images);

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

        $oldPaths = [];
        $newPaths = [];
        $updatedProduct = $product;

        try {
            DB::transaction(function () use ($product, $updatable, $imageFiles, $data, &$oldPaths, &$newPaths, &$updatedProduct): void {
                $product = $this->productRepository->update($product, $updatable);
                $updatedProduct = $product;
                $product->load('images');
                $clearImages = filter_var($data['clear_images'] ?? false, FILTER_VALIDATE_BOOLEAN);

                if (! empty($imageFiles)) {
                    $existing = $product->images->map(fn ($image) => [
                        'path' => $image->path,
                        'sort_order' => $image->sort_order,
                    ])->all();
                    if ($clearImages) {
                        $oldPaths = $this->storedPaths($product);
                        $existing = [];
                    }
                    if (count($existing) + count($imageFiles) > 10) {
                        throw ValidationException::withMessages([
                            'images' => ['You may have a maximum of 10 product images.'],
                        ]);
                    }
                    $newPaths = $this->storeImages($product, $imageFiles, $existing);
                    $this->productRepository->syncImages($product, [...$existing, ...$newPaths]);
                    $product->refresh();
                    $product->image = $product->images()->orderBy('sort_order')->value('path');
                    $product->save();
                } elseif ($clearImages) {
                    $oldPaths = $this->storedPaths($product);
                    $this->productRepository->syncImages($product, []);
                    $product->image = null;
                    $product->save();
                }
            });
        } catch (\Throwable $exception) {
            foreach ($newPaths as $image) {
                Storage::disk('public')->delete($image['path']);
            }
            throw $exception;
        }

        foreach ($oldPaths as $path) {
            if (! in_array($path, array_column($newPaths, 'path'), true)) {
                Storage::disk('public')->delete($path);
            }
        }

        return $updatedProduct->load(['category', 'images']);
    }

    public function delete(Product $product): bool
    {
        $paths = $this->storedPaths($product->load('images'));
        $deleted = DB::transaction(fn () => $this->productRepository->delete($product));

        foreach ($paths as $path) {
            Storage::disk('public')->delete($path);
        }

        return $deleted;
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
    * Store uploaded files under products/{product_id}; DB records are synced
    * by the surrounding transaction.
     *
     * @param  UploadedFile[]  $files
     */
    private function storeImages(Product $product, array $files, array $existing = []): array
    {
        $images = [];
        $nextSortOrder = empty($existing)
            ? 0
            : max(array_column($existing, 'sort_order')) + 1;

        try {
            foreach ($files as $index => $file) {
                $path = $file->store("products/{$product->id}", 'public');

                if ($path === false || ! Storage::disk('public')->exists($path)) {
                    throw new \RuntimeException('Product image could not be persisted.');
                }

                $images[] = [
                    'path'       => $path,
                    'sort_order' => $nextSortOrder + $index,
                ];
            }
        } catch (\Throwable $exception) {
            foreach ($images as $image) {
                Storage::disk('public')->delete($image['path']);
            }
            throw $exception;
        }

        return $images;
    }

    /**
     * Delete all stored image files for a product from disk.
     * DB rows are handled separately (via syncImages or cascade delete).
     */
    private function storedPaths(Product $product): array
    {
        $paths = $product->images->pluck('path')->all();
        if ($product->image) {
            $paths[] = $product->image;
        }

        return array_values(array_unique(array_filter($paths)));
    }
}
