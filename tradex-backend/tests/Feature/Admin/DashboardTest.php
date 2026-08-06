<?php

namespace Tests\Feature\Admin;

use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
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

    public function test_unauthenticated_cannot_access_admin_dashboard(): void
    {
        $this->getJson('/api/v1/admin/dashboard')
            ->assertStatus(401);
    }

    public function test_merchant_cannot_access_admin_dashboard(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/dashboard', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_client_cannot_access_admin_dashboard(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/dashboard', $this->headers($token))
            ->assertStatus(403);
    }

    // =========================================================================
    // Dashboard — structure
    // =========================================================================

    public function test_admin_dashboard_returns_correct_structure(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $response = $this->getJson('/api/v1/admin/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'system_overview' => [
                        'users'       => ['total', 'clients', 'merchants', 'admins'],
                        'stores'      => ['total', 'active', 'inactive', 'suspended'],
                        'products'    => ['total', 'active', 'inactive', 'out_of_stock'],
                        'orders'      => ['total', 'pending', 'confirmed', 'processing', 'completed', 'cancelled'],
                        'total_sales',
                    ],
                    'marketplace' => [
                        'newest_users',
                        'newest_stores',
                        'newest_products',
                        'recent_orders',
                    ],
                ],
            ]);
    }

    // =========================================================================
    // Dashboard — system counts
    // =========================================================================

    public function test_dashboard_counts_users_by_role(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        User::factory()->client()->count(3)->create();
        User::factory()->merchant()->count(2)->create();

        $response = $this->getJson('/api/v1/admin/dashboard', $this->headers($token));

        $response->assertOk();

        // 1 admin (created above) + 3 clients + 2 merchants = 6 total
        $data = $response->json('data.system_overview.users');
        $this->assertEquals(3, $data['clients']);
        $this->assertEquals(2, $data['merchants']);
        $this->assertGreaterThanOrEqual(1, $data['admins']);
    }

    public function test_dashboard_counts_stores_by_status(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        Store::factory()->active()->count(2)->create();
        Store::factory()->inactive()->count(1)->create();

        $response = $this->getJson('/api/v1/admin/dashboard', $this->headers($token));

        $response->assertOk();

        $stores = $response->json('data.system_overview.stores');
        $this->assertEquals(2, $stores['active']);
        $this->assertEquals(1, $stores['inactive']);
    }

    public function test_dashboard_calculates_total_sales_from_completed_orders(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $client = User::factory()->client()->create();
        $store  = Store::factory()->create();

        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'completed', 'total_amount' => 300]);
        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'completed', 'total_amount' => 200]);
        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'pending',   'total_amount' => 999]); // should not be counted

        $response = $this->getJson('/api/v1/admin/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('data.system_overview.total_sales', 500); // 500.00 encodes as integer in JSON
    }

    // =========================================================================
    // Analytics
    // =========================================================================

    public function test_admin_analytics_returns_correct_structure(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $response = $this->getJson('/api/v1/admin/analytics', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'sales_statistics'   => ['monthly_sales'],
                    'order_statistics'   => ['by_status'],
                    'user_growth',
                    'merchant_growth',
                    'product_statistics' => ['by_category', 'by_status'],
                ],
            ]);
    }

    public function test_client_cannot_access_admin_analytics(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/analytics', $this->headers($token))
            ->assertStatus(403);
    }
}
