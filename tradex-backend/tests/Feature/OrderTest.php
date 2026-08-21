<?php

namespace Tests\Feature;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Cross-cutting order tests: covers the full checkout flow, order lifecycle,
 * and status constants — complementing the more focused tests in
 * Tests\Feature\Client\OrderTest and Tests\Feature\Merchant\OrderTest.
 */
class OrderTest extends TestCase
{
    use RefreshDatabase;

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    /**
     * Set up an active merchant + store + product, and a client with a
     * pre-seeded cart item pointing to that product.
     */
    private function seedCheckoutFixture(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $product  = Product::factory()->active()->create([
            'store_id' => $store->id,
            'price'    => 50.00,
            'quantity' => 100,
        ]);

        $client      = User::factory()->client()->create();
        $clientToken = $client->createToken('test')->plainTextToken;

        $cart = Cart::create(['user_id' => $client->id]);
        // cart_id is excluded from CartItem::$fillable (mass-assignment protection);
        // use the HasMany relationship so Laravel sets cart_id automatically.
        $cart->items()->create([
            'product_id' => $product->id,
            'quantity'   => 2,
        ]);

        return compact('merchant', 'store', 'product', 'client', 'clientToken', 'cart');
    }

    // ── Checkout flow ─────────────────────────────────────────────────────────

    public function test_client_can_checkout_and_order_is_created(): void
    {
        [
            'merchant' => $merchant,
            'client' => $client,
            'clientToken' => $token,
        ] = $this->seedCheckoutFixture();

        $response = $this->postJson('/api/v1/orders', [
            'customer_name'  => 'John Test',
            'customer_phone' => '0501234567',
            'customer_city'  => 'Riyadh',
        ], $this->headers($token));

        $response->assertStatus(201)->assertJson(['success' => true]);

        $this->assertDatabaseHas('orders', [
            'client_id' => $client->id,
            'status'    => 'pending',
        ]);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $client->id,
            'type'    => 'order_placed',
        ]);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $merchant->id,
            'type'    => 'new_order',
        ]);
    }

    public function test_checkout_decrements_product_stock(): void
    {
        [
            'clientToken' => $token,
            'product'     => $product,
        ] = $this->seedCheckoutFixture();

        $initialQty = $product->quantity;

        $this->postJson('/api/v1/orders', [
            'customer_name'  => 'John',
            'customer_phone' => '050',
            'customer_city'  => 'Riyadh',
        ], $this->headers($token));

        $this->assertLessThan($initialQty, $product->fresh()->quantity);
    }

    public function test_cart_is_empty_after_checkout(): void
    {
        ['client' => $client, 'clientToken' => $token] = $this->seedCheckoutFixture();

        $this->postJson('/api/v1/orders', [
            'customer_name'  => 'John',
            'customer_phone' => '050',
            'customer_city'  => 'Riyadh',
        ], $this->headers($token));

        $cartItems = \App\Models\CartItem::whereHas('cart', fn ($q) => $q->where('user_id', $client->id))->count();
        $this->assertSame(0, $cartItems);
    }

    // ── Client order lifecycle ────────────────────────────────────────────────

    public function test_client_can_cancel_pending_order(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $order = Order::factory()->forClient($client)->pending()->create();

        $response = $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token));

        $response->assertOk()->assertJson(['success' => true]);
        $this->assertSame('cancelled', $order->fresh()->status);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $order->store->owner->id,
            'type'    => 'order_cancelled',
        ]);
    }

    public function test_client_cannot_cancel_confirmed_order(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $order = Order::factory()->forClient($client)->confirmed()->create();

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
            ->assertStatus(422);
    }

    public function test_client_can_list_own_orders(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        Order::factory()->forClient($client)->count(3)->create();
        Order::factory()->count(2)->create(); // other clients

        $this->getJson('/api/v1/orders', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.pagination.total', 3);
    }

    // ── Merchant order management ─────────────────────────────────────────────

    public function test_merchant_can_view_incoming_orders(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        Order::factory()->forStore($store)->count(3)->create();

        $this->getJson('/api/v1/merchant/orders', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.pagination.total', 3);
    }

    public function test_merchant_can_update_order_status(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;
        $order    = Order::factory()->forStore($store)->pending()->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'contacted'], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertSame('contacted', $order->fresh()->status);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $order->client_id,
            'type'    => 'order_status_updated',
        ]);
    }

    public function test_merchant_cannot_set_invalid_order_status(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;
        $order    = Order::factory()->forStore($store)->pending()->create();

        $this->putJson("/api/v1/merchant/orders/{$order->id}/status", ['status' => 'invalid_status'], $this->headers($token))
            ->assertStatus(422);
    }

    // ── Status constants ──────────────────────────────────────────────────────

    public function test_order_statuses_are_correct(): void
    {
        $this->assertSame('pending',    Order::STATUS_PENDING);
        $this->assertSame('contacted',  Order::STATUS_CONTACTED);
        $this->assertSame('confirmed',  Order::STATUS_CONFIRMED);
        $this->assertSame('processing', Order::STATUS_PROCESSING);
        $this->assertSame('completed',  Order::STATUS_COMPLETED);
        $this->assertSame('cancelled',  Order::STATUS_CANCELLED);
    }
}
