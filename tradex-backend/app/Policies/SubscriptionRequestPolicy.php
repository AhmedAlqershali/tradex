<?php

namespace App\Policies;

use App\Models\SubscriptionRequest;
use App\Models\User;

/**
 * Governs subscription request access.
 *
 * Roles:
 *  - merchant : create requests; view only their own
 *  - admin    : view all; approve/reject any pending request
 *  - client   : no access
 *
 * Auto-discovered by Laravel: App\Models\SubscriptionRequest → App\Policies\SubscriptionRequestPolicy.
 */
class SubscriptionRequestPolicy
{
    /**
     * List all requests — admin only (merchants list their own via a
     * separate, ownership-scoped Merchant\SubscriptionRequestController).
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * View a single request.
     * Admin sees any; merchant must own it.
     */
    public function view(User $user, SubscriptionRequest $request): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->isMerchant() && $request->user_id === $user->id;
    }

    /**
     * Submit a new request.
     */
    public function create(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Approve a request.
     */
    public function approve(User $user, SubscriptionRequest $request): bool
    {
        return $user->isAdmin();
    }

    /**
     * Reject a request.
     */
    public function reject(User $user, SubscriptionRequest $request): bool
    {
        return $user->isAdmin();
    }
}
