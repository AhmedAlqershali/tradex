<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    protected $model = Product::class;

    public function definition(): array
    {
        $quantity = fake()->numberBetween(0, 200);

        return [
            'store_id'    => Store::factory(),
            'category_id' => Category::factory(),
            'name'        => fake()->words(fake()->numberBetween(2, 4), true),
            'description' => fake()->sentences(3, true),
            'price'       => fake()->randomFloat(2, 5, 2000),
            'quantity'    => $quantity,
            'image'       => null,
            'status'      => $quantity > 0
                ? fake()->randomElement(['active', 'active', 'active', 'inactive'])
                : 'out_of_stock',
        ];
    }

    // -------------------------------------------------------------------------
    // States
    // -------------------------------------------------------------------------

    public function active(): static
    {
        // Minimum of 10 ensures cart/stock-check tests that update to quantity 5
        // never fail due to an accidentally low stock value.
        return $this->state(fn () => [
            'status'   => 'active',
            'quantity' => fake()->numberBetween(10, 200),
        ]);
    }

    public function outOfStock(): static
    {
        return $this->state(fn () => [
            'status'   => 'out_of_stock',
            'quantity' => 0,
        ]);
    }

    public function cheap(): static
    {
        return $this->state(fn () => [
            'price' => fake()->randomFloat(2, 1, 50),
        ]);
    }

    public function forStore(Store $store): static
    {
        return $this->state(fn () => ['store_id' => $store->id]);
    }

    public function inCategory(Category $category): static
    {
        return $this->state(fn () => ['category_id' => $category->id]);
    }
}
