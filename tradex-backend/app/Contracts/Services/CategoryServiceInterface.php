<?php

namespace App\Contracts\Services;

use App\Models\Category;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;

interface CategoryServiceInterface
{
    // ── Public / Client-facing ────────────────────────────────────────────────

    /**
     * Return a paginated list of active categories.
     *
     * @param  array{per_page?: int}  $filters
     */
    public function listActive(array $filters): LengthAwarePaginator;

    // ── Admin-facing ──────────────────────────────────────────────────────────

    /**
     * Return a paginated list of ALL categories (any status).
     *
     * @param  array{search?: string, status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Find a category by ID regardless of its status.
     * Returns null if not found.
     */
    public function findById(int $id): ?Category;

    /**
     * Create a new category, optionally with an uploaded image.
     */
    public function create(array $data, ?UploadedFile $image = null): Category;

    /**
     * Update a category's fields, optionally replacing the image.
     */
    public function update(Category $category, array $data, ?UploadedFile $image = null): Category;

    /**
     * Delete a category and its image from storage.
     *
     * @throws \App\Exceptions\CategoryException  if the category still has products
     */
    public function delete(Category $category): void;
}
