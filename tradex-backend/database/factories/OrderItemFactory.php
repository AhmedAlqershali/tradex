<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<OrderItem>
 */
class OrderItemFactory extends Factory
{
    protected $model = OrderItem::class;

    public function definition(): array
    {
        $price    = fake()->randomFloat(2, 5, 500);
        $quantity = fake()->numberBetween(1, 5);

        return [
            'order_id'     => Order::factory(),
            'product_id'   => Product::factory()->active(),
            'product_name' => fake()->words(3, true),
            'unit_price'   => $price,
            'quantity'     => $quantity,
            'subtotal'     => round($price * $quantity, 2),
        ];
    }

    public function forOrder(Order $order): static
    {
        return $this->state(fn () => ['order_id' => $order->id]);
    }
}
