<?php

namespace Tests\Feature\Merchant;

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

    private function actingAsMerchant(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        return compact('merchant', 'store', 'token');
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

    public function test_unauthenticated_cannot_access_merchant_dashboard(): void
    {
        $this->getJson('/api/v1/merchant/dashboard')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_client_cannot_access_merchant_dashboard(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/dashboard', $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_admin_cannot_access_merchant_dashboard(): void
    {
        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/dashboard', $this->headers($token))
            ->assertStatus(403);
    }

    // =========================================================================
    // Dashboard — structure
    // =========================================================================

    public function test_merchant_dashboard_returns_correct_structure(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $response = $this->getJson('/api/v1/merchant/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'products' => ['total', 'active', 'out_of_stock', 'low_stock'],
                    'orders'   => ['total', 'pending', 'confirmed', 'processing', 'completed', 'cancelled'],
                    'total_sales',
                    'recent_orders',
                    'top_products',
                    'low_inventory',
                ],
            ]);
    }

    // =========================================================================
    // Dashboard — product counts
    // =========================================================================

    public function test_dashboard_counts_products_correctly(): void
    {
        ['merchant' => $merchant, 'store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Product::factory()->forStore($store)->create(['status' => 'active',       'quantity' => 100]);
        Product::factory()->forStore($store)->create(['status' => 'active',       'quantity' => 5]);   // low stock
        Product::factory()->forStore($store)->create(['status' => 'out_of_stock', 'quantity' => 0]);
        Product::factory()->forStore($store)->create(['status' => 'inactive',     'quantity' => 10]);

        // Another merchant's product — must NOT be counted
        Product::factory()->create(['status' => 'active']);

        $response = $this->getJson('/api/v1/merchant/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('data.products.total',        4)
            ->assertJsonPath('data.products.active',       2)
            ->assertJsonPath('data.products.out_of_stock', 1)
            ->assertJsonPath('data.products.low_stock',    1);
    }

    // =========================================================================
    // Dashboard — order counts
    // =========================================================================

    public function test_dashboard_counts_orders_correctly(): void
    {
        ['merchant' => $merchant, 'store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $client = User::factory()->client()->create();

        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'pending',   'total_amount' => 100]);
        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'completed', 'total_amount' => 200]);
        Order::factory()->create(['store_id' => $store->id, 'client_id' => $client->id, 'status' => 'cancelled', 'total_amount' => 50]);

        // Another store's order — must NOT be counted
        Order::factory()->create(['status' => 'completed', 'total_amount' => 999]);

        $response = $this->getJson('/api/v1/merchant/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('data.orders.total',     3)
            ->assertJsonPath('data.orders.pending',   1)
            ->assertJsonPath('data.orders.completed', 1)
            ->assertJsonPath('data.orders.cancelled', 1)
            ->assertJsonPath('data.total_sales',      200);  // only completed orders; 200.00 encodes as integer 200
    }

    // =========================================================================
    // Ownership protection
    // =========================================================================

    public function test_merchant_only_sees_own_store_data(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $client = User::factory()->client()->create();

        // Own orders
        Order::factory()->count(2)->create([
            'store_id'  => $store->id,
            'client_id' => $client->id,
            'status'    => 'pending',
        ]);

        // Another merchant's order
        Order::factory()->create(['status' => 'completed', 'total_amount' => 9999]);

        $response = $this->getJson('/api/v1/merchant/dashboard', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('data.orders.total', 2);
    }

    // =========================================================================
    // Analytics
    // =========================================================================

    public function test_merchant_can_access_analytics(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $response = $this->getJson('/api/v1/merchant/analytics', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'sales_overview' => [
                        'total_revenue',
                        'this_month_revenue',
                        'last_month_revenue',
                        'growth_percent',
                    ],
                    'order_statistics' => ['by_status'],
                    'monthly_sales',
                    'best_products',
                    'store_performance',
                ],
            ]);
    }

    public function test_client_cannot_access_merchant_analytics(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/analytics', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_analytics_scoped_to_merchant_stores(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $client = User::factory()->client()->create();

        // Own completed orders
        Order::factory()->count(2)->create([
            'store_id'     => $store->id,
            'client_id'    => $client->id,
            'status'       => 'completed',
            'total_amount' => 100,
        ]);

        // Another store completed order — must not be included in revenue
        Order::factory()->create(['status' => 'completed', 'total_amount' => 5000]);

        $response = $this->getJson('/api/v1/merchant/analytics', $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('data.sales_overview.total_revenue', 200); // 200.00 encodes as integer in JSON
    }
}
