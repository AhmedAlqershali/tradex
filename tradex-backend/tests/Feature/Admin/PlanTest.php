<?php

namespace Tests\Feature\Admin;

use App\Models\Plan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Admin plan management API tests.
 */
class PlanTest extends TestCase
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

    private function planPayload(array $overrides = []): array
    {
        return array_merge([
            'name'          => 'pro',
            'display_name'  => 'Pro Plan',
            'monthly_price' => 49.99,
            'yearly_price'  => 499.99,
            'product_limit' => 100,
            'store_limit'   => 3,
            'ai_usage_limit'=> 500,
            'status'        => 'active',
        ], $overrides);
    }

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_list_plans_admin(): void
    {
        $this->getJson('/api/v1/admin/plans')->assertStatus(401);
    }

    public function test_client_cannot_manage_plans(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/plans', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_merchant_cannot_manage_plans(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/plans', $this->headers($token))
            ->assertStatus(403);
    }

    // ── List ──────────────────────────────────────────────────────────────────

    public function test_admin_can_list_plans(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        Plan::factory()->count(2)->create();

        $this->getJson('/api/v1/admin/plans', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    // ── Create ────────────────────────────────────────────────────────────────

    public function test_admin_can_create_a_plan(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->postJson('/api/v1/admin/plans', $this->planPayload(), $this->headers($token))
            ->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.display_name', 'Pro Plan');

        $this->assertDatabaseHas('plans', ['name' => 'pro', 'display_name' => 'Pro Plan']);
    }

    public function test_plan_requires_name_and_monthly_price(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->postJson('/api/v1/admin/plans', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // ── Show ──────────────────────────────────────────────────────────────────

    public function test_admin_can_view_a_plan(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $plan = Plan::factory()->create(['display_name' => 'Starter']);

        $this->getJson("/api/v1/admin/plans/{$plan->id}", $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.display_name', 'Starter');
    }

    public function test_viewing_non_existent_plan_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/plans/99999', $this->headers($token))
            ->assertStatus(404);
    }

    // ── Update ────────────────────────────────────────────────────────────────

    public function test_admin_can_update_a_plan(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $plan = Plan::factory()->create(['monthly_price' => 9.99]);

        $this->putJson("/api/v1/admin/plans/{$plan->id}", [
            'monthly_price' => 19.99,
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.monthly_price', 19.99);
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    public function test_admin_can_delete_a_plan(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $plan = Plan::factory()->create();

        $this->deleteJson("/api/v1/admin/plans/{$plan->id}", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('plans', ['id' => $plan->id]);
    }
}
