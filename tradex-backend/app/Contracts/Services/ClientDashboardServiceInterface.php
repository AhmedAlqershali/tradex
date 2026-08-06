<?php

namespace App\Contracts\Services;

use App\Models\User;

interface ClientDashboardServiceInterface
{
    /**
     * Return lightweight dashboard counters scoped to the authenticated client.
     *
     * @return array{orders_count: int, favorites_count: int}
     */
    public function getDashboard(User $client): array;
}