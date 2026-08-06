<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\ReviewServiceInterface;
use App\Exceptions\ReviewException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Review\ReviewCollection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin review moderation.
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 *
 * GET    /api/v1/admin/products/{productId}/reviews  — list reviews for any product
 * DELETE /api/v1/admin/reviews/{id}                 — delete any review
 */
class ReviewController extends BaseApiController
{
    public function __construct(
        private readonly ReviewServiceInterface $reviewService,
    ) {}

    // ── GET /api/v1/admin/products/{productId}/reviews ────────────────────────

    public function index(Request $request, int $productId): JsonResponse
    {
        try {
            // Admin can view reviews for any product regardless of status
            $paginator = $this->reviewService->listForAnyProduct(
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

    // ── DELETE /api/v1/admin/reviews/{id} ─────────────────────────────────────

    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            $this->reviewService->delete($request->user(), $id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Review not found.');
        } catch (ReviewException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success(null, 'Review deleted successfully.');
    }
}
