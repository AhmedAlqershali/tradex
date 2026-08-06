<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\ProductServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Product\ProductCollection;
use App\Http\Resources\Product\ProductResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client-facing Products browsing API.
 *
 * Public — no authentication required.
 * GET /api/v1/products
 * GET /api/v1/products/{id}
 */
class ProductController extends BaseApiController
{
    public function __construct(
        private readonly ProductServiceInterface $productService,
    ) {}

    // -------------------------------------------------------------------------
    // GET /api/v1/products
    // -------------------------------------------------------------------------

    /**
     * Browse active products with filtering, sorting, and pagination.
     *
     * Query parameters:
     *   category_id  int     — filter by category
     *   store_id     int     — filter by store
     *   price_min    float   — minimum price (inclusive)
     *   price_max    float   — maximum price (inclusive)
     *   search       string  — search in product name
     *   sort         string  — newest | oldest | price_asc | price_desc  (default: newest)
     *   per_page     int     — 1–100  (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'category_id' => ['nullable', 'integer', 'min:1'],
            'store_id'    => ['nullable', 'integer', 'min:1'],
            'price_min'   => ['nullable', 'numeric', 'min:0'],
            'price_max'   => ['nullable', 'numeric', 'min:0', 'gte:price_min'],
            'search'      => ['nullable', 'string', 'max:100'],
            'sort'        => ['nullable', 'string', 'in:newest,oldest,price_asc,price_desc'],
            'per_page'    => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $filters    = $request->only(['category_id', 'store_id', 'price_min', 'price_max', 'search', 'sort', 'per_page']);
        $paginator  = $this->productService->listForClient($filters);
        $collection = new ProductCollection($paginator);

        return $this->success($collection->toArray($request), 'Products retrieved successfully.');
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/products/{id}
    // -------------------------------------------------------------------------

    /**
     * Show a single active product with its images, store, and category.
     */
    public function show(int $id): JsonResponse
    {
        try {
            $product = $this->productService->findActiveById($id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        return $this->success(new ProductResource($product), 'Product retrieved successfully.');
    }
}
