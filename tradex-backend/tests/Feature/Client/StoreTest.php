<?php

namespace Tests\Feature\Client;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StoreTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // GET /api/v1/stores
    // =========================================================================

    public function test_anyone_can_list_active_stores(): void
    {
        Store::factory()->count(3)->create(['status' => 'active']);
        Store::factory()->count(2)->create(['status' => 'inactive']);

        $response = $this->getJson('/api/v1/stores');

        $response->assertOk()
                 ->assertJsonPath('success', true)
                 ->assertJsonCount(3, 'data.data');
    }

    public function test_inactive_stores_are_excluded(): void
    {
        Store::factory()->create(['store_name' => 'Open Store',   'status' => 'active']);
        Store::factory()->create(['store_name' => 'Closed Store', 'status' => 'inactive']);
        Store::factory()->create(['store_name' => 'Suspended',    'status' => 'suspended']);

        $this->getJson('/api/v1/stores')
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.store_name', 'Open Store');
    }

    public function test_store_list_includes_products_count(): void
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $category = Category::factory()->create();

        Product::factory()->count(4)->forStore($store)->create(['status' => 'active']);

        $response = $this->getJson('/api/v1/stores');

        $response->assertOk();

        $found = collect($response->json('data.data'))
            ->firstWhere('id', $store->id);

        $this->assertNotNull($found);
        $this->assertEquals(4, $found['products_count']);
    }

    public function test_store_list_filters_by_region(): void
    {
        Store::factory()->active()->create([
            'store_name' => 'Central Store',
            'region' => 'الوسطى',
        ]);
        Store::factory()->active()->create([
            'store_name' => 'Gaza Store',
            'region' => 'غزة',
        ]);

        $response = $this->getJson('/api/v1/stores?region=' . urlencode('الوسطى'));

        $response->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.store_name', 'Central Store')
            ->assertJsonPath('data.data.0.region', 'الوسطى');
    }

    public function test_store_list_response_shape(): void
    {
        Store::factory()->active()->create();

        $response = $this->getJson('/api/v1/stores');

        $response->assertOk()
                 ->assertJsonStructure([
                     'success',
                     'message',
                     'data' => [
                         'data' => [[
                             'id', 'store_name', 'description',
                             'logo', 'status', 'products_count', 'created_at',
                         ]],
                         'pagination' => ['total', 'per_page', 'current_page', 'last_page'],
                     ],
                 ]);
    }

    public function test_store_list_supports_pagination(): void
    {
        Store::factory()->count(6)->active()->create();

        $response = $this->getJson('/api/v1/stores?per_page=2');

        $response->assertOk()
                 ->assertJsonPath('data.pagination.total', 6)
                 ->assertJsonPath('data.pagination.per_page', 2)
                 ->assertJsonPath('data.pagination.last_page', 3);
    }

    // =========================================================================
    // GET /api/v1/stores/{id}
    // =========================================================================

    public function test_anyone_can_view_active_store(): void
    {
        $store = Store::factory()->active()->create();

        $this->getJson("/api/v1/stores/{$store->id}")
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.id', $store->id);
    }

    public function test_inactive_store_returns_404(): void
    {
        $store = Store::factory()->create(['status' => 'inactive']);

        $this->getJson("/api/v1/stores/{$store->id}")
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    public function test_nonexistent_store_returns_404(): void
    {
        $this->getJson('/api/v1/stores/99999')
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    public function test_store_show_includes_products_count(): void
    {
        $merchant = User::factory()->merchant()->create();
        $store    = Store::factory()->forUser($merchant)->active()->create();

        Product::factory()->count(3)->forStore($store)->create(['status' => 'active']);

        $response = $this->getJson("/api/v1/stores/{$store->id}");

        $response->assertOk()
                 ->assertJsonPath('data.products_count', 3);
    }
}
