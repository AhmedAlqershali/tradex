<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\ProductRepositoryInterface;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductRepository implements ProductRepositoryInterface
{
    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public function getForMerchant(User $user, array $filters): LengthAwarePaginator
    {
        // Gather all store IDs belonging to this merchant
        $storeIds = $user->stores()->pluck('id');

        $query = Product::with(['category', 'images'])
            ->whereIn('store_id', $storeIds);

        $this->applyFilters($query, $filters);

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->paginate($perPage)->withQueryString();
    }

    public function getAllPaginated(array $filters): LengthAwarePaginator
    {
        $query = Product::with(['store', 'category', 'images']);

        $this->applyFilters($query, $filters);

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->paginate($perPage)->withQueryString();
    }

    public function findByIdForMerchant(int $id, User $user): ?Product
    {
        $storeIds = $user->stores()->pluck('id');

        return Product::with(['category', 'images'])
            ->whereIn('store_id', $storeIds)
            ->find($id);
    }

    public function findById(int $id): ?Product
    {
        return Product::with(['store', 'category', 'images'])->find($id);
    }

    // ── Client marketplace ────────────────────────────────────────────────────

    public function getForClient(array $filters): LengthAwarePaginator
    {
        $query = Product::with(['store', 'category', 'images'])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('status', 'active')
            ->where('quantity', '>', 0)
            ->whereHas('store', fn ($q) => $q->where('status', 'active'));

        // Search by product name and description
        if (! empty($filters['search'])) {
            $term = '%'.$filters['search'].'%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                  ->orWhere('description', 'like', $term);
            });
        }

        // Filter by category
        if (! empty($filters['category_id'])) {
            $query->where('category_id', (int) $filters['category_id']);
        }

        // Filter by store
        if (! empty($filters['store_id'])) {
            $query->where('store_id', (int) $filters['store_id']);
        }

        // Price range
        if (isset($filters['price_min'])) {
            $query->where('price', '>=', (float) $filters['price_min']);
        }
        if (isset($filters['price_max'])) {
            $query->where('price', '<=', (float) $filters['price_max']);
        }

        // Sorting
        $sort = $filters['sort'] ?? 'newest';
        match ($sort) {
            'oldest'     => $query->orderBy('created_at'),
            'price_asc'  => $query->orderBy('price'),
            'price_desc' => $query->orderByDesc('price'),
            default      => $query->orderByDesc('created_at'), // newest
        };

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->paginate($perPage)->withQueryString();
    }

    public function findActiveById(int $id): ?Product
    {
        return Product::with(['store', 'category', 'images'])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->where('status', 'active')
            ->where('quantity', '>', 0)
            ->whereHas('store', fn ($q) => $q->where('status', 'active'))
            ->find($id);
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    /**
     * Create a new product.
     *
     * SECURITY: `store_id` and `total_sold` are excluded from Product::$fillable
     * to prevent merchants from assigning products to stores they don't own or
     * manipulating the sold counter. forceCreate() is used here because this is
     * trusted repository code that has already validated ownership in the service
     * layer (store_id verified via StoreProductRequest ownership rule).
     */
    public function create(array $data): Product
    {
        return Product::forceCreate([
            'store_id'    => $data['store_id'],
            'category_id' => $data['category_id'] ?? null,
            'name'        => $data['name'],
            'description' => $data['description'] ?? null,
            'price'       => $data['price'],
            'quantity'    => $data['quantity'],
            'status'      => $data['status'] ?? 'active',
            'image'       => $data['image'] ?? null,
        ]);
    }

    /**
     * Update product fields.
     * Only mutable merchant fields are accepted; store_id and total_sold are
     * never updated through this path.
     */
    public function update(Product $product, array $data): Product
    {
        $product->update($data);

        return $product->fresh();
    }

    public function delete(Product $product): bool
    {
        return (bool) $product->delete();
    }

    /**
     * Sync (replace) all product images.
     * Deletes existing image records and inserts the new set.
     */
    public function syncImages(Product $product, array $images): void
    {
        $product->images()->delete();

        if (! empty($images)) {
            $product->images()->createMany($images);
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function applyFilters($query, array $filters): void
    {
        if (! empty($filters['search'])) {
            $term = '%' . $filters['search'] . '%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                  ->orWhere('description', 'like', $term);
            });
        }

        if (! empty($filters['category_id'])) {
            $query->where('category_id', (int) $filters['category_id']);
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['sort_by'])) {
            $allowedSorts = ['name', 'price', 'quantity', 'created_at', 'status'];
            $sortBy  = in_array($filters['sort_by'], $allowedSorts, true) ? $filters['sort_by'] : 'created_at';
            $sortDir = ($filters['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc';
            $query->orderBy($sortBy, $sortDir);
        } else {
            $query->orderByDesc('created_at');
        }
    }
}
