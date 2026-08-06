<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\AdminDashboardServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use Illuminate\Http\JsonResponse;

/**
 * Admin Dashboard & Analytics
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 *
 * GET /api/v1/admin/dashboard  — system-wide overview + marketplace activity
 * GET /api/v1/admin/analytics  — sales trends, user/merchant growth, product stats
 */
class DashboardController extends BaseApiController
{
    public function __construct(
        private readonly AdminDashboardServiceInterface $dashboardService,
    ) {}

    // ── GET /api/v1/admin/dashboard ─────────────────────────────────────────

    public function dashboard(): JsonResponse
    {
        $data = $this->dashboardService->getDashboard();

        return $this->success($data, 'Admin dashboard retrieved successfully.');
    }

    // ── GET /api/v1/admin/analytics ─────────────────────────────────────────

    public function analytics(): JsonResponse
    {
        $data = $this->dashboardService->getAnalytics();

        return $this->success($data, 'Admin analytics retrieved successfully.');
    }
}
