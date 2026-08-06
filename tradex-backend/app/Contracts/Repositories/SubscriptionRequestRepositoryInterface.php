<?php

namespace App\Contracts\Repositories;

use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface SubscriptionRequestRepositoryInterface
{
    /**
     * Paginated list of ALL subscription requests — admin use.
     *
     * @param  array{status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Find a request by ID regardless of owner — admin use.
     */
    public function findById(int $id): ?SubscriptionRequest;

    /**
     * All requests submitted by the given merchant, most recent first.
     */
    public function getForMerchant(User $merchant): Collection;

    /**
     * Find a specific request that belongs to the given merchant.
     */
    public function findForMerchant(int $id, User $merchant): ?SubscriptionRequest;

    /**
     * Persist a new subscription request and return it.
     */
    public function create(array $data): SubscriptionRequest;

    /**
     * Update a request's review fields (status, rejection_reason,
     * reviewed_by, reviewed_at) and return the refreshed record.
     */
    public function update(SubscriptionRequest $request, array $data): SubscriptionRequest;
}
