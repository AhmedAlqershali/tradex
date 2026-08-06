<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\ReviewServiceInterface;
use App\Exceptions\ReviewException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Review\StoreReviewRequest;
use App\Http\Resources\Review\ReviewCollection;
use App\Http\Resources\Review\ReviewResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Product reviews (client-facing).
 *
 * Public:
 *   GET /api/v1/products/{productId}/reviews        — list reviews for a product
 *
 * Authenticated (auth:sanctum + role:client):
 *   POST   /api/v1/products/{productId}/reviews     — submit a review
 *   DELETE /api/v1/reviews/{id}                     — delete own review
 */
class ReviewController extends BaseApiController
{
    public function __construct(
        private readonly ReviewServiceInterface $reviewService,
    ) {}

    // ── GET /api/v1/products/{productId}/reviews ──────────────────────────────

    /**
     * List paginated reviews for a product.
     *
     * Query parameters:
     *   per_page  int  — 1–100 (default: 15)
     */
    public function index(Request $request, int $productId): JsonResponse
    {
        try {
            $paginator = $this->reviewService->listForProduct(
                $productId,
                $request->only(['per_page']),
            );
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        }

        return $this->success(
            (new ReviewCollection($paginator))->toArray($request),
            'Reviews retrieved successfully.',
        );
    }

    // ── POST /api/v1/products/{productId}/reviews ─────────────────────────────

    /**
     * Submit a review for a product. One review per client per product.
     */
    public function store(StoreReviewRequest $request, int $productId): JsonResponse
    {
        try {
            $review = $this->reviewService->create(
                $request->user(),
                $productId,
                $request->validated(),
            );
        } catch (ModelNotFoundException) {
            return $this->notFound('Product not found.');
        } catch (ReviewException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->created(new ReviewResource($review), 'Review submitted successfully.');
    }

    // ── DELETE /api/v1/reviews/{id} ───────────────────────────────────────────

    /**
     * Delete a review (client may only delete their own).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $this->reviewService->delete($request->user(), $id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Review not found.');
        } catch (ReviewException $e) {
            return $this->forbidden($e->getMessage());
        }

        return $this->success(null, 'Review deleted successfully.');
    }
}
