<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\CategoryRepositoryInterface;
use App\Models\Category;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class CategoryRepository implements CategoryRepositoryInterface
{
    /**
     * Paginated list of ALL categories — for admin management.
     *
     * Supported filters:
     *   search   — partial match on name
     *   status   — exact match (active | inactive)
     *   per_page — 1–100 (default: 20)
     */
    public function listAll(array $filters): LengthAwarePaginator
    {
        $query = Category::withCount('products');

        if (! empty($filters['search'])) {
            $query->where('name', 'like', '%' . $filters['search'] . '%');
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 20), 100);

        return $query->orderBy('name')->paginate($perPage)->withQueryString();
    }

    /**
     * Paginated list of active categories — for the public marketplace.
     */
    public function listActive(array $filters): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 20), 100);

        $query = Category::active();

        if (! empty($filters['search'])) {
            $query->where('name', 'like', '%' . $filters['search'] . '%');
        }

        return $query->orderBy('name')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Find a category by ID regardless of its status.
     */
    public function findById(int $id): ?Category
    {
        return Category::withCount('products')->find($id);
    }

    /**
     * Create a new category record.
     */
    public function create(array $data): Category
    {
        return Category::create($data);
    }

    /**
     * Update a category and return the refreshed record with product count.
     */
    public function update(Category $category, array $data): Category
    {
        $category->update($data);

        return $category->fresh();
    }

    /**
     * Permanently delete a category record.
     */
    public function delete(Category $category): bool
    {
        return (bool) $category->delete();
    }
}
