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
     * Mark all of the merchant's currently active subscriptions as
     * 'cancelled' (history is preserved — rows are not deleted).
     */
    public function cancelActiveForUser(User $user): void;

    /**
     * Persist a new subscription record and return it.
     */
    public function create(array $data): Subscription;
}
