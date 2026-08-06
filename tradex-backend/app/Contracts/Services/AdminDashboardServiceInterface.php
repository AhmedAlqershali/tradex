<?php

namespace App\Contracts\Services;

interface AdminDashboardServiceInterface
{
    /**
     * Aggregate system-wide dashboard overview for admins.
     */
    public function getDashboard(): array;

    /**
     * Aggregate system-wide analytics (sales, growth, trends) for admins.
     */
    public function getAnalytics(): array;
}
