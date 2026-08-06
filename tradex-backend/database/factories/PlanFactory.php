<?php

namespace Database\Factories;

use App\Models\Plan;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Plan>
 */
class PlanFactory extends Factory
{
    protected $model = Plan::class;

    public function definition(): array
    {
        return [
            'name'           => fake()->unique()->slug(1),
            'display_name'   => fake()->words(2, true),
            'monthly_price'  => fake()->randomFloat(2, 9, 99),
            'yearly_price'   => fake()->randomFloat(2, 90, 990),
            'ai_usage_limit' => fake()->numberBetween(100, 1000),
            'product_limit'  => fake()->numberBetween(10, 500),
            'store_limit'    => fake()->numberBetween(1, 5),
            'features'       => ['priority_support' => fake()->boolean()],
            'status'         => 'active',
        ];
    }

    public function active(): static
    {
        return $this->state(fn () => ['status' => 'active']);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['status' => 'inactive']);
    }
}
