<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\CategoryServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Category\CategoryCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client-facing Categories API.
 *
 * Public — no authentication required.
 * GET /api/v1/categories
 */
class CategoryController extends BaseApiController
{
    public function __construct(
        private readonly CategoryServiceInterface $categoryService,
    ) {}

    // -------------------------------------------------------------------------
    // GET /api/v1/categories
    // -------------------------------------------------------------------------

    /**
     * List all active categories.
     *
     * Query parameters:
     *   per_page  int     — 1–100 (default: 20)
     *   search    string  — partial match on category name (optional)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'search'   => ['nullable', 'string', 'max:100'],
        ]);

        $filters    = $request->only(['per_page', 'search']);
        $paginator  = $this->categoryService->listActive($filters);
        $collection = new CategoryCollection($paginator);

        return $this->success($collection->toArray($request), 'Categories retrieved successfully.');
    }
}
