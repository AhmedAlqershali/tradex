<?php

namespace Database\Factories;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Subscription>
 */
class SubscriptionFactory extends Factory
{
    protected $model = Subscription::class;

    public function definition(): array
    {
        $startsAt = now();

        return [
            'user_id'       => User::factory()->merchant(),
            'plan_id'       => Plan::factory(),
            'billing_cycle' => fake()->randomElement(['monthly', 'yearly']),
            'status'        => 'active',
            'starts_at'     => $startsAt,
            'ends_at'       => $startsAt->copy()->addMonth(),
        ];
    }

    public function active(): static
    {
        return $this->state(fn () => ['status' => 'active', 'ends_at' => now()->addMonth()]);
    }

    public function expired(): static
    {
        return $this->state(fn () => ['status' => 'expired', 'ends_at' => now()->subDay()]);
    }

    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->id]);
    }

    public function forPlan(Plan $plan): static
    {
        return $this->state(fn () => ['plan_id' => $plan->id]);
    }
}
