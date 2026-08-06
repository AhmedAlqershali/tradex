<?php

namespace Tests\Feature\Client;

use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests for the public store listing endpoint with search and filtering.
 *
 * GET /api/v1/stores — public, no authentication required.
 */
class StoreSearchTest extends TestCase
{
    use RefreshDatabase;

    private function createActiveStore(string $name): Store
    {
        $merchant = User::factory()->merchant()->create();

        return Store::factory()->create([
            'user_id'    => $merchant->id,
            'store_name' => $name,
            'status'     => 'active',
        ]);
    }

    // =========================================================================
    // Basic listing
    // =========================================================================

    public function test_stores_list_is_paginated(): void
    {
        $this->createActiveStore('Alpha Store');
        $this->createActiveStore('Beta Store');

        $this->getJson('/api/v1/stores?per_page=1')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_stores_list_only_returns_active_stores(): void
    {
        $this->createActiveStore('Active Store');

        $merchant = User::factory()->merchant()->create();
        Store::factory()->create([
            'user_id'    => $merchant->id,
            'store_name' => 'Inactive Store',
            'status'     => 'inactive',
        ]);

        $response = $this->getJson('/api/v1/stores')->assertOk();

        $names = collect($response->json('data.data'))->pluck('store_name');
        $this->assertContains('Active Store', $names);
        $this->assertNotContains('Inactive Store', $names);
    }

    // =========================================================================
    // Search
    // =========================================================================

    public function test_search_returns_matching_stores(): void
    {
        $this->createActiveStore('Tech Gadgets Store');
        $this->createActiveStore('Fashion World');
        $this->createActiveStore('Tech Books Online');

        $response = $this->getJson('/api/v1/stores?search=Tech')->assertOk();

        $names = collect($response->json('data.data'))->pluck('store_name');
        $this->assertContains('Tech Gadgets Store', $names);
        $this->assertContains('Tech Books Online', $names);
        $this->assertNotContains('Fashion World', $names);
    }

    public function test_search_is_case_insensitive(): void
    {
        $this->createActiveStore('Electronics Hub');

        $response = $this->getJson('/api/v1/stores?search=electronics')->assertOk();

        $names = collect($response->json('data.data'))->pluck('store_name');
        $this->assertContains('Electronics Hub', $names);
    }

    public function test_search_with_no_matches_returns_empty_list(): void
    {
        $this->createActiveStore('Books & More');

        $response = $this->getJson('/api/v1/stores?search=zzznomatch')->assertOk();

        $this->assertEmpty($response->json('data.data'));
    }

    public function test_empty_search_returns_all_stores(): void
    {
        $this->createActiveStore('Store A');
        $this->createActiveStore('Store B');

        $response = $this->getJson('/api/v1/stores?search=')->assertOk();

        $this->assertCount(2, $response->json('data.data'));
    }

    // =========================================================================
    // Validation
    // =========================================================================

    public function test_search_param_max_length_is_validated(): void
    {
        $this->getJson('/api/v1/stores?search=' . str_repeat('a', 101))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_per_page_must_be_positive_integer(): void
    {
        $this->getJson('/api/v1/stores?per_page=-1')
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Response structure
    // =========================================================================

    public function test_store_response_includes_products_count(): void
    {
        $this->createActiveStore('Store With Count');

        $response = $this->getJson('/api/v1/stores')->assertOk();

        $store = collect($response->json('data.data'))->first();
        $this->assertArrayHasKey('products_count', $store);
    }

    public function test_store_list_response_has_standard_envelope(): void
    {
        $this->getJson('/api/v1/stores')
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data' => ['data', 'pagination']]);
    }
}
