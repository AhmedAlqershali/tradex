<?php

namespace Database\Factories;

use App\Models\AiUsage;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AiUsage>
 */
class AiUsageFactory extends Factory
{
    protected $model = AiUsage::class;

    public function definition(): array
    {
        return [
            'user_id'       => User::factory(),
            'service_type'  => $this->faker->randomElement(AiUsage::validTypes()),
            'request_count' => 1,
            'credits_used'  => 1,
            'tokens_used'   => $this->faker->numberBetween(50, 600),
        ];
    }
}
