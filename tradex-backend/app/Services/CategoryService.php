<?php

namespace App\Services;

use App\Contracts\Repositories\CategoryRepositoryInterface;
use App\Contracts\Services\CategoryServiceInterface;
use App\Exceptions\CategoryException;
use App\Models\Category;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class CategoryService implements CategoryServiceInterface
{
    public function __construct(
        private readonly CategoryRepositoryInterface $categoryRepository,
    ) {}

    // ── Public / Client-facing ────────────────────────────────────────────────

    /**
     * Return a paginated list of active categories, ordered by name.
     *
     * @param  array{per_page?: int}  $filters
     */
    public function listActive(array $filters): LengthAwarePaginator
    {
        return $this->categoryRepository->listActive($filters);
    }

    // ── Admin-facing ──────────────────────────────────────────────────────────

    /**
     * Return a paginated list of ALL categories (any status) with product count.
     *
     * @param  array{search?: string, status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator
    {
        return $this->categoryRepository->listAll($filters);
    }

    /**
     * Find a category by ID regardless of its status.
     * Returns null if not found.
     */
    public function findById(int $id): ?Category
    {
        return $this->categoryRepository->findById($id);
    }

    /**
     * Create a new category, uploading the image to storage if provided.
     */
    public function create(array $data, ?UploadedFile $image = null): Category
    {
        if ($image) {
            $data['image'] = $image->store('categories', 'public');
        }

        // Default status to active when not provided
        $data['status'] ??= 'active';

        return $this->categoryRepository->create($data);
    }

    /**
     * Update a category, replacing the image in storage if a new one is provided.
     *
     * Old image is deleted only after the new one is successfully stored,
     * so a failed upload never leaves the category without an image.
     */
    public function update(Category $category, array $data, ?UploadedFile $image = null): Category
    {
        if ($image) {
            $newPath = $image->store('categories', 'public');

            // Delete the old image only after the new one is safely stored
            if ($category->image && Storage::disk('public')->exists($category->image)) {
                Storage::disk('public')->delete($category->image);
            }

            $data['image'] = $newPath;
        }

        return $this->categoryRepository->update($category, $data);
    }

    /**
     * Delete a category and its image file.
     *
     * Refuses deletion if any products are still assigned — the caller
     * receives a CategoryException and should surface it as a 409.
     *
     * @throws \App\Exceptions\CategoryException
     */
    public function delete(Category $category): void
    {
        $productCount = $category->products()->count();

        if ($productCount > 0) {
            throw CategoryException::hasProducts($category->name, $productCount);
        }

        // Remove the category image from storage (best-effort)
        if ($category->image && Storage::disk('public')->exists($category->image)) {
            Storage::disk('public')->delete($category->image);
        }

        $this->categoryRepository->delete($category);
    }
}
