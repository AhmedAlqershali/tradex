<?php

namespace Tests\Feature\Client;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests for the public category listing endpoint with search.
 *
 * GET /api/v1/categories — public, no authentication required.
 */
class CategorySearchTest extends TestCase
{
    use RefreshDatabase;

    private function createActiveCategory(string $name): Category
    {
        return Category::factory()->create(['name' => $name, 'status' => 'active']);
    }

    // =========================================================================
    // Basic listing
    // =========================================================================

    public function test_categories_list_is_paginated(): void
    {
        $this->createActiveCategory('Electronics');
        $this->createActiveCategory('Fashion');

        $this->getJson('/api/v1/categories?per_page=1')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_only_active_categories_are_returned(): void
    {
        $this->createActiveCategory('Active Category');
        Category::factory()->create(['name' => 'Inactive Category', 'status' => 'inactive']);

        $response = $this->getJson('/api/v1/categories')->assertOk();

        $names = collect($response->json('data.data'))->pluck('name');
        $this->assertContains('Active Category', $names);
        $this->assertNotContains('Inactive Category', $names);
    }

    // =========================================================================
    // Search
    // =========================================================================

    public function test_search_returns_matching_categories(): void
    {
        $this->createActiveCategory('Electronics');
        $this->createActiveCategory('Electronic Games');
        $this->createActiveCategory('Fashion');

        $response = $this->getJson('/api/v1/categories?search=Electronic')->assertOk();

        $names = collect($response->json('data.data'))->pluck('name');
        $this->assertContains('Electronics', $names);
        $this->assertContains('Electronic Games', $names);
        $this->assertNotContains('Fashion', $names);
    }

    public function test_search_is_case_insensitive(): void
    {
        $this->createActiveCategory('Books & Literature');

        $response = $this->getJson('/api/v1/categories?search=books')->assertOk();

        $names = collect($response->json('data.data'))->pluck('name');
        $this->assertContains('Books & Literature', $names);
    }

    public function test_search_with_no_matches_returns_empty(): void
    {
        $this->createActiveCategory('Electronics');

        $response = $this->getJson('/api/v1/categories?search=zzznomatch')->assertOk();

        $this->assertEmpty($response->json('data.data'));
    }

    public function test_empty_search_returns_all_active_categories(): void
    {
        $this->createActiveCategory('Electronics');
        $this->createActiveCategory('Fashion');

        $response = $this->getJson('/api/v1/categories?search=')->assertOk();

        $this->assertCount(2, $response->json('data.data'));
    }

    // =========================================================================
    // Validation
    // =========================================================================

    public function test_search_param_max_length_is_validated(): void
    {
        $this->getJson('/api/v1/categories?search=' . str_repeat('a', 101))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_per_page_must_be_positive_integer(): void
    {
        $this->getJson('/api/v1/categories?per_page=0')
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Response structure
    // =========================================================================

    public function test_category_response_has_standard_envelope(): void
    {
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data' => ['data', 'pagination']]);
    }
}
