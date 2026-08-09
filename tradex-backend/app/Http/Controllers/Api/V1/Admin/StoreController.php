<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\AdminStoreManagementServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Admin\UpdateStoreStatusRequest;
use App\Http\Resources\Store\AdminStoreCollection;
use App\Http\Resources\Store\AdminStoreResource;
use App\Models\Store;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin Store Management
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 *
 * GET /api/v1/admin/stores              — paginated list with search/filter
 * GET /api/v1/admin/stores/{id}         — view store with owner + products
 * PUT /api/v1/admin/stores/{id}/status  — approve / suspend / deactivate
 */
class StoreController extends BaseApiController
{
    public function __construct(
        private readonly AdminStoreManagementServiceInterface $storeService,
    ) {}

    // ── GET /api/v1/admin/stores ────────────────────────────────────────────

    /**
     * Paginated list of all stores.
     *
     * Query parameters:
     *   search    string  — partial match on store name / description
     *   status    string  — active | inactive | suspended
     *   per_page  int     — 1–100 (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Store::class);

        $paginator = $this->storeService->listStores(
            $request->only(['search', 'status', 'per_page']),
        );

        return $this->success(
            (new AdminStoreCollection($paginator))->toArray($request),
            'Stores retrieved successfully.',
        );
    }

    // ── GET /api/v1/admin/stores/{id} ───────────────────────────────────────

    public function show(int $id): JsonResponse
    {
        $store = $this->storeService->findById($id);

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        $this->authorize('view', $store);

        return $this->success(
            new AdminStoreResource($store),
            'Store retrieved successfully.',
        );
    }

    // ── PUT /api/v1/admin/stores/{id}/status ────────────────────────────────

    public function updateStatus(UpdateStoreStatusRequest $request, int $id): JsonResponse
    {
        $store = $this->storeService->findById($id);

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        $this->authorize('updateStatus', $store);

        $updated = $this->storeService->updateStatus($store, $request->validated('status'));

        return $this->success(
            new AdminStoreResource($updated),
            'Store status updated successfully.',
        );
    }
}
