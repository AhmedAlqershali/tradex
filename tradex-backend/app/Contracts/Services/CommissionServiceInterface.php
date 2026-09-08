<?php

namespace App\Contracts\Services;

use App\Models\Commission;
use App\Models\Order;

interface CommissionServiceInterface
{
    public function accrueForCompletedOrder(Order $order): ?Commission;
}
