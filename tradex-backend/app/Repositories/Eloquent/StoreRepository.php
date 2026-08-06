<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\StoreRepositoryInterface;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Collection;

class StoreRepository implements StoreRepositoryInterface
{
    /**
     * Return all stores owned by the merchant, with product count.
     */
    public function getForMerchant(User $merchant): Collection
    {
        return Store::where('user_id', $merchant->id)
            ->withCount('products')
            ->orderBy('store_name')
            ->get();
    }

    /**
     * Find a store by ID that is owned by the given merchant.
     * Returns null if not found or not owned by this merchant.
     */
    public function findForMerchant(int $storeId, User $merchant): ?Store
    {
        return Store::where('id', $storeId)
            ->where('user_id', $merchant->id)
            ->withCount('products')
            ->first();
    }

    /**
     * Update store fields and return the refreshed record.
     */
    public function update(Store $store, array $data): Store
    {
        $store->update($data);

        return $store->fresh();
    }

    /**
     * Persist a new logo storage path and return the refreshed record.
     */
    public function updateLogo(Store $store, string $path): Store
    {
        $store->update(['logo' => $path]);

        return $store->fresh();
    }
}
