<?php

namespace Tests\Feature\Client;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CartTest extends TestCase
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

    private function activeProduct(): Product
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        return Product::factory()->forStore($store)->active()->create();
    }

    // =========================================================================
    // Auth / Role guard
    // =========================================================================

    public function test_unauthenticated_cannot_access_cart(): void
    {
        $this->getJson('/api/v1/cart')->assertStatus(401);
    }

    public function test_merchant_cannot_access_client_cart(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/cart', $this->headers($token))->assertStatus(403);
    }

    // =========================================================================
    // GET /api/v1/cart
    // =========================================================================

    public function test_client_gets_empty_cart_on_first_load(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->getJson('/api/v1/cart', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.item_count', 0)
             ->assertJsonPath('data.subtotal', 0)
             ->assertJsonCount(0, 'data.items');
    }

    public function test_cart_is_created_automatically(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $this->assertDatabaseMissing('carts', ['user_id' => $client->id]);

        $this->getJson('/api/v1/cart', $this->headers($token))->assertOk();

        $this->assertDatabaseHas('carts', ['user_id' => $client->id]);
    }

    // =========================================================================
    // POST /api/v1/cart/items
    // =========================================================================

    public function test_client_can_add_product_to_cart(): void
    {
        ['token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();

        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 2,
        ], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.item_count', 1);
    }

    public function test_adding_same_product_increments_quantity(): void
    {
        ['token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();

        $this->postJson('/api/v1/cart/items', ['product_id' => $product->id, 'quantity' => 2], $this->headers($token));
        $this->postJson('/api/v1/cart/items', ['product_id' => $product->id, 'quantity' => 3], $this->headers($token));

        $response = $this->getJson('/api/v1/cart', $this->headers($token));

        $this->assertEquals(5, $response->json('data.items.0.quantity'));
    }

    public function test_cannot_add_inactive_product_to_cart(): void
    {
        ['token' => $token] = $this->actingAsClient();
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $product  = Product::factory()->forStore($store)->create(['status' => 'inactive']);

        $this->postJson('/api/v1/cart/items', ['product_id' => $product->id, 'quantity' => 1], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_add_item_validates_required_fields(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->postJson('/api/v1/cart/items', [], $this->headers($token))
             ->assertStatus(422);
    }

    public function test_cart_subtotal_is_calculated_correctly(): void
    {
        ['token' => $token] = $this->actingAsClient();
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();

        $product = Product::factory()->forStore($store)->active()->create(['price' => 50.00]);

        $this->postJson('/api/v1/cart/items', ['product_id' => $product->id, 'quantity' => 3], $this->headers($token));

        $response = $this->getJson('/api/v1/cart', $this->headers($token));

        $this->assertEquals(150.0, $response->json('data.subtotal'));
    }

    // =========================================================================
    // PUT /api/v1/cart/items/{id}
    // =========================================================================

    public function test_client_can_update_cart_item_quantity(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();

        $cart = Cart::factory()->forUser($client)->create();
        $item = CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => 2]);

        $this->putJson("/api/v1/cart/items/{$item->id}", ['quantity' => 5], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true);

        $this->assertDatabaseHas('cart_items', ['id' => $item->id, 'quantity' => 5]);
    }

    public function test_cannot_update_another_clients_cart_item(): void
    {
        ['token' => $token] = $this->actingAsClient();

        // Item belonging to a different client
        $otherClient = User::factory()->client()->create();
        $otherCart   = Cart::factory()->forUser($otherClient)->create();
        $product     = $this->activeProduct();
        $otherItem   = CartItem::factory()->forCart($otherCart)->forProduct($product)->create();

        $this->putJson("/api/v1/cart/items/{$otherItem->id}", ['quantity' => 10], $this->headers($token))
             ->assertStatus(404);
    }

    // =========================================================================
    // DELETE /api/v1/cart/items/{id}
    // =========================================================================

    public function test_client_can_remove_item_from_cart(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();

        $cart = Cart::factory()->forUser($client)->create();
        $item = CartItem::factory()->forCart($cart)->forProduct($product)->create([
            'quantity' => 1,
        ]);

        $this->deleteJson("/api/v1/cart/items/{$item->id}", [], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.item_count', 0);

        $this->assertDatabaseMissing('cart_items', ['id' => $item->id]);
    }

    public function test_cannot_remove_another_clients_cart_item(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $otherClient = User::factory()->client()->create();
        $otherCart   = Cart::factory()->forUser($otherClient)->create();
        $product     = $this->activeProduct();
        $otherItem   = CartItem::factory()->forCart($otherCart)->forProduct($product)->create();

        $this->deleteJson("/api/v1/cart/items/{$otherItem->id}", [], $this->headers($token))
             ->assertStatus(404);
    }

    public function test_client_can_clear_their_server_cart(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();
        $cart = Cart::factory()->forUser($client)->create();
        CartItem::factory()->forCart($cart)->forProduct($product)->create(['quantity' => 2]);

        $this->deleteJson('/api/v1/cart', [], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.item_count', 0)
            ->assertJsonCount(0, 'data.items');

        $this->assertDatabaseMissing('cart_items', ['cart_id' => $cart->id]);
    }

    public function test_updating_cart_rejects_a_product_that_is_no_longer_available(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();
        $product = $this->activeProduct();
        $cart = Cart::factory()->forUser($client)->create();
        $item = CartItem::factory()->forCart($cart)->forProduct($product)->create([
            'quantity' => 1,
        ]);
        $product->update(['status' => 'out_of_stock']);

        $this->putJson("/api/v1/cart/items/{$item->id}", ['quantity' => 2], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);

        $this->assertDatabaseHas('cart_items', ['id' => $item->id, 'quantity' => 1]);
    }
}
