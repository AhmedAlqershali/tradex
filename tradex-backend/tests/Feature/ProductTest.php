<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Product API tests covering public browsing, search/filter, and merchant CRUD.
 * Complements Tests\Feature\Client\ProductTest and Tests\Feature\Merchant\ProductTest.
 */
class ProductTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function actingAsMerchant(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;
        return compact('merchant', 'store', 'token');
    }

    // ── Public browsing ───────────────────────────────────────────────────────

    public function test_anyone_can_browse_active_products(): void
    {
        $store = Store::factory()->active()->create();
        Product::factory()->active()->count(3)->create(['store_id' => $store->id]);

        $this->getJson('/api/v1/products')
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_products_can_be_searched_by_keyword(): void
    {
        $store = Store::factory()->active()->create();
        Product::factory()->active()->create(['store_id' => $store->id, 'name' => 'Unique Widget XYZ']);
        Product::factory()->active()->create(['store_id' => $store->id, 'name' => 'Something Else']);

        $response = $this->getJson('/api/v1/products?search=Widget');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
        $this->assertStringContainsString('Widget', $response->json('data.data.0.name'));
    }

    public function test_products_can_be_filtered_by_category(): void
    {
        $store    = Store::factory()->active()->create();
        $catA     = Category::factory()->create();
        $catB     = Category::factory()->create();

        Product::factory()->active()->create(['store_id' => $store->id, 'category_id' => $catA->id]);
        Product::factory()->active()->create(['store_id' => $store->id, 'category_id' => $catB->id]);

        $response = $this->getJson("/api/v1/products?category_id={$catA->id}");

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
    }

    public function test_products_can_be_filtered_by_price_range(): void
    {
        $store = Store::factory()->active()->create();
        Product::factory()->active()->create(['store_id' => $store->id, 'price' => 10]);
        Product::factory()->active()->create(['store_id' => $store->id, 'price' => 50]);
        Product::factory()->active()->create(['store_id' => $store->id, 'price' => 100]);

        $response = $this->getJson('/api/v1/products?price_min=20&price_max=60');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
    }

    public function test_single_active_product_can_be_retrieved(): void
    {
        $store   = Store::factory()->active()->create();
        $product = Product::factory()->active()->create(['store_id' => $store->id]);

        $this->getJson("/api/v1/products/{$product->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $product->id);
    }

    public function test_inactive_product_returns_404(): void
    {
        $store   = Store::factory()->active()->create();
        $product = Product::factory()->create(['store_id' => $store->id, 'status' => 'inactive']);

        $this->getJson("/api/v1/products/{$product->id}")
            ->assertStatus(404);
    }

    // ── Merchant CRUD ─────────────────────────────────────────────────────────

    public function test_merchant_can_create_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $category = Category::factory()->create();

        $this->postJson('/api/v1/merchant/products', [
            'store_id'    => $store->id,
            'category_id' => $category->id,
            'name'        => 'New Product',
            'price'       => 99.99,
            'quantity'    => 10,
        ], $this->headers($token))
            ->assertStatus(201)
            ->assertJsonPath('data.name', 'New Product');

        $this->assertDatabaseHas('products', ['name' => 'New Product']);
    }

    public function test_merchant_can_update_own_product(): void
    {
        ['merchant' => $merchant, 'store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->create(['store_id' => $store->id, 'name' => 'Old Name']);

        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'name'  => 'Updated Name',
            'price' => 50,
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Name');
    }

    public function test_merchant_can_delete_own_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->create(['store_id' => $store->id]);

        $this->deleteJson("/api/v1/merchant/products/{$product->id}", [], $this->headers($token))
            ->assertOk();

        $this->assertDatabaseMissing('products', ['id' => $product->id]);
    }

    public function test_merchant_cannot_access_other_merchant_products(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        // Another merchant's product
        $other        = User::factory()->merchant()->create();
        $otherStore   = Store::factory()->forUser($other)->active()->create();
        $otherProduct = Product::factory()->create(['store_id' => $otherStore->id]);

        $this->getJson("/api/v1/merchant/products/{$otherProduct->id}", $this->headers($token))
            ->assertStatus(404);
    }

    // ── Product response structure ────────────────────────────────────────────

    public function test_product_response_includes_rating_fields(): void
    {
        $store   = Store::factory()->active()->create();
        $product = Product::factory()->active()->create(['store_id' => $store->id]);

        $response = $this->getJson("/api/v1/products/{$product->id}");

        $response->assertOk()
            ->assertJsonStructure(['data' => ['id', 'name', 'price', 'average_rating', 'review_count']]);
    }
}
