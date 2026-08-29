<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserDeviceToken;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AccountDeletionTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ];
    }

    public function test_authenticated_user_can_delete_their_own_account(): void
    {
        $user = User::factory()->client()->create(['status' => 'active']);
        $other = User::factory()->client()->create(['status' => 'active']);
        $token = $user->createToken('mobile')->plainTextToken;

        UserDeviceToken::create([
            'user_id' => $user->id,
            'token' => 'fcm-token-123',
            'platform' => 'android',
            'last_seen_at' => now(),
        ]);

        UserNotification::create([
            'user_id' => $user->id,
            'type' => 'general',
            'title' => 'Private',
            'message' => 'This should be deleted.',
        ]);

        DB::table('ai_usages')->insert([
            'user_id' => $user->id,
            'service_type' => 'product_description',
            'request_count' => 1,
            'tokens_used' => 42,
            'credits_used' => 1,
            'cost_usd' => 0.01,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('ai_requests')->insert([
            'user_id' => $user->id,
            'service_type' => 'product_description',
            'request_payload' => json_encode(['prompt' => 'private prompt']),
            'response_content' => 'private response',
            'tokens_used' => 42,
            'credits_used' => 1,
            'cost_usd' => 0.01,
            'status' => 'completed',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->deleteJson('/api/v1/profile', [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id' => $user->id]);
        $this->assertDatabaseMissing('user_device_tokens', ['user_id' => $user->id]);
        $this->assertDatabaseMissing('user_notifications', ['user_id' => $user->id]);
        $this->assertDatabaseMissing('ai_usages', ['user_id' => $user->id]);
        $this->assertDatabaseMissing('ai_requests', ['user_id' => $user->id]);
        $this->assertDatabaseHas('users', ['id' => $other->id]);
    }

    public function test_unauthenticated_user_cannot_delete_account(): void
    {
        $this->deleteJson('/api/v1/profile')
            ->assertUnauthorized();
    }

    public function test_delete_account_revokes_current_token_and_blocks_reuse(): void
    {
        $user = User::factory()->client()->create(['status' => 'active']);
        $token = $user->createToken('mobile')->plainTextToken;

        $this->deleteJson('/api/v1/profile', [], $this->headers($token))
            ->assertOk();

        $this->getJson('/api/v1/auth/me', $this->headers($token))
            ->assertUnauthorized();
    }
}
