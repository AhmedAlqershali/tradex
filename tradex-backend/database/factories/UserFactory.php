<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'name'              => fake()->name(),
            'email'             => fake()->unique()->safeEmail(),
            'phone'             => fake()->numerify('+966 5## ### ###'),
            'password'          => Hash::make('password'),
            'role'              => fake()->randomElement(['client', 'merchant']),
            'avatar'            => null,
            'email_verified_at' => now(),
            'remember_token'    => Str::random(10),
        ];
    }

    // -------------------------------------------------------------------------
    // States
    // -------------------------------------------------------------------------

    public function client(): static
    {
        return $this->state(fn () => ['role' => 'client']);
    }

    public function merchant(): static
    {
        return $this->state(fn () => ['role' => 'merchant']);
    }

    public function admin(): static
    {
        return $this->state(fn () => [
            'role' => 'admin',
            'name' => 'Admin',
        ]);
    }

    public function unverified(): static
    {
        return $this->state(fn () => ['email_verified_at' => null]);
    }
}
