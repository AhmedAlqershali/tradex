<?php

namespace App\Contracts\Repositories;

use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Collection;

interface StoreRepositoryInterface
{
    /**
     * Return all stores owned by the given merchant, with product count.
     */
    public function getForMerchant(User $merchant): Collection;

    /**
     * Find a specific store that belongs to the given merchant.
     * Returns null if not found or if the merchant does not own it.
     */
    public function findForMerchant(int $storeId, User $merchant): ?Store;

    /**
     * Update store fields (store_name, description).
     */
    public function update(Store $store, array $data): Store;

    /**
     * Persist a new logo path and return the fresh store record.
     */
    public function updateLogo(Store $store, string $path): Store;
}
