<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        Plan::updateOrCreate(
            ['name' => 'pro'],
            [
                'display_name'   => 'Pro Plan',
                'monthly_price'  => 5.00,
                'yearly_price'   => 60.00,
                'ai_usage_limit' => 1000,
                'product_limit'  => 100,
                'store_limit'    => 1,
                'features'       => ['priority_support' => true],
                'status'         => 'active',
            ],
        );
    }
}
