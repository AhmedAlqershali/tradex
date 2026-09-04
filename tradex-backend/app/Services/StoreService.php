<?php

namespace App\Services;

use App\Contracts\Repositories\StoreRepositoryInterface;
use App\Contracts\Services\StoreServiceInterface;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
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

        $query = Store::active()
            ->with('owner:id,phone')
            ->withCount([
                'products as products_count' => fn ($products) => $products
                    ->where('status', 'active')
                    ->where('quantity', '>', 0),
            ]);

        if (! empty($filters['search'])) {
            $query->where('store_name', 'like', '%' . $filters['search'] . '%');
        }

        if (! empty($filters['region'])) {
            $query->where('region', $filters['region']);
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
            ->with('owner:id,phone')
            ->withCount([
                'products as products_count' => fn ($products) => $products
                    ->where('status', 'active')
                    ->where('quantity', '>', 0),
            ])
            ->find($id);
    }

    public function listActiveProducts(int $storeId, int $perPage = 15): LengthAwarePaginator
    {
        return Product::query()
            ->where('store_id', $storeId)
            ->where('status', 'active')
            ->where('quantity', '>', 0)
            ->with(['store', 'category', 'images'])
            ->latest()
            ->paginate(min($perPage, 100))
            ->withQueryString();
    }

    public function follow(User $client, int $storeId): void
    {
        $store = Store::active()->findOrFail($storeId);
        $client->followedStores()->syncWithoutDetaching([$store->id]);
    }

    public function unfollow(User $client, int $storeId): void
    {
        $client->followedStores()->detach($storeId);
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
     * Create only the first store for a merchant. Locking the owner row makes
     * concurrent completion requests observe the same existing store.
     */
    public function createForMerchant(User $merchant, array $data): Store
    {
        return DB::transaction(function () use ($merchant, $data) {
            $lockedMerchant = User::whereKey($merchant->id)->lockForUpdate()->firstOrFail();

            $store = $lockedMerchant->stores()->orderBy('id')->first();
            if ($store) {
                return $store->fresh(['owner:id,phone']);
            }

            $store = new Store();
            $store->fill([
                'store_name' => $data['store_name'],
                'region'     => $data['region'] ?? null,
            ]);
            $store->user_id = $lockedMerchant->id;
            $store->status = 'active';
            $store->save();

            return $store->fresh(['owner:id,phone']);
        });
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
        $oldPath = $store->logo;
        $path = $file->store('logos', 'public');

        try {
            $updated = $this->storeRepository->updateLogo($store, $path);
        } catch (\Throwable $exception) {
            Storage::disk('public')->delete($path);
            throw $exception;
        }

        if ($oldPath && $oldPath !== $path) {
            Storage::disk('public')->delete($oldPath);
        }

        return $updated;
    }
}
