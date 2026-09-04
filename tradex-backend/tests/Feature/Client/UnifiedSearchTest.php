<?php

namespace Tests\Feature\Client;

use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UnifiedSearchTest extends TestCase
{
    use RefreshDatabase;

    private function activeStore(array $attributes = []): Store
    {
        $merchant = User::factory()->merchant()->create();

        return Store::factory()->forUser($merchant)->active()->create($attributes);
    }

    public function test_search_returns_matching_products_and_stores(): void
    {
        $store = $this->activeStore(['store_name' => 'Apple Store']);
        Product::factory()->forStore($store)->active()->create([
            'name' => 'iPhone 17',
            'description' => 'Apple smartphone',
        ]);

        $response = $this->getJson('/api/v1/search?query=Apple');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.stores.data.0.store_name', 'Apple Store');
        $this->assertSame(
            'iPhone 17',
            $response->json('data.products.data.0.name'),
        );
    }

    public function test_search_supports_partial_store_names(): void
    {
        $this->activeStore(['store_name' => 'Apple Mobile']);
        $this->activeStore(['store_name' => 'Books Corner']);

        $response = $this->getJson('/api/v1/search?query=app')->assertOk();

        $names = collect($response->json('data.stores.data'))->pluck('store_name');
        $this->assertSame(['Apple Mobile'], $names->all());
    }

    public function test_store_products_endpoint_returns_only_available_products(): void
    {
        $store = $this->activeStore(['store_name' => 'Catalog Store']);
        Product::factory()->forStore($store)->active()->create(['name' => 'Available']);
        Product::factory()->forStore($store)->create([
            'name' => 'Inactive',
            'status' => 'inactive',
        ]);
        Product::factory()->forStore($store)->create([
            'name' => 'Out of stock',
            'status' => 'out_of_stock',
            'quantity' => 0,
        ]);

        $response = $this->getJson("/api/v1/stores/{$store->id}/products")
            ->assertOk()
            ->assertJsonPath('success', true);

        $names = collect($response->json('data.data'))->pluck('name');
        $this->assertSame(['Available'], $names->all());
    }

    public function test_store_details_returns_public_store_data(): void
    {
        $store = $this->activeStore([
            'store_name' => 'Public Store',
            'description' => 'A public description',
        ]);

        $this->getJson("/api/v1/stores/{$store->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $store->id)
            ->assertJsonPath('data.store_name', 'Public Store')
            ->assertJsonPath('data.description', 'A public description');
    }

    public function test_missing_store_products_returns_not_found(): void
    {
        $this->getJson('/api/v1/stores/999999/products')
            ->assertNotFound()
            ->assertJsonPath('success', false);
    }

    public function test_search_does_not_expose_private_merchant_information(): void
    {
        $store = $this->activeStore(['store_name' => 'Public Store']);
        $store->owner->update(['phone' => '0500000000']);

        $response = $this->getJson('/api/v1/search?query=Public')->assertOk();

        $result = $response->json('data.stores.data.0');
        $this->assertArrayNotHasKey('phone', $result);
        $this->assertArrayNotHasKey('user_id', $result);
    }

    public function test_blank_search_query_is_rejected(): void
    {
        $this->getJson('/api/v1/search?query=%20%20')
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }
}