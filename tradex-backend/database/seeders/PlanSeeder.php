<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        Plan::updateOrCreate(
            ['name' => Plan::FREE_PLAN_NAME],
            [
                'display_name'   => 'Free',
                'monthly_price'  => Plan::FREE_MONTHLY_PRICE,
                'yearly_price'   => Plan::FREE_YEARLY_PRICE,
                'ai_usage_limit' => 0,
                'product_limit'  => null,
                'store_limit'    => 1,
                'features'       => [],
                'status'         => 'active',
            ],
        );

        // Keep legacy plan rows untouched so historical subscriptions retain
        // their original plan identity.
        Plan::updateOrCreate(
            ['name' => Plan::AI_PLAN_NAME],
            [
                'display_name'   => 'AI',
                'monthly_price'  => Plan::AI_MONTHLY_PRICE,
                'yearly_price'   => Plan::AI_YEARLY_PRICE,
                'ai_usage_limit' => 1000,
                'product_limit'  => 100,
                'store_limit'    => 1,
                'features'       => ['priority_support' => true, 'ai' => true],
                'status'         => 'active',
            ],
        );

        // Keep historical Premium rows, but never expose them as new options.
        Plan::where('name', Plan::PREMIUM_PLAN_NAME)
            ->where('status', 'active')
            ->update(['status' => 'inactive']);
    }
}
