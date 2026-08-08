<?php

namespace App\Contracts\Repositories;

use App\Models\Subscription;
use App\Models\User;

interface SubscriptionRepositoryInterface
{
    /**
     * Find the merchant's current active subscription, if any.
     */
    public function findActiveForUser(User $user): ?Subscription;

    /**
     * Find the latest subscription period, regardless of status.
     */
    public function findLatestForUser(User $user): ?Subscription;

    /**
     * Mark a stale active period as expired while preserving its history.
     */
    public function markExpired(Subscription $subscription): Subscription;

    /**
     * Mark all of the merchant's currently active subscriptions as
     * 'cancelled' (history is preserved — rows are not deleted).
     */
    public function cancelActiveForUser(User $user): void;

    /**
     * Persist a new subscription record and return it.
     */
    public function create(array $data): Subscription;
}
