<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\SubscriptionRequestServiceInterface;
use App\Exceptions\SubscriptionException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Subscription\RejectSubscriptionRequestRequest;
use App\Http\Resources\Subscription\SubscriptionRequestCollection;
use App\Http\Resources\Subscription\SubscriptionRequestResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin subscription request management.
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 *
 * GET /api/v1/admin/subscription-requests              — paginated list
 * GET /api/v1/admin/subscription-requests/{id}         — single request detail
 * PUT /api/v1/admin/subscription-requests/{id}/approve — approve
 * PUT /api/v1/admin/subscription-requests/{id}/reject  — reject with reason
 */
class SubscriptionRequestController extends BaseApiController
{
    public function __construct(
        private readonly SubscriptionRequestServiceInterface $subscriptionRequestService,
    ) {}

    // ── GET /api/v1/admin/subscription-requests ───────────────────────────────

    /**
     * Paginated list of all subscription requests.
     *
     * Query parameters:
     *   status    string  — pending | approved | rejected
     *   per_page  int     — 1–100 (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $paginator = $this->subscriptionRequestService->listAll(
            $request->only(['status', 'per_page']),
        );

        return $this->success(
            (new SubscriptionRequestCollection($paginator))->toArray($request),
            'Subscription requests retrieved successfully.',
        );
    }

    // ── GET /api/v1/admin/subscription-requests/{id} ─────────────────────────

    public function show(int $id): JsonResponse
    {
        $subscriptionRequest = $this->subscriptionRequestService->findById($id);

        if (! $subscriptionRequest) {
            return $this->notFound('Subscription request not found.');
        }

        $subscriptionRequest->loadMissing(['plan', 'user', 'reviewer']);

        return $this->success(
            new SubscriptionRequestResource($subscriptionRequest),
            'Subscription request retrieved successfully.',
        );
    }

    // ── PUT /api/v1/admin/subscription-requests/{id}/approve ──────────────────

    public function approve(Request $request, int $id): JsonResponse
    {
        $subscriptionRequest = $this->subscriptionRequestService->findById($id);

        if (! $subscriptionRequest) {
            return $this->notFound('Subscription request not found.');
        }

        try {
            $updated = $this->subscriptionRequestService->approve(
                $subscriptionRequest,
                $request->user(),
            );
        } catch (SubscriptionException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $updated->loadMissing(['plan', 'user', 'reviewer']);

        return $this->success(
            new SubscriptionRequestResource($updated),
            'Subscription request approved. Merchant subscription activated.',
        );
    }

    // ── PUT /api/v1/admin/subscription-requests/{id}/reject ───────────────────

    public function reject(RejectSubscriptionRequestRequest $request, int $id): JsonResponse
    {
        $subscriptionRequest = $this->subscriptionRequestService->findById($id);

        if (! $subscriptionRequest) {
            return $this->notFound('Subscription request not found.');
        }

        try {
            $updated = $this->subscriptionRequestService->reject(
                $subscriptionRequest,
                $request->user(),
                $request->validated('rejection_reason'),
            );
        } catch (SubscriptionException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $updated->loadMissing(['plan', 'user', 'reviewer']);

        return $this->success(
            new SubscriptionRequestResource($updated),
            'Subscription request rejected.',
        );
    }
}
