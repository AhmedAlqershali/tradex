<?php

namespace Tests\Feature\Client;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // GET /api/v1/categories
    // =========================================================================

    public function test_anyone_can_list_active_categories(): void
    {
        Category::factory()->count(3)->create(['status' => 'active']);
        Category::factory()->count(2)->create(['status' => 'inactive']);

        $response = $this->getJson('/api/v1/categories');

        $response->assertOk()
                 ->assertJsonPath('success', true)
                 ->assertJsonCount(3, 'data.data');
    }

    public function test_inactive_categories_are_excluded(): void
    {
        Category::factory()->create(['name' => 'Visible', 'status' => 'active']);
        Category::factory()->create(['name' => 'Hidden',  'status' => 'inactive']);

        $this->getJson('/api/v1/categories')
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.name', 'Visible');
    }

    public function test_response_includes_pagination_meta(): void
    {
        Category::factory()->count(5)->create(['status' => 'active']);

        $response = $this->getJson('/api/v1/categories?per_page=2');

        $response->assertOk()
                 ->assertJsonPath('data.pagination.total', 5)
                 ->assertJsonPath('data.pagination.per_page', 2)
                 ->assertJsonPath('data.pagination.last_page', 3);
    }

    public function test_category_resource_shape(): void
    {
        Category::factory()->create(['name' => 'Electronics', 'status' => 'active']);

        $response = $this->getJson('/api/v1/categories');

        $response->assertOk()
                 ->assertJsonStructure([
                     'success',
                     'message',
                     'data' => [
                         'data' => [['id', 'name', 'image', 'status', 'created_at']],
                         'pagination' => ['total', 'per_page', 'current_page', 'last_page'],
                     ],
                 ]);
    }

    public function test_categories_ordered_alphabetically(): void
    {
        Category::factory()->create(['name' => 'Shoes',       'status' => 'active']);
        Category::factory()->create(['name' => 'Electronics', 'status' => 'active']);
        Category::factory()->create(['name' => 'Clothing',    'status' => 'active']);

        $response = $this->getJson('/api/v1/categories');

        $names = collect($response->json('data.data'))->pluck('name')->toArray();

        $this->assertEquals(['Clothing', 'Electronics', 'Shoes'], $names);
    }
}
