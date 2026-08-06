<?php

namespace App\Services;

use App\Contracts\Services\ClientDashboardServiceInterface;
use App\Models\User;

class ClientDashboardService implements ClientDashboardServiceInterface
{
    public function getDashboard(User $client): array
    {
        return [
            'orders_count'    => $client->orders()->count(),
            'favorites_count' => $client->favorites()->count(),
        ];
    }
}