<?php

namespace App\Contracts\Services;

use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;

interface SubscriptionRequestServiceInterface
{
    // ── Admin-facing ──────────────────────────────────────────────────────────

    /**
     * Paginated list of ALL subscription requests.
     *
     * @param  array{status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Find a request by ID regardless of owner. Returns null if not found.
     */
    public function findById(int $id): ?SubscriptionRequest;

    /**
     * Approve a pending request: activates the merchant's subscription
     * and marks the request as approved.
     *
     * @throws \App\Exceptions\SubscriptionException  if the request was already reviewed
     */
    public function approve(SubscriptionRequest $request, User $admin): SubscriptionRequest;

    /**
     * Reject a pending request with a reason.
     *
     * @throws \App\Exceptions\SubscriptionException  if the request was already reviewed
     */
    public function reject(SubscriptionRequest $request, User $admin, string $reason): SubscriptionRequest;

    // ── Merchant-facing ──────────────────────────────────────────────────────

    /**
     * All requests submitted by the given merchant.
     */
    public function getForMerchant(User $merchant): Collection;

    /**
     * Find a specific request belonging to the given merchant.
     */
    public function findForMerchant(int $id, User $merchant): ?SubscriptionRequest;

    /**
     * Submit a new subscription request with an uploaded payment proof image.
     *
     * @throws \App\Exceptions\SubscriptionException  if the selected plan is not active
     */
    public function create(User $merchant, array $data, UploadedFile $proofImage): SubscriptionRequest;
}
