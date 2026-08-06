<?php

namespace App\Policies;

use App\Models\Store;
use App\Models\User;

/**
 * Governs which users may perform which store actions.
 *
 * Roles:
 *  - merchant : view and update only their own store(s)
 *  - admin    : full visibility (handled in Admin\StoreController — Phase 2 Step 4)
 *  - client   : no access to merchant/admin store management routes
 *
 * Auto-discovered by Laravel: App\Models\Store → App\Policies\StorePolicy.
 */
class StorePolicy
{
    /**
     * List stores.
     * Merchants may list their own; admins get their own controller.
     */
    public function viewAny(User $user): bool
    {
        return $user->isMerchant() || $user->isAdmin();
    }

    /**
     * View a single store.
     * Merchant must own the store.
     */
    public function view(User $user, Store $store): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->isMerchant() && $store->user_id === $user->id;
    }

    /**
     * Update store info or logo.
     * Merchant must own the store; admins cannot update through merchant routes.
     */
    public function update(User $user, Store $store): bool
    {
        return $user->isMerchant() && $store->user_id === $user->id;
    }

    /**
     * Admin-only: change a store's status (active / inactive / suspended).
     */
    public function updateStatus(User $user, Store $store): bool
    {
        return $user->isAdmin();
    }
}
