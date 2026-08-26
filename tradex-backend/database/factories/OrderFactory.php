<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        return [
            'client_id'       => User::factory()->client(),
            'store_id'        => Store::factory(),
            'customer_name'   => fake()->name(),
            'customer_phone'  => fake()->phoneNumber(),
            'customer_city'   => fake()->city(),
            'total_amount'    => fake()->randomFloat(2, 10, 500),
            'status'          => Order::STATUS_PENDING,
            'notes'           => fake()->optional()->sentence(),
        ];
    }

    public function forClient(User $client): static
    {
        return $this->state(fn () => ['client_id' => $client->id]);
    }

    public function forStore(Store $store): static
    {
        return $this->state(fn () => ['store_id' => $store->id]);
    }

    public function pending(): static
    {
        return $this->state(fn () => ['status' => Order::STATUS_PENDING]);
    }

    public function confirmed(): static
    {
        return $this->state(fn () => ['status' => 'confirmed']);
    }

    public function completed(): static
    {
        return $this->state(fn () => ['status' => 'completed']);
    }

    public function cancelled(): static
    {
        return $this->state(fn () => ['status' => 'cancelled']);
    }
}
