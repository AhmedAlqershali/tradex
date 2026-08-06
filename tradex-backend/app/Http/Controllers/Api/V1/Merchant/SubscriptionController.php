<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Contracts\Services\SubscriptionRequestServiceInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Exceptions\SubscriptionException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Subscription\StoreSubscriptionRequestRequest;
use App\Http\Resources\Subscription\SubscriptionRequestCollection;
use App\Http\Resources\Subscription\SubscriptionRequestResource;
use App\Http\Resources\Subscription\SubscriptionResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Merchant subscription management.
 *
 * All routes are behind auth:sanctum + role:merchant middleware.
 *
 * GET  /api/v1/merchant/subscription              — current active subscription
 * GET  /api/v1/merchant/subscription-requests     — own subscription requests
 * GET  /api/v1/merchant/subscription-requests/{id} — specific request detail
 * POST /api/v1/merchant/subscription-requests     — submit new request
 */
class SubscriptionController extends BaseApiController
{
    public function __construct(
        private readonly SubscriptionServiceInterface        $subscriptionService,
        private readonly SubscriptionRequestServiceInterface $subscriptionRequestService,
    ) {}

    // ── GET /api/v1/merchant/subscription ─────────────────────────────────────

    /**
     * Get the merchant's current active subscription, if any.
     */
    public function show(Request $request): JsonResponse
    {
        $subscription = $this->subscriptionService->getActiveForMerchant($request->user());

        if (! $subscription) {
            return $this->success(null, 'No active subscription found.');
        }

        $subscription->loadMissing('plan');

        return $this->success(
            new SubscriptionResource($subscription),
            'Active subscription retrieved successfully.',
        );
    }

    // ── GET /api/v1/merchant/subscription-requests ────────────────────────────

    /**
     * List all subscription requests submitted by the authenticated merchant.
     */
    public function indexRequests(Request $request): JsonResponse
    {
        $requests = $this->subscriptionRequestService->getForMerchant($request->user());

        return $this->success(
            SubscriptionRequestResource::collection($requests->load(['plan', 'user'])),
            'Subscription requests retrieved successfully.',
        );
    }

    // ── GET /api/v1/merchant/subscription-requests/{id} ──────────────────────

    /**
     * Show a specific subscription request belonging to the merchant.
     */
    public function showRequest(Request $request, int $id): JsonResponse
    {
        $subscriptionRequest = $this->subscriptionRequestService->findForMerchant($id, $request->user());

        if (! $subscriptionRequest) {
            return $this->notFound('Subscription request not found.');
        }

        $subscriptionRequest->loadMissing(['plan', 'user']);

        return $this->success(
            new SubscriptionRequestResource($subscriptionRequest),
            'Subscription request retrieved successfully.',
        );
    }

    // ── POST /api/v1/merchant/subscription-requests ───────────────────────────

    /**
     * Submit a new subscription request with payment proof.
     */
    public function storeRequest(StoreSubscriptionRequestRequest $request): JsonResponse
    {
        try {
            $subscriptionRequest = $this->subscriptionRequestService->create(
                $request->user(),
                $request->validated(),
                $request->file('payment_proof_image'),
            );
        } catch (SubscriptionException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $subscriptionRequest->loadMissing('plan');

        return $this->created(
            new SubscriptionRequestResource($subscriptionRequest),
            'Subscription request submitted successfully. Please wait for admin review.',
        );
    }
}
