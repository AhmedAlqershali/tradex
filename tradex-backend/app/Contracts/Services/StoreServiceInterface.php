<?php

namespace App\Contracts\Services;

use App\Models\Store;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;

interface StoreServiceInterface
{
    // ── Public / Client-facing ────────────────────────────────────────────────

    /**
     * Return a paginated list of active stores, including product count.
     *
     * @param  array{per_page?: int}  $filters
     */
    public function listActive(array $filters): LengthAwarePaginator;

    /**
     * Find a single active store by ID, including its products count.
     * Returns null if not found or not active.
     */
    public function findActive(int $id): ?Store;

    public function listActiveProducts(int $storeId, int $perPage = 15): LengthAwarePaginator;

    public function follow(User $client, int $storeId): void;

    public function unfollow(User $client, int $storeId): void;

    // ── Merchant-facing ───────────────────────────────────────────────────────

    /**
     * Return all stores owned by the given merchant, with product count.
     */
    public function getForMerchant(User $merchant): Collection;

    /**
     * Return the merchant's existing store, or create their first store.
     */
    public function createForMerchant(User $merchant, array $data): Store;

    /**
     * Find a specific store that belongs to the given merchant.
     * Returns null if not found or if the merchant does not own it.
     */
    public function findForMerchant(int $storeId, User $merchant): ?Store;

    /**
     * Update store profile fields (store_name, description).
     */
    public function updateStore(Store $store, array $data): Store;

    /**
     * Upload a new logo image, delete the old one, and persist the new path.
     */
    public function updateStoreLogo(Store $store, UploadedFile $file): Store;
}
