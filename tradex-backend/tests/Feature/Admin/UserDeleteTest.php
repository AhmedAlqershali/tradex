<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests for DELETE /api/v1/admin/users/{id}
 */
class UserDeleteTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsAdmin(): array
    {
        $admin = User::factory()->admin()->create(['status' => 'active']);
        $token = $admin->createToken('test')->plainTextToken;

        return compact('admin', 'token');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    public function test_unauthenticated_cannot_delete_user(): void
    {
        $user = User::factory()->client()->create();
        $this->deleteJson("/api/v1/admin/users/{$user->id}")->assertUnauthorized();
    }

    public function test_client_cannot_delete_user(): void
    {
        $client = User::factory()->client()->create(['status' => 'active']);
        $token  = $client->createToken('test')->plainTextToken;
        $target = User::factory()->client()->create();

        $this->deleteJson("/api/v1/admin/users/{$target->id}", [], $this->headers($token))
            ->assertForbidden();
    }

    public function test_merchant_cannot_delete_user(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $token    = $merchant->createToken('test')->plainTextToken;
        $target   = User::factory()->client()->create();

        $this->deleteJson("/api/v1/admin/users/{$target->id}", [], $this->headers($token))
            ->assertForbidden();
    }

    public function test_admin_can_delete_client(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $client = User::factory()->client()->create();

        $this->deleteJson("/api/v1/admin/users/{$client->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('users', ['id' => $client->id]);
    }

    public function test_admin_can_delete_merchant(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $merchant = User::factory()->merchant()->create();

        $this->deleteJson("/api/v1/admin/users/{$merchant->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('users', ['id' => $merchant->id]);
    }

    public function test_admin_cannot_delete_own_account(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();

        $this->deleteJson("/api/v1/admin/users/{$admin->id}", [], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_admin_cannot_delete_another_admin(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $otherAdmin = User::factory()->admin()->create();

        $this->deleteJson("/api/v1/admin/users/{$otherAdmin->id}", [], $this->headers($token))
            ->assertForbidden();
    }

    public function test_delete_non_existent_user_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->deleteJson('/api/v1/admin/users/99999', [], $this->headers($token))
            ->assertNotFound();
    }
}
