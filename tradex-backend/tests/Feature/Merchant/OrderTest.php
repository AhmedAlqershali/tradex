<?php

namespace Tests\Feature\Merchant;

use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderTest extends TestCase
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
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // =========================================================================
    // Auth / Role guard
    // =========================================================================

    public function test_unauthenticated_cannot_access_merchant_orders(): void
    {
        $this->getJson('/api/v1/merchant/orders')->assertStatus(401);
    }

    public function test_unauthenticated_cannot_access_merchant_order_detail(): void
    {
        $this->getJson('/api/v1/merchant/orders/1')->assertStatus(401);
    }

    public function test_client_cannot_access_merchant_orders(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/orders', $this->headers($token))->assertStatus(403);
    }

    // =========================================================================
    // GET /api/v1/merchant/orders
    // =========================================================================

    public function test_merchant_can_list_own_store_orders(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Order::factory()->forStore($store)->count(3)->create();
        Order::factory()->count(2)->create(); // other stores

        $this->getJson('/api/v1/merchant/orders', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.pagination.total', 3);
    }

    public function test_merchant_cannot_see_other_stores_orders(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        Order::factory()->count(5)->create(); // all from other stores

        $this->getJson('/api/v1/merchant/orders', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 0);
    }

    public function test_order_list_includes_pagination(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Order::factory()->forStore($store)->count(7)->create();

        $this->getJson('/api/v1/merchant/orders?per_page=3', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 7)
             ->assertJsonPath('data.pagination.per_page', 3);
    }

    // =========================================================================
    // GET /api/v1/merchant/orders/{id}
    // =========================================================================

    public function test_merchant_can_view_own_store_order(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->create();

        $this->getJson("/api/v1/merchant/orders/{$order->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.id', $order->id);
    }

    public function test_merchant_cannot_view_other_stores_order(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $other = Order::factory()->create();

        $this->getJson("/api/v1/merchant/orders/{$other->id}", $this->headers($token))
             ->assertStatus(404);
    }

    public function test_order_show_returns_404_for_nonexistent(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->getJson('/api/v1/merchant/orders/99999', $this->headers($token))
             ->assertStatus(404);
    }

    // =========================================================================
    // PUT /api/v1/merchant/orders/{id}/status
    // =========================================================================

    public function test_merchant_can_confirm_order_without_a_contacted_state(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->pending()->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'confirmed'], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.status', 'confirmed');

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'confirmed']);
    }

    public function test_merchant_can_progress_order_through_required_lifecycle(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $order = Order::factory()->forStore($store)->pending()->create();

        foreach (['confirmed', 'completed'] as $status) {
            $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => $status], $this->headers($token))
                ->assertOk()
                ->assertJsonPath('data.status', $status);
        }

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'completed']);
    }

    public function test_merchant_cannot_skip_confirmation_before_completion(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $skippedTransitions = [
            ['pending_review', 'completed'],
            ['completed', 'confirmed'],
            ['completed', 'completed'],
            ['cancelled', 'confirmed'],
        ];

        foreach ($skippedTransitions as [$from, $to]) {
            $order = Order::factory()->forStore($store)->create(['status' => $from]);

            $this->putJson(
                "/api/v1/merchant/orders/{$order->id}/status",
                ['status' => $to],
                $this->headers($token),
            )->assertStatus(422);

            $this->assertDatabaseHas('orders', [
                'id' => $order->id,
                'status' => $from,
            ]);
        }
    }

    public function test_merchant_can_cancel_order(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->pending()->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'cancelled'], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_cancelling_order_twice_only_restores_stock_once(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $category = Category::factory()->create(['status' => 'active']);
        $product  = Product::factory()->for($store)->for($category)->create([
            'status'   => 'active',
            'quantity' => 10,
        ]);

        // Create a pending order with a real item so stock restoration can be measured
        $order = Order::factory()->forStore($store)->pending()->create();
        OrderItem::factory()->forOrder($order)->create([
            'product_id' => $product->id,
            'quantity'   => 3,
        ]);

        // Simulate stock already being decremented at checkout (as createWithItems does)
        $product->decrement('quantity', 3);
        $this->assertEquals(7, $product->fresh()->quantity);

        // First cancellation — should restore 3 units
        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'cancelled'], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.status', 'cancelled');

        $this->assertEquals(10, $product->fresh()->quantity);

        // Second cancellation — order is already cancelled; stock must NOT be restored again
        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'cancelled'], $this->headers($token))
             ->assertOk();

        $this->assertEquals(10, $product->fresh()->quantity, 'Cancelling an already-cancelled order must not restore stock a second time.');
    }

    public function test_merchant_cannot_update_other_stores_order_status(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $other = Order::factory()->create();

        $this->putJson("/api/v1/merchant/orders/{$other->id}/status", ['status' => 'confirmed'], $this->headers($token))
             ->assertStatus(404);
    }

    public function test_status_update_rejects_invalid_status(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'pending_review'], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_status_update_validates_required_field(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", [], $this->headers($token))
             ->assertStatus(422);
    }

    // =========================================================================
    // Order resource shape
    // =========================================================================

    public function test_order_detail_includes_items_and_client(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $order = Order::factory()->forStore($store)->create();
        OrderItem::factory()->forOrder($order)->create();

        $this->getJson("/api/v1/merchant/orders/{$order->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonStructure([
                 'data' => [
                     'id', 'status', 'total_amount',
                     'customer_name', 'customer_phone', 'customer_city',
                     'store'  => ['id', 'store_name'],
                     'client' => ['id', 'name', 'phone'],
                     'items'  => [['id', 'product_name', 'unit_price', 'quantity', 'subtotal']],
                 ],
             ])
             ->assertJsonPath('data.customer_phone', $order->customer_phone)
             ->assertJsonPath('data.client.phone', $order->client->phone);
    }
}
