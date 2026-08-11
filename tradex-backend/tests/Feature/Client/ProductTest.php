<?php

namespace Tests\Feature\Client;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function activeStore(): Store
    {
        $merchant = User::factory()->merchant()->create();
        return Store::factory()->forUser($merchant)->active()->create();
    }

    // =========================================================================
    // GET /api/v1/products — Listing
    // =========================================================================

    public function test_anyone_can_browse_active_products(): void
    {
        $store = $this->activeStore();

        Product::factory()->count(4)->forStore($store)->create(['status' => 'active']);
        Product::factory()->forStore($store)->create(['status' => 'inactive']);
        Product::factory()->forStore($store)->create(['status' => 'out_of_stock']);

        $response = $this->getJson('/api/v1/products');

        $response->assertOk()
                 ->assertJsonPath('success', true)
                 ->assertJsonCount(4, 'data.data');
    }

    public function test_inactive_products_are_excluded(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create(['status' => 'active',   'name' => 'Visible']);
        Product::factory()->forStore($store)->create(['status' => 'inactive', 'name' => 'Hidden']);

        $this->getJson('/api/v1/products')
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.name', 'Visible');
    }

    public function test_products_from_inactive_stores_are_excluded(): void
    {
        $merchant     = User::factory()->merchant()->create();
        $activeStore  = Store::factory()->forUser($merchant)->active()->create();
        $closedStore  = Store::factory()->forUser($merchant)->create(['status' => 'inactive']);

        Product::factory()->forStore($activeStore)->create(['status' => 'active']);
        Product::factory()->forStore($closedStore)->create(['status' => 'active']);

        $this->getJson('/api/v1/products')
             ->assertOk()
             ->assertJsonCount(1, 'data.data');
    }

    // =========================================================================
    // Filters
    // =========================================================================

    public function test_filter_by_category_id(): void
    {
        $store = $this->activeStore();
        $cat1  = Category::factory()->create();
        $cat2  = Category::factory()->create();

        Product::factory()->forStore($store)->inCategory($cat1)->count(2)->create(['status' => 'active']);
        Product::factory()->forStore($store)->inCategory($cat2)->create(['status' => 'active']);

        $this->getJson("/api/v1/products?category_id={$cat1->id}")
             ->assertOk()
             ->assertJsonCount(2, 'data.data');
    }

    public function test_category_with_no_products_returns_an_empty_list(): void
    {
        $store = $this->activeStore();
        $category = Category::factory()->create();

        $this->getJson("/api/v1/products?category_id={$category->id}")
             ->assertOk()
             ->assertJsonPath('data.data', [])
             ->assertJsonPath('data.pagination.total', 0);
    }

    public function test_filter_by_store_id(): void
    {
        $store1 = $this->activeStore();
        $store2 = $this->activeStore();

        Product::factory()->forStore($store1)->count(3)->create(['status' => 'active']);
        Product::factory()->forStore($store2)->create(['status' => 'active']);

        $this->getJson("/api/v1/products?store_id={$store1->id}")
             ->assertOk()
             ->assertJsonCount(3, 'data.data');
    }

    public function test_filter_by_price_range(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 10.00, 'name' => 'Cheap']);
        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 50.00, 'name' => 'Mid']);
        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 200.00, 'name' => 'Expensive']);

        $this->getJson('/api/v1/products?price_min=20&price_max=100')
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.name', 'Mid');
    }

    public function test_search_by_product_name(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create(['status' => 'active', 'name' => 'Leather Shoes']);
        Product::factory()->forStore($store)->create(['status' => 'active', 'name' => 'Cotton T-Shirt']);

        $this->getJson('/api/v1/products?search=Leather')
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.name', 'Leather Shoes');
    }

    // =========================================================================
    // Sorting
    // =========================================================================

    public function test_sort_by_newest(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create([
            'status'     => 'active',
            'name'       => 'Old Product',
            'created_at' => now()->subMinutes(10),
        ]);
        Product::factory()->forStore($store)->create([
            'status'     => 'active',
            'name'       => 'New Product',
            'created_at' => now(),
        ]);

        $response = $this->getJson('/api/v1/products?sort=newest');

        $this->assertEquals('New Product', $response->json('data.data.0.name'));
    }

    public function test_sort_by_price_ascending(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 100.00, 'name' => 'Expensive']);
        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 10.00,  'name' => 'Cheap']);

        $response = $this->getJson('/api/v1/products?sort=price_asc');

        $this->assertEquals('Cheap', $response->json('data.data.0.name'));
    }

    public function test_sort_by_price_descending(): void
    {
        $store = $this->activeStore();

        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 10.00,  'name' => 'Cheap']);
        Product::factory()->forStore($store)->create(['status' => 'active', 'price' => 100.00, 'name' => 'Expensive']);

        $response = $this->getJson('/api/v1/products?sort=price_desc');

        $this->assertEquals('Expensive', $response->json('data.data.0.name'));
    }

    // =========================================================================
    // Pagination
    // =========================================================================

    public function test_response_includes_pagination_meta(): void
    {
        $store = $this->activeStore();
        Product::factory()->count(10)->forStore($store)->create(['status' => 'active']);

        $response = $this->getJson('/api/v1/products?per_page=3');

        $response->assertOk()
                 ->assertJsonPath('data.pagination.total', 10)
                 ->assertJsonPath('data.pagination.per_page', 3)
                 ->assertJsonPath('data.pagination.last_page', 4);
    }

    // =========================================================================
    // Resource shape
    // =========================================================================

    public function test_product_resource_includes_store_and_category(): void
    {
        $store    = $this->activeStore();
        $category = Category::factory()->create();

        Product::factory()->forStore($store)->inCategory($category)->create(['status' => 'active']);

        $response = $this->getJson('/api/v1/products');

        $response->assertOk()
                 ->assertJsonStructure([
                     'data' => [
                         'data' => [[
                            'id', 'store_id', 'category_id', 'name', 'price',
                            'status', 'image', 'images',
                             'store'    => ['id', 'store_name', 'status'],
                             'category' => ['id', 'name'],
                         ]],
                     ],
                 ]);
    }

    // =========================================================================
    // GET /api/v1/products/{id} — Show
    // =========================================================================

    public function test_anyone_can_view_active_product(): void
    {
        $store   = $this->activeStore();
        $product = Product::factory()->forStore($store)->create(['status' => 'active']);

        $this->getJson("/api/v1/products/{$product->id}")
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.id', $product->id);
    }

    public function test_inactive_product_returns_404(): void
    {
        $store   = $this->activeStore();
        $product = Product::factory()->forStore($store)->create(['status' => 'inactive']);

        $this->getJson("/api/v1/products/{$product->id}")
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    public function test_product_in_inactive_store_returns_404(): void
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->create(['status' => 'inactive']);
        $product  = Product::factory()->forStore($store)->create(['status' => 'active']);

        $this->getJson("/api/v1/products/{$product->id}")
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    public function test_nonexistent_product_returns_404(): void
    {
        $this->getJson('/api/v1/products/99999')
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Permissions
    // =========================================================================

    public function test_product_list_is_public_no_auth_needed(): void
    {
        $store = $this->activeStore();
        Product::factory()->forStore($store)->create(['status' => 'active']);

        $this->getJson('/api/v1/products')
             ->assertOk();
    }

    public function test_product_show_is_public_no_auth_needed(): void
    {
        $store   = $this->activeStore();
        $product = Product::factory()->forStore($store)->create(['status' => 'active']);

        $this->getJson("/api/v1/products/{$product->id}")
             ->assertOk();
    }
}
