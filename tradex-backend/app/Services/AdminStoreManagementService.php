<?php

namespace App\Services;

use App\Contracts\Services\AdminStoreManagementServiceInterface;
use App\Models\Store;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AdminStoreManagementService implements AdminStoreManagementServiceInterface
{
    /** Allowed status values for a store. */
    public const STATUSES = ['active', 'inactive', 'suspended'];

    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public function listStores(array $filters): LengthAwarePaginator
    {
        $query = Store::with(['owner:id,name,email,phone,role,status']);

        if (! empty($filters['search'])) {
            $term = '%' . $filters['search'] . '%';
            $query->where(function ($q) use ($term) {
                $q->where('store_name', 'like', $term)
                  ->orWhere('description', 'like', $term);
            });
        }

        if (! empty($filters['status']) && in_array($filters['status'], self::STATUSES, true)) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return $query->withCount(['products', 'orders'])
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findById(int $id): ?Store
    {
        return Store::with([
            'owner:id,name,email,phone,role,status',
            'products' => fn ($q) => $q->with(['images'])->limit(10),
        ])
        ->withCount(['products', 'orders'])
        ->find($id);
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    /**
     * Update a store's status.
     *
     * SECURITY: `status` is excluded from Store::$fillable to prevent merchant
     * self-activation. Use direct attribute assignment + save() here since this
     * is admin-only trusted service code.
     */
    public function updateStatus(Store $store, string $status): Store
    {
        $store->status = $status;
        $store->save();

        return $store->fresh(['owner']);
    }
}
