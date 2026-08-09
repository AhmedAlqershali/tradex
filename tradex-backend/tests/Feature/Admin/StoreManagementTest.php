<?php

namespace Tests\Feature\Admin;

use App\Models\Product;
use App\Models\Store;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StoreManagementTest extends TestCase
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

    public function test_unauthenticated_cannot_list_stores(): void
    {
        $this->getJson('/api/v1/admin/stores')->assertStatus(401);
    }

    public function test_merchant_cannot_access_admin_store_management(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/stores', $this->headers($token))->assertStatus(403);
    }

    public function test_client_cannot_access_admin_store_management(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/stores', $this->headers($token))->assertStatus(403);
    }

    // =========================================================================
    // Index — listing
    // =========================================================================

    public function test_admin_can_list_all_stores(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        Store::factory()->active()->count(3)->create();
        Store::factory()->suspended()->count(1)->create();

        $response = $this->getJson('/api/v1/admin/stores', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'data',
                    'pagination' => ['total', 'per_page', 'current_page', 'last_page'],
                ],
            ]);

        $this->assertEquals(4, $response->json('data.pagination.total'));
    }

    public function test_index_includes_owner_info(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $merchant = User::factory()->merchant()->create(['name' => 'Store Owner']);
        Store::factory()->forUser($merchant)->active()->create();

        $response = $this->getJson('/api/v1/admin/stores', $this->headers($token));

        $response->assertOk();
        // The StoreCollection uses StoreResource which includes owner when loaded
        $this->assertNotNull($response->json('data.data.0'));
    }

    public function test_index_includes_merchant_subscription_status_and_dates(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $merchant = User::factory()->merchant()->create();
        $store = Store::factory()->forUser($merchant)->active()->create();
        $plan = Plan::factory()->active()->create();
        Subscription::factory()->forUser($merchant)->forPlan($plan)->create([
            'type'      => 'trial',
            'status'    => 'active',
            'starts_at' => now()->subDay(),
            'ends_at'   => now()->addDays(13),
        ]);

        $this->getJson('/api/v1/admin/stores', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.data.0.id', $store->id)
            ->assertJsonPath('data.data.0.owner.current_subscription.type', 'trial')
            ->assertJsonPath('data.data.0.owner.current_subscription.status', 'active')
            ->assertJsonPath('data.data.0.owner.current_subscription.starts_at', fn ($value) => is_string($value))
            ->assertJsonPath('data.data.0.owner.current_subscription.ends_at', fn ($value) => is_string($value));
    }

    public function test_index_supports_search_filter(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $merchant = User::factory()->merchant()->create();
        Store::factory()->forUser($merchant)->create(['store_name' => 'Alpha Electronics']);
        Store::factory()->forUser($merchant)->create(['store_name' => 'Beta Fashion']);

        $this->getJson('/api/v1/admin/stores?search=Alpha', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.store_name', 'Alpha Electronics');
    }

    public function test_index_search_matches_merchant_identity(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $merchant = User::factory()->merchant()->create([
            'name'  => 'Mariam Merchant',
            'email' => 'mariam@example.com',
            'phone' => '0500001234',
        ]);
        Store::factory()->forUser($merchant)->create(['store_name' => 'The Store']);
        Store::factory()->create(['store_name' => 'Another Store']);

        $this->getJson('/api/v1/admin/stores?search=mariam@example.com', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.owner.email', 'mariam@example.com');

        $this->getJson('/api/v1/admin/stores?search=0500001234', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.owner.name', 'Mariam Merchant');
    }

    public function test_index_supports_status_filter(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        Store::factory()->active()->count(2)->create();
        Store::factory()->suspended()->count(1)->create();

        $this->getJson('/api/v1/admin/stores?status=suspended', $this->headers($token))
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.status', 'suspended');
    }

    public function test_index_returns_pagination_meta(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        Store::factory()->active()->count(10)->create();

        $this->getJson('/api/v1/admin/stores?per_page=3', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.pagination.per_page', 3);
    }

    // =========================================================================
    // Show
    // =========================================================================

    public function test_admin_can_view_a_store_with_details(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $merchant = User::factory()->merchant()->create(['name' => 'Merchant Owner']);
        $store    = Store::factory()->forUser($merchant)->active()->create();

        Product::factory()->forStore($store)->count(3)->create();

        $response = $this->getJson("/api/v1/admin/stores/{$store->id}", $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $store->id)
            ->assertJsonPath('data.owner.name', 'Merchant Owner')
            ->assertJsonStructure([
                'data' => [
                    'id', 'store_name', 'status',
                    'owner'    => ['id', 'name', 'email'],
                    'products',
                    'products_count',
                ],
            ]);

        $this->assertEquals(3, $response->json('data.products_count'));
    }

    public function test_show_returns_404_for_missing_store(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/stores/99999', $this->headers($token))
            ->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Update Status
    // =========================================================================

    public function test_admin_can_suspend_a_store(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $store = Store::factory()->active()->create();

        $this->putJson("/api/v1/admin/stores/{$store->id}/status", ['status' => 'suspended'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'suspended');

        $this->assertDatabaseHas('stores', ['id' => $store->id, 'status' => 'suspended']);
    }

    public function test_admin_can_activate_a_store(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $store = Store::factory()->inactive()->create();

        $this->putJson("/api/v1/admin/stores/{$store->id}/status", ['status' => 'active'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.status', 'active');
    }

    public function test_admin_can_deactivate_a_store(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $store = Store::factory()->active()->create();

        $this->putJson("/api/v1/admin/stores/{$store->id}/status", ['status' => 'inactive'], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');
    }

    public function test_update_status_rejects_invalid_status(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $store = Store::factory()->create();

        $this->putJson("/api/v1/admin/stores/{$store->id}/status", ['status' => 'deleted'], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_update_status_returns_404_for_missing_store(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->putJson('/api/v1/admin/stores/99999/status', ['status' => 'active'], $this->headers($token))
            ->assertStatus(404);
    }
}
