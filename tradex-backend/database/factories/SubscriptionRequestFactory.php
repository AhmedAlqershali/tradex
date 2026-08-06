<?php

namespace Database\Factories;

use App\Models\Plan;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SubscriptionRequest>
 */
class SubscriptionRequestFactory extends Factory
{
    protected $model = SubscriptionRequest::class;

    public function definition(): array
    {
        return [
            'user_id'             => User::factory()->merchant(),
            'plan_id'             => Plan::factory(),
            'billing_cycle'       => fake()->randomElement(['monthly', 'yearly']),
            'full_name'           => fake()->name(),
            'phone'               => fake()->numerify('05########'),
            'payment_method'      => 'bank_transfer',
            'payment_proof_image' => 'subscriptions/proofs/test.jpg',
            'notes'               => fake()->optional()->sentence(),
            'status'              => 'pending',
            'rejection_reason'    => null,
            'reviewed_by'         => null,
            'reviewed_at'         => null,
        ];
    }

    public function pending(): static
    {
        return $this->state(fn () => ['status' => 'pending', 'reviewed_by' => null, 'reviewed_at' => null]);
    }

    public function approved(User $reviewer = null): static
    {
        return $this->state(fn () => [
            'status'      => 'approved',
            'reviewed_by' => $reviewer?->id ?? User::factory()->admin(),
            'reviewed_at' => now(),
        ]);
    }

    public function rejected(User $reviewer = null, string $reason = 'Payment proof unclear.'): static
    {
        return $this->state(fn () => [
            'status'           => 'rejected',
            'reviewed_by'      => $reviewer?->id ?? User::factory()->admin(),
            'reviewed_at'      => now(),
            'rejection_reason' => $reason,
        ]);
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
