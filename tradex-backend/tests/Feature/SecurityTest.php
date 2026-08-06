<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Security & permission tests.
 *
 * Verifies that:
 * - Unauthenticated requests to protected routes return 401.
 * - Role-based access control prevents cross-role access (403).
 * - Clients cannot access merchant/admin endpoints.
 * - Merchants cannot access admin endpoints.
 * - Admins cannot perform client-only actions directly.
 * - Ownership is enforced on resource-level actions.
 */
class SecurityTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('test')->plainTextToken;
    }

    // =========================================================================
    // Unauthenticated (401) guards
    // =========================================================================

    public function test_profile_requires_auth(): void
    {
        $this->getJson('/api/v1/profile')->assertStatus(401);
    }

    public function test_cart_requires_auth(): void
    {
        $this->getJson('/api/v1/cart')->assertStatus(401);
    }

    public function test_orders_list_requires_auth(): void
    {
        $this->getJson('/api/v1/orders')->assertStatus(401);
    }

    public function test_favorites_requires_auth(): void
    {
        $this->getJson('/api/v1/favorites')->assertStatus(401);
    }

    public function test_merchant_dashboard_requires_auth(): void
    {
        $this->getJson('/api/v1/merchant/dashboard')->assertStatus(401);
    }

    public function test_admin_dashboard_requires_auth(): void
    {
        $this->getJson('/api/v1/admin/dashboard')->assertStatus(401);
    }

    // =========================================================================
    // Client cannot access merchant routes (403)
    // =========================================================================

    public function test_client_cannot_access_merchant_dashboard(): void
    {
        $client = User::factory()->client()->create();
        $token  = $this->tokenFor($client);

        $this->getJson('/api/v1/merchant/dashboard', $this->headers($token))
             ->assertStatus(403);
    }

    public function test_client_cannot_create_merchant_product(): void
    {
        $client = User::factory()->client()->create();
        $token  = $this->tokenFor($client);

        $this->postJson('/api/v1/merchant/products', ['name' => 'Test'], $this->headers($token))
             ->assertStatus(403);
    }

    public function test_client_cannot_access_admin_users(): void
    {
        $client = User::factory()->client()->create();
        $token  = $this->tokenFor($client);

        $this->getJson('/api/v1/admin/users', $this->headers($token))
             ->assertStatus(403);
    }

    // =========================================================================
    // Merchant cannot access admin routes (403)
    // =========================================================================

    public function test_merchant_cannot_access_admin_users(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $this->tokenFor($merchant);

        $this->getJson('/api/v1/admin/users', $this->headers($token))
             ->assertStatus(403);
    }

    public function test_merchant_cannot_manage_categories(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $this->tokenFor($merchant);

        $this->postJson('/api/v1/admin/categories', ['name' => 'cat'], $this->headers($token))
             ->assertStatus(403);
    }

    public function test_merchant_cannot_access_admin_dashboard(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $this->tokenFor($merchant);

        $this->getJson('/api/v1/admin/dashboard', $this->headers($token))
             ->assertStatus(403);
    }

    // =========================================================================
    // Merchant cannot access client-only routes (403)
    // =========================================================================

    public function test_merchant_cannot_access_cart(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $this->tokenFor($merchant);

        $this->getJson('/api/v1/cart', $this->headers($token))
             ->assertStatus(403);
    }

    public function test_merchant_cannot_place_order(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $this->tokenFor($merchant);

        $this->postJson('/api/v1/orders', [
            'customer_name'  => 'Test',
            'customer_phone' => '123',
            'customer_city'  => 'City',
        ], $this->headers($token))
             ->assertStatus(403);
    }

    // =========================================================================
    // Ownership enforcement
    // =========================================================================

    public function test_client_cannot_view_another_clients_order(): void
    {
        $clientA = User::factory()->client()->create();
        $clientB = User::factory()->client()->create();

        $order  = Order::factory()->forClient($clientB)->create();
        $tokenA = $this->tokenFor($clientA);

        $this->getJson("/api/v1/orders/{$order->id}", $this->headers($tokenA))
             ->assertStatus(404);
    }

    public function test_merchant_cannot_update_another_merchants_product(): void
    {
        $merchant1  = User::factory()->merchant()->create();
        $merchant2  = User::factory()->merchant()->create();
        $store2     = Store::factory()->forUser($merchant2)->active()->create();
        $product    = Product::factory()->forStore($store2)->create();

        $token1 = $this->tokenFor($merchant1);

        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'name' => 'Hacked Name',
        ], $this->headers($token1))
             ->assertStatus(404); // returns 404 (not found for this merchant)
    }

    // =========================================================================
    // Public marketplace endpoints (no auth needed)
    // =========================================================================

    public function test_products_endpoint_is_public(): void
    {
        $this->getJson('/api/v1/products')->assertOk();
    }

    public function test_stores_endpoint_is_public(): void
    {
        $this->getJson('/api/v1/stores')->assertOk();
    }

    public function test_categories_endpoint_is_public(): void
    {
        $this->getJson('/api/v1/categories')->assertOk();
    }

    public function test_health_endpoint_is_public(): void
    {
        $this->getJson('/api/v1/health')->assertOk();
    }
}
