<?php

namespace Tests\Feature\Admin;

use App\Models\Plan;
use App\Models\User;
use Database\Seeders\PlanSeeder;
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
            'name'          => 'starter',
            'display_name'  => 'Starter Plan',
            'monthly_price' => Plan::AI_MONTHLY_PRICE,
            'yearly_price'  => Plan::AI_YEARLY_PRICE,
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
            ->assertJsonPath('data.display_name', 'Starter Plan');

        $this->assertDatabaseHas('plans', ['name' => 'starter', 'display_name' => 'Starter Plan']);
    }

    public function test_plan_seeder_defines_free_and_ai_without_deleting_premium(): void
    {
        $premium = Plan::factory()->create([
            'name'   => Plan::PREMIUM_PLAN_NAME,
            'status' => 'active',
        ]);

        $this->seed(PlanSeeder::class);

        $this->assertDatabaseHas('plans', [
            'name'          => Plan::FREE_PLAN_NAME,
            'monthly_price' => Plan::FREE_MONTHLY_PRICE,
            'yearly_price'  => Plan::FREE_YEARLY_PRICE,
        ]);
        $this->assertDatabaseHas('plans', [
            'name'          => Plan::AI_PLAN_NAME,
            'monthly_price' => Plan::AI_MONTHLY_PRICE,
            'yearly_price'  => Plan::AI_YEARLY_PRICE,
        ]);
        $this->assertDatabaseHas('plans', [
            'id'     => $premium->id,
            'status' => 'inactive',
        ]);
    }

    public function test_admin_cannot_create_premium_plan(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->postJson('/api/v1/admin/plans', $this->planPayload([
            'name' => Plan::PREMIUM_PLAN_NAME,
        ]), $this->headers($token))
            ->assertStatus(422);
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
        $plan = Plan::factory()->create([
            'monthly_price' => Plan::AI_MONTHLY_PRICE,
            'yearly_price'  => Plan::AI_YEARLY_PRICE,
        ]);

        $response = $this->putJson("/api/v1/admin/plans/{$plan->id}", [
            'monthly_price' => Plan::AI_MONTHLY_PRICE,
        ], $this->headers($token))
            ->assertOk();

        $this->assertSame(Plan::AI_MONTHLY_PRICE, (float) $response->json('data.monthly_price'));
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
