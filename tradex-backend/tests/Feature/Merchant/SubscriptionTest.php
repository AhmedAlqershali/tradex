<?php

namespace Tests\Feature\Merchant;

use App\Models\Plan;
use App\Models\Store;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Tests for merchant subscription endpoints:
 *   GET  /merchant/subscription
 *   GET  /merchant/subscription-requests
 *   GET  /merchant/subscription-requests/{id}
 *   POST /merchant/subscription-requests
 */
class SubscriptionTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsMerchant(): array
    {
        $user  = User::factory()->merchant()->create(['status' => 'active']);
        Store::factory()->forUser($user)->create();
        $token = $user->createToken('test')->plainTextToken;

        return compact('user', 'token');
    }

    private function actingAsClient(): array
    {
        $user  = User::factory()->client()->create(['status' => 'active']);
        $token = $user->createToken('test')->plainTextToken;

        return compact('user', 'token');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── GET /merchant/subscription ─────────────────────────────────────────────

    public function test_unauthenticated_cannot_get_subscription(): void
    {
        $this->getJson('/api/v1/merchant/subscription')->assertUnauthorized();
    }

    public function test_client_cannot_access_merchant_subscription(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->getJson('/api/v1/merchant/subscription', $this->headers($token))
            ->assertForbidden();
    }

    public function test_merchant_with_no_subscription_gets_null(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->getJson('/api/v1/merchant/subscription', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true, 'data' => null]);
    }

    public function test_merchant_can_view_active_subscription(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsMerchant();
        $plan = Plan::factory()->active()->create();

        \App\Models\Subscription::factory()->forUser($user)->forPlan($plan)->active()->create();

        $this->getJson('/api/v1/merchant/subscription', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'active');
    }

    // ── GET /merchant/subscription-requests ───────────────────────────────────

    public function test_merchant_can_list_active_subscription_plans(): void
    {
        ['token' => $token] = $this->actingAsMerchant();
        Plan::factory()->active()->create([
            'display_name' => 'Pro Plan',
            'monthly_price' => 19.99,
        ]);
        Plan::factory()->create([
            'display_name' => 'Retired Plan',
            'status' => 'inactive',
        ]);

        $response = $this->getJson('/api/v1/merchant/plans', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Pro Plan', $response->json('data.0.display_name'));
    }

    public function test_client_cannot_list_merchant_subscription_plans(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->getJson('/api/v1/merchant/plans', $this->headers($token))
            ->assertForbidden();
    }

    public function test_merchant_can_list_own_subscription_requests(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsMerchant();
        $plan = Plan::factory()->active()->create();

        SubscriptionRequest::factory()->forUser($user)->forPlan($plan)->count(2)->create();

        $this->getJson('/api/v1/merchant/subscription-requests', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_merchant_only_sees_own_requests(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsMerchant();
        $other = User::factory()->merchant()->create();
        $plan  = Plan::factory()->active()->create();

        SubscriptionRequest::factory()->forUser($user)->forPlan($plan)->create();
        SubscriptionRequest::factory()->forUser($other)->forPlan($plan)->create();

        $response = $this->getJson('/api/v1/merchant/subscription-requests', $this->headers($token))
            ->assertOk();

        $this->assertCount(1, $response->json('data'));
    }

    // ── GET /merchant/subscription-requests/{id} ──────────────────────────────

    public function test_merchant_can_view_own_request(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsMerchant();
        $plan = Plan::factory()->active()->create();
        $req  = SubscriptionRequest::factory()->forUser($user)->forPlan($plan)->create();

        $this->getJson("/api/v1/merchant/subscription-requests/{$req->id}", $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.id', $req->id);
    }

    public function test_merchant_cannot_view_another_merchants_request(): void
    {
        ['token' => $token] = $this->actingAsMerchant();
        $other = User::factory()->merchant()->create();
        $plan  = Plan::factory()->active()->create();
        $req   = SubscriptionRequest::factory()->forUser($other)->forPlan($plan)->create();

        $this->getJson("/api/v1/merchant/subscription-requests/{$req->id}", $this->headers($token))
            ->assertNotFound();
    }

    // ── POST /merchant/subscription-requests ──────────────────────────────────

    public function test_merchant_can_submit_subscription_request(): void
    {
        Storage::fake('public');
        ['token' => $token] = $this->actingAsMerchant();
        $plan = Plan::factory()->active()->create();

        $response = $this->postJson('/api/v1/merchant/subscription-requests', [
            'plan_id'            => $plan->id,
            'billing_cycle'      => 'monthly',
            'full_name'          => 'Ahmed Ali',
            'phone'              => '0501234567',
            'payment_method'     => 'bank_transfer',
            'payment_proof_image' => UploadedFile::fake()->image('proof.jpg'),
        ], $this->headers($token));

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'pending');
    }

    public function test_submission_requires_plan_and_payment_proof(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->postJson('/api/v1/merchant/subscription-requests', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_merchant_cannot_submit_while_pending_request_exists(): void
    {
        Storage::fake('public');
        ['user' => $user, 'token' => $token] = $this->actingAsMerchant();
        $plan = Plan::factory()->active()->create();

        // Create an existing pending request
        SubscriptionRequest::factory()->forUser($user)->forPlan($plan)->pending()->create();

        $this->postJson('/api/v1/merchant/subscription-requests', [
            'plan_id'            => $plan->id,
            'billing_cycle'      => 'monthly',
            'full_name'          => 'Ahmed Ali',
            'phone'              => '0501234567',
            'payment_method'     => 'bank_transfer',
            'payment_proof_image' => UploadedFile::fake()->image('proof.jpg'),
        ], $this->headers($token))
            ->assertStatus(422);
    }
}
