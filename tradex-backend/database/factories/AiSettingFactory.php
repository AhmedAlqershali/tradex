<?php

namespace Database\Factories;

use App\Models\AiSetting;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AiSetting>
 */
class AiSettingFactory extends Factory
{
    protected $model = AiSetting::class;

    public function definition(): array
    {
        return [
            'user_id'       => User::factory(),
            'daily_limit'   => null,
            'monthly_limit' => null,
            'is_active'     => true,
        ];
    }

    /** Disable AI generation for this user. */
    public function disabled(): static
    {
        return $this->state(['is_active' => false]);
    }
}
