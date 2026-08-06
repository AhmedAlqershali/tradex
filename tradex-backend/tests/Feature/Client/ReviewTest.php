<?php

namespace Tests\Feature\Client;

use App\Models\Product;
use App\Models\Review;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Client review API tests.
 *
 * Covers:
 *  - Public: list reviews for a product
 *  - Client: submit a review, delete own review
 *  - Auth / role guards
 */
class ReviewTest extends TestCase
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

    // ── Public listing ────────────────────────────────────────────────────────

    public function test_anyone_can_list_reviews_for_active_product(): void
    {
        $product = $this->makeActiveProduct();
        $client  = User::factory()->client()->create();
        Review::factory()->forProduct($product)->forUser($client)->rating(5)->create(['comment' => 'Great!']);

        $this->getJson("/api/v1/products/{$product->id}/reviews")
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_reviews_listing_returns_correct_structure(): void
    {
        $product = $this->makeActiveProduct();
        $client  = User::factory()->client()->create();
        Review::factory()->forProduct($product)->forUser($client)->create();

        $response = $this->getJson("/api/v1/products/{$product->id}/reviews");

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'data' => [
                        ['id', 'rating', 'comment', 'reviewer', 'created_at'],
                    ],
                ],
            ]);
    }

    public function test_listing_reviews_for_non_existent_product_returns_404(): void
    {
        $this->getJson('/api/v1/products/99999/reviews')
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    public function test_listing_reviews_for_inactive_product_returns_404(): void
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $product  = Product::factory()->create(['store_id' => $store->id, 'status' => 'inactive']);

        $this->getJson("/api/v1/products/{$product->id}/reviews")
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    // ── Role guard: submit review ─────────────────────────────────────────────

    public function test_unauthenticated_user_cannot_submit_review(): void
    {
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 5,
        ])->assertStatus(401);
    }

    public function test_merchant_cannot_submit_review(): void
    {
        $product  = $this->makeActiveProduct();
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 5,
        ], $this->headers($token))->assertStatus(403);
    }

    public function test_admin_cannot_submit_review(): void
    {
        $product = $this->makeActiveProduct();
        $admin   = User::factory()->admin()->create();
        $token   = $admin->createToken('test')->plainTextToken;

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 5,
        ], $this->headers($token))->assertStatus(403);
    }

    // ── Submit review ─────────────────────────────────────────────────────────

    public function test_client_can_submit_a_review(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating'  => 4,
            'comment' => 'Very good product.',
        ], $this->headers($token))
            ->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.rating', 4)
            ->assertJsonPath('data.comment', 'Very good product.');

        $this->assertDatabaseHas('reviews', [
            'product_id' => $product->id,
            'user_id'    => $client->id,
            'rating'     => 4,
        ]);
    }

    public function test_client_cannot_review_same_product_twice(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        Review::factory()->forProduct($product)->forUser($client)->create();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 3,
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_review_rating_must_be_between_1_and_5(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 6,
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_review_rating_is_required(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'comment' => 'No rating here.',
        ], $this->headers($token))
            ->assertStatus(422);
    }

    public function test_review_comment_is_optional(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating' => 5,
        ], $this->headers($token))
            ->assertStatus(201)
            ->assertJson(['success' => true]);
    }

    public function test_submitting_review_for_non_existent_product_returns_404(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/products/99999/reviews', [
            'rating' => 5,
        ], $this->headers($token))
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    // ── Delete review ─────────────────────────────────────────────────────────

    public function test_client_can_delete_own_review(): void
    {
        $client  = User::factory()->client()->create();
        $token   = $client->createToken('test')->plainTextToken;
        $product = $this->makeActiveProduct();
        $review  = Review::factory()->forProduct($product)->forUser($client)->create();

        $this->deleteJson("/api/v1/reviews/{$review->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('reviews', ['id' => $review->id]);
    }

    public function test_client_cannot_delete_another_clients_review(): void
    {
        $client1  = User::factory()->client()->create();
        $client2  = User::factory()->client()->create();
        $token    = $client2->createToken('test')->plainTextToken;
        $product  = $this->makeActiveProduct();
        $review   = Review::factory()->forProduct($product)->forUser($client1)->create();

        $this->deleteJson("/api/v1/reviews/{$review->id}", [], $this->headers($token))
            ->assertStatus(403)
            ->assertJson(['success' => false]);
    }

    public function test_deleting_non_existent_review_returns_404(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->deleteJson('/api/v1/reviews/99999', [], $this->headers($token))
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    public function test_unauthenticated_user_cannot_delete_review(): void
    {
        $product = $this->makeActiveProduct();
        $client  = User::factory()->client()->create();
        $review  = Review::factory()->forProduct($product)->forUser($client)->create();

        $this->deleteJson("/api/v1/reviews/{$review->id}")
            ->assertStatus(401);
    }
}
