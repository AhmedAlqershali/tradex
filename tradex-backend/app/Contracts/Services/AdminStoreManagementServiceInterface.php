<?php

namespace App\Contracts\Services;

use App\Models\Store;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface AdminStoreManagementServiceInterface
{
    /**
     * Paginated store list with optional search (name) and status filter.
     * Eager-loads the store owner.
     */
    public function listStores(array $filters): LengthAwarePaginator;

    /**
     * Find a single store by ID with owner and product summary.
     * Returns null if not found.
     */
    public function findById(int $id): ?Store;

    /**
     * Update a store's status (active | inactive | suspended).
     */
    public function updateStatus(Store $store, string $status): Store;
}
