<?php

namespace Tests\Feature\Admin;

use App\Models\Plan;
use App\Models\Store;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Admin subscription request management API tests.
 */
class SubscriptionRequestTest extends TestCase
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

    private function makePendingRequest(?User $merchant = null): SubscriptionRequest
    {
        $merchant ??= User::factory()->merchant()->create();
        Store::factory()->forUser($merchant)->active()->create();
        $plan = Plan::factory()->create();

        return SubscriptionRequest::create([
            'user_id'              => $merchant->id,
            'plan_id'              => $plan->id,
            'billing_cycle'        => 'monthly',
            'full_name'            => $merchant->name,
            'phone'                => '0501234567',
            'payment_method'       => 'bank_transfer',
            'payment_proof_image'  => 'subscriptions/proof.jpg',
            'status'               => 'pending',
        ]);
    }

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_list_subscription_requests(): void
    {
        $this->getJson('/api/v1/admin/subscription-requests')
            ->assertStatus(401);
    }

    public function test_merchant_cannot_list_subscription_requests_as_admin(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/subscription-requests', $this->headers($token))
            ->assertStatus(403);
    }

    public function test_client_cannot_list_subscription_requests_as_admin(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/subscription-requests', $this->headers($token))
            ->assertStatus(403);
    }

    // ── List ──────────────────────────────────────────────────────────────────

    public function test_admin_can_list_subscription_requests(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();
        $this->makePendingRequest();

        $this->getJson('/api/v1/admin/subscription-requests', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['data', 'pagination']]);
    }

    public function test_admin_can_filter_requests_by_status(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $merchant1 = User::factory()->merchant()->create();
        $merchant2 = User::factory()->merchant()->create();

        $req1 = $this->makePendingRequest($merchant1);
        $req2 = $this->makePendingRequest($merchant2);

        // Approve one
        $admin = User::factory()->admin()->create();
        $req1->update(['status' => 'approved', 'reviewed_by' => $admin->id, 'reviewed_at' => now()]);

        $response = $this->getJson('/api/v1/admin/subscription-requests?status=pending', $this->headers($token));
        $response->assertOk();
        $this->assertCount(1, $response->json('data.data'));
    }

    // ── Show ──────────────────────────────────────────────────────────────────

    public function test_admin_can_view_a_subscription_request(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();

        $this->getJson("/api/v1/admin/subscription-requests/{$req->id}", $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.id', $req->id)
            ->assertJsonPath('data.status', 'pending');
    }

    public function test_viewing_non_existent_request_returns_404(): void
    {
        ['token' => $token] = $this->actingAsAdmin();

        $this->getJson('/api/v1/admin/subscription-requests/99999', $this->headers($token))
            ->assertStatus(404);
    }

    // ── Approve ───────────────────────────────────────────────────────────────

    public function test_admin_can_approve_a_pending_request(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();

        $this->putJson("/api/v1/admin/subscription-requests/{$req->id}/approve", [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('subscription_requests', ['id' => $req->id, 'status' => 'approved']);
        $this->assertDatabaseHas('subscriptions', ['user_id' => $req->user_id]);
    }

    public function test_admin_cannot_approve_already_approved_request(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();
        $req->update(['status' => 'approved', 'reviewed_by' => $admin->id, 'reviewed_at' => now()]);

        $this->putJson("/api/v1/admin/subscription-requests/{$req->id}/approve", [], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // ── Reject ────────────────────────────────────────────────────────────────

    public function test_admin_can_reject_a_pending_request(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();

        $this->putJson("/api/v1/admin/subscription-requests/{$req->id}/reject", [
            'rejection_reason' => 'Payment proof is unclear.',
        ], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'rejected');

        $this->assertDatabaseHas('subscription_requests', ['id' => $req->id, 'status' => 'rejected']);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $req->user_id,
            'type'    => 'subscription_rejected',
        ]);
        $this->assertDatabaseMissing('subscriptions', [
            'user_id' => $req->user_id,
        ]);
    }

    public function test_rejection_reason_is_required(): void
    {
        ['token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();

        $this->putJson("/api/v1/admin/subscription-requests/{$req->id}/reject", [], $this->headers($token))
            ->assertStatus(422);
    }

    public function test_admin_cannot_reject_already_reviewed_request(): void
    {
        ['admin' => $admin, 'token' => $token] = $this->actingAsAdmin();
        $req = $this->makePendingRequest();
        $req->update(['status' => 'rejected', 'reviewed_by' => $admin->id, 'reviewed_at' => now(), 'rejection_reason' => 'Bad proof']);

        $this->putJson("/api/v1/admin/subscription-requests/{$req->id}/reject", [
            'rejection_reason' => 'Trying to reject again.',
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }
}
