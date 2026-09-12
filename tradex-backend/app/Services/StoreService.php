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
            ->with('owner:id,phone,avatar')
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
            ->with('owner:id,phone,avatar')
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
     * Upload a new logo image to Cloudinary, delete the old local file when
     * applicable, and persist the Cloudinary URL on the store record.
     *
     * Deletion is best-effort: a missing file on disk is not treated as an
     * error since the record update must still succeed.
     */
    public function updateStoreLogo(Store $store, UploadedFile $file): Store
    {
        $oldPath = $store->logo;
        $disk = Storage::disk('cloudinary');
        $storedPath = $disk->putFileAs('logos', $file, $file->hashName());

        if ($storedPath === false) {
            throw new \RuntimeException('Store logo could not be persisted.');
        }

        $url = $disk->url($storedPath);

        if (! is_string($url) || trim($url) === '') {
            throw new \RuntimeException('Store logo URL could not be generated.');
        }

        try {
            $updated = $this->storeRepository->updateLogo($store, $url);
        } catch (\Throwable $exception) {
            $disk->delete($storedPath);
            throw $exception;
        }

        if ($oldPath && $oldPath !== $url) {
            $this->deleteStoredLogo($oldPath);
        }

        return $updated;
    }

    private function deleteStoredLogo(?string $path): void
    {
        if (! is_string($path) || trim($path) === '') {
            return;
        }

        if (preg_match('#^https?://#i', $path) === 1) {
            return;
        }

        $publicPath = preg_replace('#^/?storage/?#i', '', $path);
        $publicPath = preg_replace('#^/+#', '', $publicPath);

        if ($publicPath === '' || $publicPath === 'storage') {
            return;
        }

        if (Storage::disk('public')->exists($publicPath)) {
            Storage::disk('public')->delete($publicPath);
        }
    }
}
