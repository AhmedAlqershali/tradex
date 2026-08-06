<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\CategoryServiceInterface;
use App\Exceptions\CategoryException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Category\StoreCategoryRequest;
use App\Http\Requests\Category\UpdateCategoryRequest;
use App\Http\Resources\Category\CategoryCollection;
use App\Http\Resources\Category\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin category management.
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 * Full CRUD — list, create, view, update, delete.
 *
 * GET    /api/v1/admin/categories       — list all (any status)
 * POST   /api/v1/admin/categories       — create
 * GET    /api/v1/admin/categories/{id}  — show
 * PUT    /api/v1/admin/categories/{id}  — update
 * DELETE /api/v1/admin/categories/{id}  — delete (guarded: no products)
 */
class CategoryController extends BaseApiController
{
    public function __construct(
        private readonly CategoryServiceInterface $categoryService,
    ) {}

    // ── GET /api/v1/admin/categories ─────────────────────────────────────────

    /**
     * List all categories across all statuses.
     *
     * Query parameters:
     *   search    string  — partial name match
     *   status    string  — active | inactive
     *   per_page  int     — 1–100 (default: 20)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Category::class);

        $filters   = $request->only(['search', 'status', 'per_page']);
        $paginator = $this->categoryService->listAll($filters);

        return $this->success(
            (new CategoryCollection($paginator))->toArray($request),
            'Categories retrieved successfully.',
        );
    }

    // ── POST /api/v1/admin/categories ────────────────────────────────────────

    /**
     * Create a new category.
     *
     * Body (multipart/form-data):
     *   name    string  required  max:100  unique
     *   image   file    optional  image/jpeg,png,webp  max:2MB
     *   status  string  optional  active(default) | inactive
     */
    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $this->authorize('create', Category::class);

        $category = $this->categoryService->create(
            $request->validated(),
            $request->file('image'),
        );

        return $this->created(new CategoryResource($category), 'Category created successfully.');
    }

    // ── GET /api/v1/admin/categories/{id} ────────────────────────────────────

    /**
     * Show a single category by ID.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $category = $this->categoryService->findById($id);

        if (! $category) {
            return $this->notFound('Category not found.');
        }

        $this->authorize('view', $category);

        return $this->success(new CategoryResource($category), 'Category retrieved successfully.');
    }

    // ── PUT /api/v1/admin/categories/{id} ────────────────────────────────────

    /**
     * Update a category's name, image, and/or status.
     *
     * Body (multipart/form-data — all fields optional):
     *   name    string  max:100  unique (ignores self)
     *   image   file    image/jpeg,png,webp  max:2MB
     *   status  string  active | inactive
     */
    public function update(UpdateCategoryRequest $request, int $id): JsonResponse
    {
        $category = $this->categoryService->findById($id);

        if (! $category) {
            return $this->notFound('Category not found.');
        }

        $this->authorize('update', $category);

        $updated = $this->categoryService->update(
            $category,
            $request->validated(),
            $request->file('image'),
        );

        return $this->success(new CategoryResource($updated), 'Category updated successfully.');
    }

    // ── DELETE /api/v1/admin/categories/{id} ─────────────────────────────────

    /**
     * Delete a category.
     *
     * Returns 409 Conflict if any products are still assigned to this category.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $category = $this->categoryService->findById($id);

        if (! $category) {
            return $this->notFound('Category not found.');
        }

        $this->authorize('delete', $category);

        try {
            $this->categoryService->delete($category);
        } catch (CategoryException $e) {
            return $this->error($e->getMessage(), 409);
        }

        return $this->success(null, 'Category deleted successfully.');
    }
}
