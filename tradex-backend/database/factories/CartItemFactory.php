<?php

namespace Database\Factories;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CartItem>
 */
class CartItemFactory extends Factory
{
    protected $model = CartItem::class;

    public function definition(): array
    {
        return [
            'cart_id'    => Cart::factory(),
            'product_id' => Product::factory()->active(),
            'quantity'   => fake()->numberBetween(1, 5),
        ];
    }

    public function forCart(Cart $cart): static
    {
        return $this->state(fn () => ['cart_id' => $cart->id]);
    }

    public function forProduct(Product $product): static
    {
        return $this->state(fn () => ['product_id' => $product->id]);
    }
}
