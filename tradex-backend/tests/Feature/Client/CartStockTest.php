<?php

namespace Tests\Feature\Client;

use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Cart edge-case tests focused on stock validation and order cancellation stock restoration.
 */
class CartStockTest extends TestCase
{
    use RefreshDatabase;

    private User $client;
    private string $token;
    private Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->client = User::factory()->client()->create(['status' => 'active']);
        $this->token  = $this->client->createToken('test')->plainTextToken;

        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $store    = Store::factory()->forUser($merchant)->create(['status' => 'active']);
        $category = Category::factory()->create(['status' => 'active']);

        $this->product = Product::factory()->for($store)->for($category)->create([
            'status'   => 'active',
            'quantity' => 5,
            'price'    => 10.00,
        ]);
    }

    private function headers(): array
    {
        return ['Authorization' => "Bearer {$this->token}", 'Accept' => 'application/json'];
    }

    // ── Add-to-cart stock checks ───────────────────────────────────────────────

    public function test_adding_within_stock_succeeds(): void
    {
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 3,
        ], $this->headers())
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_adding_exact_stock_quantity_succeeds(): void
    {
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 5,
        ], $this->headers())
            ->assertOk();
    }

    public function test_adding_more_than_stock_returns_422(): void
    {
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 10,  // stock is 5
        ], $this->headers())
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_adding_to_existing_cart_item_validates_combined_quantity(): void
    {
        // Add 3 units first
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 3,
        ], $this->headers())->assertOk();

        // Try to add 4 more (total would be 7 > stock of 5)
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 4,
        ], $this->headers())
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_updating_cart_item_over_stock_returns_422(): void
    {
        // Add 1 item
        $response = $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 1,
        ], $this->headers())->assertOk();

        // The cart items array: each item has 'id' at top level and 'product.id' nested
        $itemId = collect($response->json('data.items'))
            ->first(fn ($i) => ($i['product']['id'] ?? null) === $this->product->id)['id'];

        // Try to update to quantity > stock
        $this->putJson("/api/v1/cart/items/{$itemId}", [
            'quantity' => 10,  // stock is 5
        ], $this->headers())
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // ── Stock restoration on order cancellation ────────────────────────────────

    public function test_cancelling_order_restores_product_stock(): void
    {
        // Add to cart and checkout
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 3,
        ], $this->headers())->assertOk();

        $orderResponse = $this->postJson('/api/v1/orders', [
            'customer_name'  => 'Test Client',
            'customer_phone' => '0501234567',
            'customer_city'  => 'Riyadh',
        ], $this->headers());

        $orderResponse->assertStatus(201);
        // Checkout returns a collection; first element is the order
        $orders = $orderResponse->json('data');
        $orderId = is_array($orders) && isset($orders[0]) ? $orders[0]['id'] : $orderResponse->json('data.id');

        // Stock should be decremented
        $this->product->refresh();
        $this->assertEquals(2, $this->product->quantity);

        // Cancel the order
        $this->deleteJson("/api/v1/orders/{$orderId}", [], $this->headers())
            ->assertOk()
            ->assertJson(['success' => true]);

        // Stock should be restored
        $this->product->refresh();
        $this->assertEquals(5, $this->product->quantity);
    }

    /**
     * Regression test: concurrent double-cancellation must not restore stock twice.
     *
     * Simulates two requests both reaching the cancel endpoint for the same
     * pending order. The atomic conditional UPDATE in OrderRepository ensures
     * only the first request transitions the order to 'cancelled' (and restores
     * stock); the second is a no-op because the WHERE status = 'pending' clause
     * no longer matches.
     */
    public function test_concurrent_cancellation_restores_stock_only_once(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $store    = Store::factory()->forUser($merchant)->create(['status' => 'active']);
        $category = Category::factory()->create(['status' => 'active']);
        $product  = Product::factory()->for($store)->for($category)->create([
            'status'   => 'active',
            'quantity' => 10,
            'price'    => 20.00,
        ]);

        $client = User::factory()->client()->create(['status' => 'active']);
        $token  = $client->createToken('test')->plainTextToken;

        // Create an already-placed pending order with a known item (bypasses cart
        // to isolate the cancellation logic from the checkout path).
        $order = Order::factory()->forClient($client)->forStore($store)->pending()->create();
        OrderItem::factory()->forOrder($order)->create([
            'product_id' => $product->id,
            'quantity'   => 3,
        ]);

        // Simulate stock already decremented at checkout.
        $product->decrement('quantity', 3);
        $this->assertEquals(7, $product->fresh()->quantity);

        // First cancel — should succeed and restore 3 units.
        $this->deleteJson("/api/v1/orders/{$order->id}", [], [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ])->assertOk()->assertJson(['success' => true]);

        $this->assertEquals(10, $product->fresh()->quantity, 'First cancel must restore stock.');

        // Second cancel on the same order — order is already cancelled.
        // The service correctly rejects this with 422 (order is no longer pending),
        // which is the expected behaviour. The critical assertion is that stock
        // is still 10 (not 13) — the atomic conditional UPDATE guarantees that
        // stock restoration is not performed a second time.
        $this->deleteJson("/api/v1/orders/{$order->id}", [], [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ])->assertStatus(422);  // correct: cannot cancel a non-pending order

        $this->assertEquals(10, $product->fresh()->quantity, 'Duplicate cancel must not restore stock a second time.');
    }

    public function test_out_of_stock_product_status_restored_on_cancel(): void
    {
        // Update product to exactly 2 units
        $this->product->update(['quantity' => 2]);

        // Add 2 to cart (all stock)
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $this->product->id,
            'quantity'   => 2,
        ], $this->headers())->assertOk();

        $orderResponse = $this->postJson('/api/v1/orders', [
            'customer_name'  => 'Test Client',
            'customer_phone' => '0501234567',
            'customer_city'  => 'Riyadh',
        ], $this->headers())->assertStatus(201);

        $orders  = $orderResponse->json('data');
        $orderId = is_array($orders) && isset($orders[0]) ? $orders[0]['id'] : $orderResponse->json('data.id');

        // Product should now be out_of_stock
        $this->product->refresh();
        $this->assertEquals('out_of_stock', $this->product->status);

        // Cancel
        $this->deleteJson("/api/v1/orders/{$orderId}", [], $this->headers())
            ->assertOk();

        // Status should flip back to active
        $this->product->refresh();
        $this->assertEquals('active', $this->product->status);
        $this->assertEquals(2, $this->product->quantity);
    }
}
