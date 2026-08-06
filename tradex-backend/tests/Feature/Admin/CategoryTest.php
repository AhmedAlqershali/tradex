<?php

namespace Tests\Feature\Admin;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Admin category management API tests.
 */
class CategoryTest extends TestCase
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

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_list_categories_admin(): void
    {
        $this->getJson('/api/v1/admin/categories')
            ->assertStatus(401);
    }

    public function test_client_cannot_manage_categories(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/categories', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_merchant_cannot_manage_categories(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/categories', $this->headers($token))
            ->assertStatus(403);
    }

    // ── List ──────────────────────────────────────────────────────────────────

    public function test_admin_can_list_categories(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        Category::factory()->count(3)->create();

        $this->getJson('/api/v1/admin/categories', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_category_list_supports_search(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        Category::factory()->create(['name' => 'Electronics']);
        Category::factory()->create(['name' => 'Clothing']);

        $response = $this->getJson('/api/v1/admin/categories?search=Elect', $this->headers($token));

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
    }

    public function test_category_list_supports_status_filter(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        Category::factory()->create(['status' => 'active']);
        Category::factory()->create(['status' => 'inactive']);

        $response = $this->getJson('/api/v1/admin/categories?status=active', $this->headers($token));

        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
    }

    // ── Create ────────────────────────────────────────────────────────────────

    public function test_admin_can_create_category(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->postJson('/api/v1/admin/categories', [
            'name'   => 'Electronics',
            'status' => 'active',
        ], $this->headers($token))
            ->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.name', 'Electronics');

        $this->assertDatabaseHas('categories', ['name' => 'Electronics']);
    }

    public function test_category_name_must_be_unique(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        Category::factory()->create(['name' => 'Electronics']);

        $this->postJson('/api/v1/admin/categories', [
            'name' => 'Electronics',
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_category_name_is_required(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->postJson('/api/v1/admin/categories', [], $this->headers($token))
            ->assertStatus(422);
    }

    // ── Show ──────────────────────────────────────────────────────────────────

    public function test_admin_can_view_a_category(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $cat = Category::factory()->create(['name' => 'Books']);

        $this->getJson("/api/v1/admin/categories/{$cat->id}", $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.id', $cat->id)
            ->assertJsonPath('data.name', 'Books');
    }

    public function test_viewing_non_existent_category_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/categories/99999', $this->headers($token))
            ->assertStatus(404);
    }

    // ── Update ────────────────────────────────────────────────────────────────

    public function test_admin_can_update_a_category(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $cat = Category::factory()->create(['name' => 'Old Name']);

        $this->putJson("/api/v1/admin/categories/{$cat->id}", [
            'name' => 'New Name',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.name', 'New Name');
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    public function test_admin_can_delete_a_category(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $cat = Category::factory()->create();

        $this->deleteJson("/api/v1/admin/categories/{$cat->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('categories', ['id' => $cat->id]);
    }

    public function test_admin_cannot_delete_category_with_products(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $cat     = Category::factory()->create();
        $store   = Store::factory()->active()->create();
        Product::factory()->create(['store_id' => $store->id, 'category_id' => $cat->id]);

        $this->deleteJson("/api/v1/admin/categories/{$cat->id}", [], $this->headers($token))
            ->assertStatus(409) // Conflict
            ->assertJson(['success' => false]);
    }
}
