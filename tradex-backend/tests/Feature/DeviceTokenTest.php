<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserDeviceToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceTokenTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_token_is_owned_by_the_latest_authenticated_user(): void
    {
        $first = User::factory()->client()->create();
        $second = User::factory()->client()->create();
        $token = $second->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/device-tokens', ['token' => 'shared-fcm-token'], [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ])->assertOk();

        $this->assertDatabaseHas('user_device_tokens', [
            'user_id' => $second->id,
            'token' => 'shared-fcm-token',
        ]);
        $this->assertDatabaseMissing('user_device_tokens', ['user_id' => $first->id]);
    }
}