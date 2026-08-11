<?php

namespace App\Services;

use App\Contracts\Repositories\StoreRepositoryInterface;
use App\Contracts\Services\StoreServiceInterface;
use App\Models\Store;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;

class StoreService implements StoreServiceInterface
{
    public function __construct(
        private readonly StoreRepositoryInterface $storeRepository,
    ) {}

    // ── Public / Client-facing ────────────────────────────────────────────────

    /**
     * Return a paginated list of active stores, including product count.
     *
     * @param  array{per_page?: int}  $filters
     */
    public function listActive(array $filters): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        $query = Store::active()->withCount('products');

        if (! empty($filters['search'])) {
            $query->where('store_name', 'like', '%' . $filters['search'] . '%');
        }

        return $query->orderBy('store_name')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Find a single active store with its products count.
     * Returns null if not found or not active.
     */
    public function findActive(int $id): ?Store
    {
        return Store::active()
            ->withCount('products')
            ->find($id);
    }

    // ── Merchant-facing ───────────────────────────────────────────────────────

    /**
     * Return all stores owned by the given merchant, with product count.
     */
    public function getForMerchant(User $merchant): Collection
    {
        return $this->storeRepository->getForMerchant($merchant);
    }

    /**
     * Find a specific store that belongs to the given merchant.
     * Returns null if not found or if the merchant does not own it.
     */
    public function findForMerchant(int $storeId, User $merchant): ?Store
    {
        return $this->storeRepository->findForMerchant($storeId, $merchant);
    }

    /**
     * Update store profile fields (store_name, description).
     */
    public function updateStore(Store $store, array $data): Store
    {
        if (array_key_exists('phone', $data)) {
            $store->owner()->update(['phone' => $data['phone']]);
            unset($data['phone']);
        }

        return $this->storeRepository->update($store, $data);
    }

    /**
     * Upload a new logo image, delete the old one from storage,
     * and persist the new path on the store record.
     *
     * Deletion is best-effort: a missing file on disk is not treated
     * as an error since the record update must still succeed.
     */
    public function updateStoreLogo(Store $store, UploadedFile $file): Store
    {
        if ($store->logo && Storage::disk('public')->exists($store->logo)) {
            Storage::disk('public')->delete($store->logo);
        }

        $path = $file->store('logos', 'public');

        return $this->storeRepository->updateLogo($store, $path);
    }
}
