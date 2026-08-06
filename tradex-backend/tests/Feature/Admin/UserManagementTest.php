<?php

namespace Tests\Feature\Admin;

use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function actingAsAdmin(): array
    {
        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        return compact('admin', 'token');
    }

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    // =========================================================================
    // Auth / Role Guard
    // =========================================================================

    public function test_unauthenticated_cannot_list_users(): void
    {
        $this->getJson('/api/v1/admin/users')->assertStatus(401);
    }

    public function test_merchant_cannot_access_user_management(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/users', $this->headers($token))->assertStatus(403);
    }

    public function test_client_cannot_access_user_management(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/users', $this->headers($token))->assertStatus(403);
    }

    // =========================================================================
    // Index — listing
    // =========================================================================

    public function test_admin_can_list_all_users(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->count(3)->create();
        User::factory()->merchant()->count(2)->create();

        $response = $this->getJson('/api/v1/admin/users', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'data',
                    'pagination' => ['total', 'per_page', 'current_page', 'last_page', 'from', 'to'],
                ],
            ]);

        // 1 admin + 3 clients + 2 merchants = 6 total
        $this->assertGreaterThanOrEqual(6, $response->json('data.pagination.total'));
    }

    public function test_index_supports_search_by_name(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->create(['name' => 'Khaled Ahmed']);
        User::factory()->client()->create(['name' => 'Sara Ali']);

        $this->getJson('/api/v1/admin/users?search=Khaled', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.name', 'Khaled Ahmed');
    }

    public function test_index_supports_search_by_email(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->create(['email' => 'unique-user@example.com']);

        $this->getJson('/api/v1/admin/users?search=unique-user', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data');
    }

    public function test_index_supports_role_filter(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->count(3)->create();
        User::factory()->merchant()->count(2)->create();

        $this->getJson('/api/v1/admin/users?role=client', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(3, 'data.data');
    }

    public function test_index_supports_status_filter(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->create(['status' => 'active']);
        User::factory()->client()->create(['status' => 'inactive']);
        User::factory()->client()->create(['status' => 'banned']);

        $this->getJson('/api/v1/admin/users?role=client&status=inactive', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.status', 'inactive');
    }

    public function test_index_returns_pagination_meta(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->count(10)->create();

        $this->getJson('/api/v1/admin/users?per_page=3', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.pagination.per_page', 3);
    }

    // =========================================================================
    // Show
    // =========================================================================

    public function test_admin_can_view_a_user(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create(['name' => 'Test Client']);

        $this->getJson("/api/v1/admin/users/{$client->id}", $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $client->id)
            ->assertJsonPath('data.name', 'Test Client');
    }

    public function test_show_returns_404_for_missing_user(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/users/99999', $this->headers($token))
            ->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Update Status
    // =========================================================================

    public function test_admin_can_deactivate_a_client(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create(['status' => 'active']);

        $this->putJson("/api/v1/admin/users/{$client->id}/status", ['status' => 'inactive'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'inactive');

        $this->assertDatabaseHas('users', ['id' => $client->id, 'status' => 'inactive']);
    }

    public function test_admin_can_ban_a_user(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create(['status' => 'active']);

        $this->putJson("/api/v1/admin/users/{$client->id}/status", ['status' => 'banned'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.status', 'banned');
    }

    public function test_admin_can_reactivate_a_user(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create(['status' => 'inactive']);

        $this->putJson("/api/v1/admin/users/{$client->id}/status", ['status' => 'active'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.status', 'active');
    }

    public function test_update_status_rejects_invalid_status(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create();

        $this->putJson("/api/v1/admin/users/{$client->id}/status", ['status' => 'deleted'], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_admin_cannot_change_own_status(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();

        $this->putJson("/api/v1/admin/users/{$admin->id}/status", ['status' => 'inactive'], $this->headers($token))
            ->assertStatus(403);
    }

    public function test_admin_cannot_change_another_admins_status(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $otherAdmin = User::factory()->admin()->create(['email' => 'admin2@tradx.app']);

        $this->putJson("/api/v1/admin/users/{$otherAdmin->id}/status", ['status' => 'inactive'], $this->headers($token))
            ->assertStatus(403);
    }

    // =========================================================================
    // Update Role
    // =========================================================================

    public function test_admin_can_change_user_role(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create();

        $this->putJson("/api/v1/admin/users/{$client->id}/role", ['role' => 'merchant'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.role', 'merchant');

        $this->assertDatabaseHas('users', ['id' => $client->id, 'role' => 'merchant']);
    }

    public function test_update_role_rejects_invalid_role(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create();

        $this->putJson("/api/v1/admin/users/{$client->id}/role", ['role' => 'superuser'], $this->headers($token))
            ->assertStatus(422);
    }

    public function test_admin_cannot_change_own_role(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();

        $this->putJson("/api/v1/admin/users/{$admin->id}/role", ['role' => 'client'], $this->headers($token))
            ->assertStatus(403);
    }

    public function test_update_status_returns_404_for_missing_user(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->putJson('/api/v1/admin/users/99999/status', ['status' => 'inactive'], $this->headers($token))
            ->assertStatus(404);
    }
}
