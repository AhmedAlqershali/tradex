<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    protected $model = Category::class;

    /**
     * Real-world marketplace categories for the Tradex app.
     */
    private static array $categories = [
        'Electronics',
        'Fashion & Clothing',
        'Home & Kitchen',
        'Food & Groceries',
        'Beauty & Personal Care',
        'Sports & Outdoors',
        'Toys & Games',
        'Books & Stationery',
        'Health & Wellness',
        'Automotive',
        'Jewelry & Accessories',
        'Baby & Kids',
    ];

    public function definition(): array
    {
        return [
            'name'   => fake()->unique()->randomElement(self::$categories),
            'image'  => null,
            'status' => 'active',
        ];
    }

    // -------------------------------------------------------------------------
    // States
    // -------------------------------------------------------------------------

    public function active(): static
    {
        return $this->state(fn () => ['status' => 'active']);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['status' => 'inactive']);
    }
}
