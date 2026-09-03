<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Contracts\Services\StoreServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Store\UpdateStoreLogoRequest;
use App\Http\Requests\Store\UpdateStoreRequest;
use App\Http\Resources\Store\StoreResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Merchant store management.
 *
 * All routes are behind auth:sanctum + role:merchant middleware.
 * Ownership is enforced by StorePolicy; the service layer never
 * returns stores that do not belong to the authenticated merchant.
 *
 * GET  /api/v1/merchant/stores           — list own stores
 * POST /api/v1/merchant/stores           — return or create the first store
 * GET  /api/v1/merchant/stores/{id}      — show a specific store
 * PUT  /api/v1/merchant/stores/{id}      — update name / description
 * POST /api/v1/merchant/stores/{id}/logo — replace logo image
 */
class StoreController extends BaseApiController
{
    public function __construct(
        private readonly StoreServiceInterface $storeService,
    ) {}

    // ── GET /api/v1/merchant/stores ───────────────────────────────────────────

    /**
     * Return the merchant's first store, creating it when a legacy merchant
     * has no store yet. The service operation is idempotent per merchant.
     */
    public function store(Request $request): JsonResponse
    {
        $this->authorize('viewAny', \App\Models\Store::class);

        $data = $request->validate([
            'store_name' => ['required', 'string', 'min:2', 'max:100'],
            'region'     => ['sometimes', 'nullable', 'string', 'max:100'],
        ]);

        $store = $this->storeService->createForMerchant($request->user(), $data);

        return $this->success(new StoreResource($store), 'Store is ready.');
    }

    /**
     * List all stores owned by the authenticated merchant.
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', \App\Models\Store::class);

        $stores = $this->storeService->getForMerchant($request->user());

        return $this->success(
            StoreResource::collection($stores),
            'Stores retrieved successfully.',
        );
    }

    // ── GET /api/v1/merchant/stores/{id} ──────────────────────────────────────

    /**
     * Show a specific store that belongs to the authenticated merchant.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $store = $this->storeService->findForMerchant($id, $request->user());

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        $this->authorize('view', $store);

        return $this->success(new StoreResource($store), 'Store retrieved successfully.');
    }

    // ── PUT /api/v1/merchant/stores/{id} ──────────────────────────────────────

    /**
     * Update the store's name and/or description.
     *
     * Body (all fields optional):
     *   store_name   string  max:100
     *   description  string  max:1000  (nullable)
     */
    public function update(UpdateStoreRequest $request, int $id): JsonResponse
    {
        $store = $this->storeService->findForMerchant($id, $request->user());

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        $this->authorize('update', $store);

        $updated = $this->storeService->updateStore($store, $request->validated());

        return $this->success(new StoreResource($updated), 'Store updated successfully.');
    }

    // ── POST /api/v1/merchant/stores/{id}/logo ────────────────────────────────

    /**
     * Replace the store's logo with a new image upload.
     *
     * Body (multipart/form-data):
     *   logo  file  required  image/jpeg,png,webp  max:2MB
     */
    public function updateLogo(UpdateStoreLogoRequest $request, int $id): JsonResponse
    {
        $store = $this->storeService->findForMerchant($id, $request->user());

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        $this->authorize('update', $store);

        $updated = $this->storeService->updateStoreLogo($store, $request->file('logo'));

        return $this->success(new StoreResource($updated), 'Store logo updated successfully.');
    }
}
