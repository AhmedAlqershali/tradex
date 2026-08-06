<?php

namespace Tests\Feature\Admin;

use App\Models\Product;
use App\Models\Review;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Admin review moderation API tests.
 */
class ReviewTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function actingAsAdmin(): array
    {
        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;
        return compact('admin', 'token');
    }

    private function makeProduct(string $status = 'active'): Product
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        return Product::factory()->create(['store_id' => $store->id, 'status' => $status]);
    }

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_list_reviews_as_admin(): void
    {
        $product = $this->makeProduct();

        $this->getJson("/api/v1/admin/products/{$product->id}/reviews")
            ->assertStatus(401);
    }

    public function test_client_cannot_moderate_reviews(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeProduct();

        $this->getJson("/api/v1/admin/products/{$product->id}/reviews", $this->headers($token))
            ->assertStatus(403);
    }

    public function test_merchant_cannot_moderate_reviews(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;
        $product  = $this->makeProduct();

        $this->getJson("/api/v1/admin/products/{$product->id}/reviews", $this->headers($token))
            ->assertStatus(403);
    }

    // ── List reviews ──────────────────────────────────────────────────────────

    public function test_admin_can_list_reviews_for_active_product(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $product = $this->makeProduct('active');
        $client  = User::factory()->client()->create();
        Review::factory()->forProduct($product)->forUser($client)->create();

        $this->getJson("/api/v1/admin/products/{$product->id}/reviews", $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_admin_can_list_reviews_for_inactive_product(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $product = $this->makeProduct('inactive');
        $client  = User::factory()->client()->create();
        Review::factory()->forProduct($product)->forUser($client)->create();

        // Key difference from public endpoint: inactive products are accessible
        $this->getJson("/api/v1/admin/products/{$product->id}/reviews", $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_admin_listing_reviews_for_non_existent_product_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/products/99999/reviews', $this->headers($token))
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    // ── Delete review ─────────────────────────────────────────────────────────

    public function test_admin_can_delete_any_review(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $product = $this->makeProduct();
        $client  = User::factory()->client()->create();
        $review  = Review::factory()->forProduct($product)->forUser($client)->create();

        $this->deleteJson("/api/v1/admin/reviews/{$review->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('reviews', ['id' => $review->id]);
    }

    public function test_deleting_non_existent_review_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->deleteJson('/api/v1/admin/reviews/99999', [], $this->headers($token))
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }
}
