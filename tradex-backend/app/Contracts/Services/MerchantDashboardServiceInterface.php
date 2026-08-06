<?php

namespace App\Contracts\Services;

use App\Models\User;

interface MerchantDashboardServiceInterface
{
    /**
     * Aggregate dashboard summary stats for a merchant.
     * All data is scoped to the merchant's own stores.
     */
    public function getDashboard(User $merchant): array;

    /**
     * Aggregate analytics data (sales, orders, monthly trends, top products)
     * scoped to the merchant's own stores.
     */
    public function getAnalytics(User $merchant): array;
}
