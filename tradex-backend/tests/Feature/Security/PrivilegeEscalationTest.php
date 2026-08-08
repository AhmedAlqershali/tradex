<?php

namespace Tests\Feature\Security;

use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Privilege escalation and broken access control tests.
 *
 * Verifies that users cannot access resources belonging to other users,
 * cannot impersonate other roles, and cannot bypass ownership checks.
 */
class PrivilegeEscalationTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── Cross-role isolation ──────────────────────────────────────────────────

    public function test_client_cannot_access_admin_endpoints(): void
    {
        $token = User::factory()->create(['role' => 'client', 'status' => 'active'])
            ->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/dashboard', $this->headers($token))->assertStatus(403);
        $this->getJson('/api/v1/admin/users', $this->headers($token))->assertStatus(403);
        $this->getJson('/api/v1/admin/stores', $this->headers($token))->assertStatus(403);
    }

    public function test_merchant_cannot_access_admin_endpoints(): void
    {
        $token = User::factory()->create(['role' => 'merchant', 'status' => 'active'])
            ->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/dashboard', $this->headers($token))->assertStatus(403);
        $this->getJson('/api/v1/admin/users', $this->headers($token))->assertStatus(403);
    }

    public function test_client_cannot_access_merchant_endpoints(): void
    {
        $token = User::factory()->create(['role' => 'client', 'status' => 'active'])
            ->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/products', $this->headers($token))->assertStatus(403);
        $this->getJson('/api/v1/merchant/orders', $this->headers($token))->assertStatus(403);
        $this->getJson('/api/v1/merchant/dashboard', $this->headers($token))->assertStatus(403);
    }

    public function test_admin_cannot_access_merchant_endpoints(): void
    {
        $token = User::factory()->create(['role' => 'admin', 'status' => 'active'])
            ->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/products', $this->headers($token))->assertStatus(403);
    }

    public function test_merchant_cannot_access_client_cart(): void
    {
        $token = User::factory()->create(['role' => 'merchant', 'status' => 'active'])
            ->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/cart', $this->headers($token))->assertStatus(403);
    }

    // ── Merchant resource ownership (IDOR) ───────────────────────────────────

    public function test_merchant_cannot_update_another_merchants_store(): void
    {
        $owner = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store = Store::factory()->create(['user_id' => $owner->id, 'status' => 'active']);

        $attacker = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $this->entitleMerchant($attacker);
        $token    = $attacker->createToken('test')->plainTextToken;

        $this->putJson("/api/v1/merchant/stores/{$store->id}", [
            'store_name' => 'Hijacked Store Name',
        ], $this->headers($token))->assertStatus(404); // returns 404 (not 403) to avoid confirming ID existence
    }

    public function test_merchant_cannot_delete_another_merchants_product(): void
    {
        $owner   = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store   = Store::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $product = Product::factory()->create(['store_id' => $store->id, 'status' => 'active', 'quantity' => 5]);

        $attacker = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $this->entitleMerchant($attacker);
        $token    = $attacker->createToken('test')->plainTextToken;

        $this->deleteJson("/api/v1/merchant/products/{$product->id}", [], $this->headers($token))
            ->assertStatus(404);
    }

    public function test_merchant_cannot_view_another_merchants_orders(): void
    {
        $owner   = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store   = Store::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $client  = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $order   = Order::factory()->create([
            'store_id'  => $store->id,
            'client_id' => $client->id,
            'status'    => Order::STATUS_PENDING,
        ]);

        $attacker = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $this->entitleMerchant($attacker);
        $token    = $attacker->createToken('test')->plainTextToken;

        $this->getJson("/api/v1/merchant/orders/{$order->id}", $this->headers($token))
            ->assertStatus(404);
    }

    // ── Client resource ownership ─────────────────────────────────────────────

    public function test_client_cannot_view_another_clients_order(): void
    {
        $victim  = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $merchant= User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store   = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $order   = Order::factory()->create([
            'store_id'  => $store->id,
            'client_id' => $victim->id,
            'status'    => Order::STATUS_PENDING,
        ]);

        $attacker = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $token    = $attacker->createToken('test')->plainTextToken;

        $this->getJson("/api/v1/orders/{$order->id}", $this->headers($token))
            ->assertStatus(404);
    }

    // ── Unauthenticated access ────────────────────────────────────────────────

    public function test_unauthenticated_cannot_access_protected_routes(): void
    {
        $this->getJson('/api/v1/auth/me')->assertStatus(401);
        $this->getJson('/api/v1/cart')->assertStatus(401);
        $this->getJson('/api/v1/merchant/products')->assertStatus(401);
        $this->getJson('/api/v1/admin/dashboard')->assertStatus(401);
    }

    // ── Order status escalation ───────────────────────────────────────────────

    public function test_client_cannot_change_order_status(): void
    {
        $client  = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $merchant= User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store   = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $order   = Order::factory()->create([
            'store_id'  => $store->id,
            'client_id' => $client->id,
            'status'    => Order::STATUS_PENDING,
        ]);
        $token = $client->createToken('test')->plainTextToken;

        // The merchant order-status endpoint should not be accessible to clients
        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", [
            'status' => Order::STATUS_COMPLETED,
        ], $this->headers($token))->assertStatus(403);
    }
}
