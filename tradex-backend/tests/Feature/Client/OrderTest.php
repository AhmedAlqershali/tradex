<?php

namespace Tests\Feature\Client;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
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

    private function actingAsClient(): array
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;
        return compact('client', 'token');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function contactPayload(): array
    {
        return [
            'customer_name'  => 'Ahmed Test',
            'customer_phone' => '0501234567',
            'customer_city'  => 'Riyadh',
            'notes'          => 'Please deliver fast.',
        ];
    }

    /**
     * Create a client with a cart that has one active product from a given store.
     *
     * The product's stock is always created well above the cart quantity so
     * these tests exercise the "happy path" deterministically. The
     * active() factory state assigns a *random* quantity (1-100), which
     * would otherwise make these tests flaky now that checkout performs
     * real stock validation — explicitly overriding `quantity` here removes
     * that flakiness.
     */
    private function clientWithCart(Store $store, int $quantity = 2): array
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = Product::factory()->forStore($store)->active()->create([
            'price'    => 100.00,
            'quantity' => 1000,
        ]);
        $cart    = Cart::factory()->forUser($client)->create();
        CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => $quantity]);

        return compact('client', 'token', 'product', 'cart');
    }

    private function activeStore(): Store
    {
        $merchant = User::factory()->merchant()->create();
        return Store::factory()->forUser($merchant)->active()->create();
    }

    // =========================================================================
    // Auth / Role guard
    // =========================================================================

    public function test_unauthenticated_cannot_create_order(): void
    {
        $this->postJson('/api/v1/orders', $this->contactPayload())->assertStatus(401);
    }

    public function test_merchant_cannot_create_order(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(403);
    }

    // =========================================================================
    // POST /api/v1/orders — Checkout
    // =========================================================================

    public function test_client_can_checkout_from_cart(): void
    {
        $store = $this->activeStore();
        ['token' => $token] = $this->clientWithCart($store);

        $response = $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token));

        $response->assertStatus(201)
                 ->assertJsonPath('success', true);

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
    }

    public function test_checkout_clears_the_cart(): void
    {
        $store = $this->activeStore();
        ['client' => $client, 'token' => $token, 'cart' => $cart] = $this->clientWithCart($store);

        $this->assertDatabaseCount('cart_items', 1);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        $this->assertDatabaseCount('cart_items', 0);
    }

    public function test_checkout_creates_order_per_store(): void
    {
        $store1 = $this->activeStore();
        $store2 = $this->activeStore();

        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $cart    = Cart::factory()->forUser($client)->create();

        $product1 = Product::factory()->forStore($store1)->active()->create(['price' => 50.00, 'quantity' => 1000]);
        $product2 = Product::factory()->forStore($store2)->active()->create(['price' => 80.00, 'quantity' => 1000]);

        CartItem::factory()->forCart($cart)->forProduct($product1)->create(['quantity' => 1]);
        CartItem::factory()->forCart($cart)->forProduct($product2)->create(['quantity' => 2]);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        // One order per store
        $this->assertDatabaseCount('orders', 2);
        $this->assertDatabaseHas('orders', ['store_id' => $store1->id, 'total_amount' => 50.00]);
        $this->assertDatabaseHas('orders', ['store_id' => $store2->id, 'total_amount' => 160.00]);
    }

    public function test_checkout_saves_order_items_as_snapshot(): void
    {
        $store = $this->activeStore();
        ['token' => $token, 'product' => $product] = $this->clientWithCart($store, 3);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        $this->assertDatabaseHas('order_items', [
            'product_id'   => $product->id,
            'product_name' => $product->name,
            'unit_price'   => $product->price,
            'quantity'     => 3,
            'subtotal'     => $product->price * 3,
        ]);
    }

    public function test_checkout_increments_product_total_sold(): void
    {
        $store = $this->activeStore();
        ['token' => $token, 'product' => $product] = $this->clientWithCart($store, 4);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        $this->assertDatabaseHas('products', [
            'id'         => $product->id,
            'total_sold' => 4,
        ]);
    }

    public function test_checkout_decrements_product_quantity(): void
    {
        $store = $this->activeStore();
        $product = Product::factory()->forStore($store)->active()->create(['quantity' => 10]);

        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;
        $cart   = Cart::factory()->forUser($client)->create();
        CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => 4]);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        $this->assertDatabaseHas('products', [
            'id'       => $product->id,
            'quantity' => 6,
        ]);
    }

    public function test_checkout_marks_product_out_of_stock_when_quantity_reaches_zero(): void
    {
        $store = $this->activeStore();
        $product = Product::factory()->forStore($store)->active()->create(['quantity' => 3]);

        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;
        $cart   = Cart::factory()->forUser($client)->create();
        CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => 3]);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(201);

        $this->assertDatabaseHas('products', [
            'id'       => $product->id,
            'quantity' => 0,
            'status'   => 'out_of_stock',
        ]);
    }

    public function test_checkout_rejects_when_stock_is_insufficient(): void
    {
        $store = $this->activeStore();
        $product = Product::factory()->forStore($store)->active()->create(['quantity' => 2]);

        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;
        $cart   = Cart::factory()->forUser($client)->create();
        CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => 5]);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);

        // No order should have been created, and stock must be untouched.
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'quantity' => 2]);
    }

    public function test_cannot_checkout_with_empty_cart(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_checkout_validates_contact_fields(): void
    {
        $store = $this->activeStore();
        ['token' => $token] = $this->clientWithCart($store);

        $this->postJson('/api/v1/orders', [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_checkout_saves_customer_contact_info(): void
    {
        $store = $this->activeStore();
        ['token' => $token] = $this->clientWithCart($store);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token));

        $this->assertDatabaseHas('orders', [
            'customer_name'  => 'Ahmed Test',
            'customer_phone' => '0501234567',
            'customer_city'  => 'Riyadh',
        ]);
    }

    public function test_new_order_has_pending_status(): void
    {
        $store = $this->activeStore();
        ['token' => $token] = $this->clientWithCart($store);

        $this->postJson('/api/v1/orders', $this->contactPayload(), $this->headers($token));

        $this->assertDatabaseHas('orders', ['status' => 'pending']);
    }

    // =========================================================================
    // GET /api/v1/orders
    // =========================================================================

    public function test_client_can_list_own_orders(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(3)->create();
        Order::factory()->count(2)->create(); // other clients' orders

        $this->getJson('/api/v1/orders', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.pagination.total', 3);
    }

    // =========================================================================
    // GET /api/v1/orders/{id}
    // =========================================================================

    public function test_client_can_view_own_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create();

        $this->getJson("/api/v1/orders/{$order->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.id', $order->id);
    }

    public function test_client_cannot_view_another_clients_order(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $other = Order::factory()->create();

        $this->getJson("/api/v1/orders/{$other->id}", $this->headers($token))
             ->assertStatus(404);
    }
}
