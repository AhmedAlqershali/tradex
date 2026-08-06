<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Contracts\Services\MerchantDashboardServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Resources\Order\OrderResource;
use App\Http\Resources\Product\ProductResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Merchant Dashboard & Analytics
 *
 * All routes are behind auth:sanctum + role:merchant middleware.
 * Every query is automatically scoped to the authenticated merchant's stores.
 *
 * GET /api/v1/merchant/dashboard  — summary stats + recent orders + top/low-stock products
 * GET /api/v1/merchant/analytics  — sales trends, monthly breakdown, best products, store perf
 */
class DashboardController extends BaseApiController
{
    public function __construct(
        private readonly MerchantDashboardServiceInterface $dashboardService,
    ) {}

    // ── GET /api/v1/merchant/dashboard ──────────────────────────────────────

    public function dashboard(Request $request): JsonResponse
    {
        $merchant = $request->user();
        $data     = $this->dashboardService->getDashboard($merchant);

        return $this->success([
            'products' => $data['products'],
            'orders'   => $data['orders'],
            'total_sales'   => $data['total_sales'],
            'recent_orders' => OrderResource::collection($data['recent_orders']),
            'top_products'  => ProductResource::collection($data['top_products']),
            'low_inventory' => ProductResource::collection($data['low_inventory']),
        ], 'Merchant dashboard retrieved successfully.');
    }

    // ── GET /api/v1/merchant/analytics ──────────────────────────────────────

    public function analytics(Request $request): JsonResponse
    {
        $merchant = $request->user();
        $data     = $this->dashboardService->getAnalytics($merchant);

        return $this->success($data, 'Merchant analytics retrieved successfully.');
    }
}
