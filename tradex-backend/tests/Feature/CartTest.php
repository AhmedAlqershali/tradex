<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Cart API tests. Complements Tests\Feature\Client\CartTest.
 */
class CartTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function makeProduct(): Product
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();

        return Product::factory()->active()->create([
            'store_id' => $store->id,
            'price'    => 25.00,
            'quantity' => 20,
        ]);
    }

    // ── Access control ────────────────────────────────────────────────────────

    public function test_unauthenticated_user_cannot_access_cart(): void
    {
        $this->getJson('/api/v1/cart')
            ->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_merchant_cannot_access_cart(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/cart', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_admin_cannot_access_cart(): void
    {
        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/cart', $this->headers($token))
            ->assertStatus(403);
    }

    // ── Cart operations ───────────────────────────────────────────────────────

    public function test_client_can_view_empty_cart(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/cart', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_client_can_add_item_to_cart(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeProduct();

        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 2,
        ], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_client_can_update_cart_item(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeProduct();

        // Add item
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 1,
        ], $this->headers($token));

        // Get cart to find item id
        $cartResponse = $this->getJson('/api/v1/cart', $this->headers($token));
        $itemId       = $cartResponse->json('data.items.0.id');

        $this->putJson("/api/v1/cart/items/{$itemId}", ['quantity' => 3], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_client_can_remove_cart_item(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeProduct();

        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 1,
        ], $this->headers($token));

        $cartResponse = $this->getJson('/api/v1/cart', $this->headers($token));
        $itemId       = $cartResponse->json('data.items.0.id');

        $this->deleteJson("/api/v1/cart/items/{$itemId}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }
}
