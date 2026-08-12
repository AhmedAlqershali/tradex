<?php

namespace App\Http\Controllers\Admin;

use App\Contracts\Services\AdminDashboardServiceInterface;
use Illuminate\View\View;

class DashboardController
{
    public function __construct(
        private readonly AdminDashboardServiceInterface $dashboardService,
    ) {}

    public function index(): View
    {
        $dashboard = $this->dashboardService->getDashboard();

        return view('admin.dashboard.index', [
            'overview' => $dashboard['system_overview'],
            'marketplace' => $dashboard['marketplace'],
        ]);
    }
}