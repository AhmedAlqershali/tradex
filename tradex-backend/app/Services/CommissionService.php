<?php

namespace App\Services;

use App\Contracts\Services\CommissionServiceInterface;
use App\Models\Commission;
use App\Models\Order;
use Illuminate\Support\Facades\DB;

class CommissionService implements CommissionServiceInterface
{
    public function accrueForCompletedOrder(Order $order): ?Commission
    {
        $order = $order->fresh(['store', 'store.owner']);

        if ($order->status !== Order::STATUS_COMPLETED) {
            return null;
        }

        $existing = Commission::query()->where('order_id', $order->id)->first();
        if ($existing) {
            return $existing;
        }

        $ratePercentage = (float) config('commission.rate_percentage', 5.00);
        $rateDecimal = $ratePercentage / 100;
        $orderAmount = (float) ($order->total_amount ?? 0);
        $commissionAmount = round($orderAmount * $rateDecimal, 2);
        $merchantNetAmount = round($orderAmount - $commissionAmount, 2);

        return DB::transaction(function () use ($order, $orderAmount, $ratePercentage, $commissionAmount, $merchantNetAmount) {
            $existingAgain = Commission::query()->where('order_id', $order->id)->first();
            if ($existingAgain) {
                return $existingAgain;
            }

            $merchantId = $order->store?->user_id ?? $order->store?->owner?->id;

            return Commission::query()->create([
                'order_id' => $order->id,
                'merchant_id' => $merchantId,
                'store_id' => $order->store_id,
                'order_amount' => $orderAmount,
                'commission_rate' => $ratePercentage,
                'commission_amount' => $commissionAmount,
                'merchant_net_amount' => $merchantNetAmount,
                'status' => 'accrued',
                'payment_status' => 'unpaid',
            ]);
        });
    }
}
