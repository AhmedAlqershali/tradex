<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\StoreServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Store\StoreCollection;
use App\Http\Resources\Store\StoreResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client-facing Stores API.
 *
 * Public — no authentication required.
 * GET /api/v1/stores
 * GET /api/v1/stores/{id}
 */
class StoreController extends BaseApiController
{
    public function __construct(
        private readonly StoreServiceInterface $storeService,
    ) {}

    // -------------------------------------------------------------------------
    // GET /api/v1/stores
    // -------------------------------------------------------------------------

    /**
     * List all active stores with product count.
     *
     * Query parameters:
     *   per_page  int     — 1–100 (default: 15)
     *   search    string  — partial match on store name (optional)
     *   region    string  — exact current/selected region (optional)
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'search'   => ['nullable', 'string', 'max:100'],
            'region'   => ['nullable', 'string', 'max:100'],
        ]);

        $filters    = $request->only(['per_page', 'search', 'region']);
        $paginator  = $this->storeService->listActive($filters);
        $collection = new StoreCollection($paginator);

        return $this->success($collection->toArray($request), 'Stores retrieved successfully.');
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/stores/{id}
    // -------------------------------------------------------------------------

    /**
     * Show a single active store with its product count.
     */
    public function show(int $id): JsonResponse
    {
        $store = $this->storeService->findActive($id);

        if (! $store) {
            return $this->notFound('Store not found.');
        }

        return $this->success(new StoreResource($store), 'Store retrieved successfully.');
    }
}
