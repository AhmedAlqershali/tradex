<?php

namespace Database\Factories;

use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Store>
 */
class StoreFactory extends Factory
{
    protected $model = Store::class;

    public function definition(): array
    {
        $adjectives = ['Fresh', 'Golden', 'Royal', 'Elite', 'Prime', 'Top', 'Best', 'Grand', 'Pure', 'Star'];
        $nouns      = ['Market', 'Store', 'Shop', 'Bazaar', 'Hub', 'Outlet', 'Corner', 'Place', 'Zone'];

        return [
            'user_id'     => User::factory()->merchant(),
            'store_name'  => fake()->randomElement($adjectives).' '.fake()->randomElement($nouns),
            'description' => fake()->sentences(2, true),
            'logo'        => null,
            'status'      => fake()->randomElement(['active', 'active', 'active', 'inactive']), // weighted active
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

    public function suspended(): static
    {
        return $this->state(fn () => ['status' => 'suspended']);
    }

    public function forUser(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->id]);
    }
}
