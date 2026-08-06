<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\ClientDashboardServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client dashboard counters.
 *
 * GET /api/v1/client/dashboard
 */
class DashboardController extends BaseApiController
{
    public function __construct(
        private readonly ClientDashboardServiceInterface $dashboardService,
    ) {}

    public function dashboard(Request $request): JsonResponse
    {
        return $this->success(
            $this->dashboardService->getDashboard($request->user()),
            'Client dashboard retrieved successfully.',
        );
    }
}