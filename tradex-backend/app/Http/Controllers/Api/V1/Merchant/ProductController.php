<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Contracts\Services\ProductServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Product\StoreProductRequest;
use App\Http\Requests\Product\UpdateProductRequest;
use App\Http\Resources\Product\ProductCollection;
use App\Http\Resources\Product\ProductResource;
use App\Models\Product;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Merchant product management.
 *
 * All routes are behind auth:sanctum + role:merchant middleware.
 * Ownership is enforced by ProductPolicy and the service layer.
 */
class ProductController extends BaseApiController
{
    public function __construct(
        private readonly ProductServiceInterface $productService,
    ) {}

    // -------------------------------------------------------------------------
    // GET /api/v1/merchant/products
    // -------------------------------------------------------------------------

    /**
     * List the authenticated merchant's products.
     *
     * Query parameters:
     *   search       string   — searches name + description
     *   category_id  int      — filter by category
     *   status       string   — active | inactive | out_of_stock
     *   sort_by      string   — name | price | quantity | created_at | status  (default: created_at)
     *   sort_dir     string   — asc | desc  (default: desc)
     *   per_page     int      — 1–100  (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Product::class);

        $filters    = $request->only(['search', 'category_id', 'status', 'sort_by', 'sort_dir', 'per_page']);
        $paginator  = $this->productService->listForMerchant($request->user(), $filters);
        $collection = new ProductCollection($paginator);

        return $this->success($collection->toArray($request), 'Products retrieved successfully.');
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/merchant/products
    // -------------------------------------------------------------------------

    public function store(StoreProductRequest $request): JsonResponse
    {
        $this->authorize('create', Product::class);

        $product = $this->productService->create(
            $request->user(),
            $request->validated(),
            $request->file('images', []),
        );

        return $this->created(
            new ProductResource($product),
            'Product created successfully.'
        );
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/merchant/products/{product}
    // -------------------------------------------------------------------------

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $product = $this->productService->findForMerchant($id, $request->user());
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        $this->authorize('view', $product);

        return $this->success(new ProductResource($product), 'Product retrieved successfully.');
    }

    // -------------------------------------------------------------------------
    // PUT /api/v1/merchant/products/{product}
    // -------------------------------------------------------------------------

    public function update(UpdateProductRequest $request, int $id): JsonResponse
    {
        try {
            $product = $this->productService->findForMerchant($id, $request->user());
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        $this->authorize('update', $product);

        $product = $this->productService->update(
            $product,
            $request->validated(),
            $request->file('images', []),
        );

        return $this->success(new ProductResource($product), 'Product updated successfully.');
    }

    // -------------------------------------------------------------------------
    // DELETE /api/v1/merchant/products/{product}
    // -------------------------------------------------------------------------

    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $product = $this->productService->findForMerchant($id, $request->user());
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        $this->authorize('delete', $product);

        $this->productService->delete($product);

        return $this->success(null, 'Product deleted successfully.');
    }
}
