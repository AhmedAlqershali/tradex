<?php

namespace App\Contracts\Repositories;

use App\Models\Category;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface CategoryRepositoryInterface
{
    /**
     * Paginated list of ALL categories (any status) — admin use.
     *
     * @param  array{search?: string, status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Paginated list of active categories only — public / client use.
     *
     * @param  array{per_page?: int}  $filters
     */
    public function listActive(array $filters): LengthAwarePaginator;

    /**
     * Find a category by primary key regardless of status.
     */
    public function findById(int $id): ?Category;

    /**
     * Persist a new category record and return it.
     */
    public function create(array $data): Category;

    /**
     * Update a category and return the refreshed record.
     */
    public function update(Category $category, array $data): Category;

    /**
     * Permanently delete a category.
     */
    public function delete(Category $category): bool;
}
