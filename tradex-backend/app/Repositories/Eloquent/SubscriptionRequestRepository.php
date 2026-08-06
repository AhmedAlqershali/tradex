<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\SubscriptionRequestRepositoryInterface;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

class SubscriptionRequestRepository implements SubscriptionRequestRepositoryInterface
{
    /**
     * Paginated list of ALL subscription requests — for admin review.
     *
     * Supported filters:
     *   status   — exact match (pending | approved | rejected)
     *   per_page — 1–100 (default: 20)
     */
    public function listAll(array $filters): LengthAwarePaginator
    {
        $query = SubscriptionRequest::with(['user', 'plan', 'reviewer']);

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 20), 100);

        return $query->latest()->paginate($perPage)->withQueryString();
    }

    /**
     * Find a request by ID regardless of owner.
     */
    public function findById(int $id): ?SubscriptionRequest
    {
        return SubscriptionRequest::with(['user', 'plan', 'reviewer'])->find($id);
    }

    /**
     * All requests submitted by the given merchant, most recent first.
     */
    public function getForMerchant(User $merchant): Collection
    {
        return SubscriptionRequest::where('user_id', $merchant->id)
            ->with('plan')
            ->latest()
            ->get();
    }

    /**
     * Find a specific request that belongs to the given merchant.
     */
    public function findForMerchant(int $id, User $merchant): ?SubscriptionRequest
    {
        return SubscriptionRequest::where('user_id', $merchant->id)
            ->with('plan')
            ->find($id);
    }

    /**
     * Create a new subscription request.
     */
    public function create(array $data): SubscriptionRequest
    {
        return SubscriptionRequest::create($data);
    }

    /**
     * Update a request's review fields and return the refreshed record.
     */
    public function update(SubscriptionRequest $request, array $data): SubscriptionRequest
    {
        $request->update($data);

        return $request->fresh(['user', 'plan', 'reviewer']);
    }
}
