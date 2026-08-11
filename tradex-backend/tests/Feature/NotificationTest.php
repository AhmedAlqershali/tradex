<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    public function test_authenticated_user_can_list_own_notifications(): void
    {
        $client = User::factory()->client()->create();
        $other = User::factory()->client()->create();
        $token = $client->createToken('test')->plainTextToken;

        UserNotification::create([
            'user_id' => $client->id,
            'type' => 'order_status_updated',
            'title' => 'Order update',
            'message' => 'Your order changed.',
            'data' => ['order_id' => 12],
        ]);
        UserNotification::create([
            'user_id' => $other->id,
            'type' => 'general',
            'title' => 'Private',
            'message' => 'Not yours.',
        ]);

        $this->getJson('/api/v1/notifications', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.data.0.type', 'order_status_updated')
            ->assertJsonPath('data.data.0.is_read', false)
            ->assertJsonPath('data.pagination.total', 1);
    }

    public function test_user_can_mark_one_notification_read_but_not_another_users(): void
    {
        $client = User::factory()->client()->create();
        $other = User::factory()->client()->create();
        $token = $client->createToken('test')->plainTextToken;
        $mine = UserNotification::create([
            'user_id' => $client->id,
            'type' => 'general',
            'title' => 'Mine',
            'message' => 'Read me.',
        ]);
        $theirs = UserNotification::create([
            'user_id' => $other->id,
            'type' => 'general',
            'title' => 'Theirs',
            'message' => 'Do not read me.',
        ]);

        $this->patchJson(
            "/api/v1/notifications/{$mine->id}/read",
            [],
            $this->headers($token),
        )
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        $this->patchJson(
            "/api/v1/notifications/{$theirs->id}/read",
            [],
            $this->headers($token),
        )
            ->assertNotFound()
            ->assertJson(['success' => false, 'data' => null]);

        $this->assertDatabaseHas('user_notifications', [
            'id' => $mine->id,
        ]);
        $this->assertNotNull($mine->fresh()->read_at);
        $this->assertNull($theirs->fresh()->read_at);

        // The read state remains authoritative after a fresh API read.
        $this->getJson('/api/v1/notifications', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.data.0.is_read', true);
    }

    public function test_user_can_mark_all_own_notifications_read(): void
    {
        $client = User::factory()->client()->create();
        $other = User::factory()->client()->create();
        $token = $client->createToken('test')->plainTextToken;

        UserNotification::insert([
            [
                'user_id' => $client->id,
                'type' => 'general',
                'title' => 'One',
                'message' => 'One.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $client->id,
                'type' => 'general',
                'title' => 'Two',
                'message' => 'Two.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $other->id,
                'type' => 'general',
                'title' => 'Other',
                'message' => 'Other.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->postJson(
            '/api/v1/notifications/read-all',
            [],
            $this->headers($token),
        )
            ->assertOk()
            ->assertJsonPath('data.updated_count', 2);

        $this->assertSame(
            0,
            UserNotification::where('user_id', $client->id)
                ->whereNull('read_at')
                ->count(),
        );
        $this->assertSame(
            1,
            UserNotification::where('user_id', $other->id)
                ->whereNull('read_at')
                ->count(),
        );
    }

    public function test_notifications_require_authentication(): void
    {
        $this->getJson('/api/v1/notifications')
            ->assertUnauthorized()
            ->assertJson(['success' => false, 'data' => null]);
    }
}