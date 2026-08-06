<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\ProductServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Product\ProductCollection;
use App\Http\Resources\Product\ProductResource;
use App\Models\Product;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin product monitoring (read-only).
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 */
class ProductController extends BaseApiController
{
    public function __construct(
        private readonly ProductServiceInterface $productService,
    ) {}

    /**
     * GET /api/v1/admin/products
     *
     * List all products across all stores.
     *
     * Query parameters:
     *   search       string
     *   category_id  int
     *   status       string   — active | inactive | out_of_stock
     *   sort_by      string   — name | price | quantity | created_at | status
     *   sort_dir     string   — asc | desc
     *   per_page     int      — 1–100  (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Product::class);

        $filters    = $request->only(['search', 'category_id', 'status', 'sort_by', 'sort_dir', 'per_page']);
        $paginator  = $this->productService->listAll($filters);
        $collection = new ProductCollection($paginator);

        return $this->success($collection->toArray($request), 'All products retrieved successfully.');
    }

    /**
     * GET /api/v1/admin/products/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $this->authorize('viewAny', Product::class);

        try {
            $product = $this->productService->findById($id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        return $this->success(new ProductResource($product), 'Product retrieved successfully.');
    }
}
