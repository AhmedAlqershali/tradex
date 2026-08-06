<?php

namespace App\Policies;

use App\Models\Product;
use App\Models\User;

/**
 * Determines who can perform which product actions.
 *
 * Roles:
 *  - merchant : CRUD on their own store's products only
 *  - admin    : read-only on all products (monitoring)
 *  - client   : no access to merchant product management endpoints
 */
class ProductPolicy
{
    /**
     * List products.
     * Merchants and admins may list; clients may not.
     */
    public function viewAny(User $user): bool
    {
        return $user->isMerchant() || $user->isAdmin();
    }

    /**
     * View a single product.
     * Merchant: only if the product belongs to one of their stores.
     * Admin: always.
     */
    public function view(User $user, Product $product): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isMerchant()) {
            return $user->stores()->where('id', $product->store_id)->exists();
        }

        return false;
    }

    /**
     * Create a product.
     * Merchants only; store ownership is already validated in StoreProductRequest.
     */
    public function create(User $user): bool
    {
        return $user->isMerchant();
    }

    /**
     * Update a product.
     * Merchant must own the product's store.
     */
    public function update(User $user, Product $product): bool
    {
        if (! $user->isMerchant()) {
            return false;
        }

        return $user->stores()->where('id', $product->store_id)->exists();
    }

    /**
     * Delete a product.
     * Merchant must own the product's store.
     */
    public function delete(User $user, Product $product): bool
    {
        if (! $user->isMerchant()) {
            return false;
        }

        return $user->stores()->where('id', $product->store_id)->exists();
    }
}
