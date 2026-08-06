<?php

namespace Tests\Feature\Client;

use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Client favorites API tests.
 */
class FavoriteTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function makeActiveProduct(): Product
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        return Product::factory()->active()->create(['store_id' => $store->id]);
    }

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_user_cannot_list_favorites(): void
    {
        $this->getJson('/api/v1/favorites')
            ->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_merchant_cannot_list_favorites(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/favorites', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_admin_cannot_list_favorites(): void
    {
        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/favorites', $this->headers($token))
            ->assertStatus(403);
    }

    // ── List favorites ────────────────────────────────────────────────────────

    public function test_client_can_list_empty_favorites(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/favorites', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    // ── Add to favorites ──────────────────────────────────────────────────────

    public function test_client_can_add_product_to_favorites(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $response = $this->postJson("/api/v1/favorites/{$product->id}", [], $this->headers($token));

        $response->assertStatus(201)->assertJson(['success' => true]);

        $this->assertDatabaseHas('favorites', [
            'user_id'    => $client->id,
            'product_id' => $product->id,
        ]);
    }

    public function test_adding_already_favorited_product_returns_200(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        // Add once
        $this->postJson("/api/v1/favorites/{$product->id}", [], $this->headers($token));

        // Add again
        $this->postJson("/api/v1/favorites/{$product->id}", [], $this->headers($token))
            ->assertStatus(200)
            ->assertJson(['success' => true]);
    }

    // ── Remove from favorites ─────────────────────────────────────────────────

    public function test_client_can_remove_product_from_favorites(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        // Add first
        $this->postJson("/api/v1/favorites/{$product->id}", [], $this->headers($token));

        // Remove
        $this->deleteJson("/api/v1/favorites/{$product->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('favorites', [
            'user_id'    => $client->id,
            'product_id' => $product->id,
        ]);
    }

    public function test_added_product_appears_in_favorites_list(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/favorites/{$product->id}", [], $this->headers($token));

        $response = $this->getJson('/api/v1/favorites', $this->headers($token));

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
        $this->assertSame($product->id, $response->json('data.data.0.product.id'));
    }
}
