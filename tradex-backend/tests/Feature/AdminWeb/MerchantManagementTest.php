<?php

namespace Tests\Feature\AdminWeb;

use App\Models\Plan;
use App\Models\Store;
use App\Models\Subscription;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class MerchantManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_users_are_redirected_to_admin_login(): void
    {
        $this->get('/admin/merchants')
            ->assertRedirect(route('admin.login'));
    }

    public function test_clients_and_merchants_are_forbidden_from_merchant_pages(): void
    {
        $merchant = User::factory()->merchant()->create();

        foreach ([User::factory()->client()->create(), User::factory()->merchant()->create()] as $user) {
            $this->actingAs($user, 'web')
                ->get('/admin/merchants')
                ->assertForbidden();

            $this->actingAs($user, 'web')
                ->get("/admin/merchants/{$merchant->id}")
                ->assertForbidden();
        }
    }

    public function test_admin_can_list_real_merchants_with_store_and_subscription_state(): void
    {
        $this->actingAs(User::factory()->admin()->create(), 'web');

        $trialMerchant = User::factory()->merchant()->create([
            'name' => 'Trial Merchant',
            'email' => 'trial@example.com',
        ]);
        Store::factory()->forUser($trialMerchant)->create(['store_name' => 'Trial Store']);
        $trialPlan = Plan::factory()->create(['display_name' => 'Free Trial']);
        Subscription::factory()->forUser($trialMerchant)->forPlan($trialPlan)->create([
            'type' => 'trial',
            'status' => 'active',
            'starts_at' => now()->subDay(),
            'ends_at' => now()->addDays(13),
        ]);

        $expiredMerchant = User::factory()->merchant()->create(['name' => 'Expired Merchant']);
        Subscription::factory()->forUser($expiredMerchant)->forPlan(Plan::factory()->create())->create([
            'type' => 'trial',
            'status' => 'expired',
            'starts_at' => now()->subDays(30),
            'ends_at' => now()->subDays(16),
        ]);

        $this->get('/admin/merchants?search=Trial')
            ->assertOk()
            ->assertSee('Trial Merchant')
            ->assertSee('trial@example.com')
            ->assertSee('Trial Store')
            ->assertSee('Active trial')
            ->assertSee('Free Trial')
            ->assertDontSee('Expired Merchant');
    }

    public function test_admin_can_view_merchant_details_and_subscription_history(): void
    {
        $this->actingAs(User::factory()->admin()->create(), 'web');
        $merchant = User::factory()->merchant()->create(['name' => 'Detailed Merchant']);
        $store = Store::factory()->forUser($merchant)->create([
            'store_name' => 'Detailed Store',
            'region' => 'Riyadh',
        ]);
        $expiredPlan = Plan::factory()->create(['display_name' => 'Expired Trial']);
        $paidPlan = Plan::factory()->create(['display_name' => 'Growth Annual']);

        Subscription::factory()->forUser($merchant)->forPlan($expiredPlan)->create([
            'type' => 'trial',
            'status' => 'expired',
            'starts_at' => now()->subDays(30),
            'ends_at' => now()->subDays(16),
        ]);
        $paid = Subscription::factory()->forUser($merchant)->forPlan($paidPlan)->create([
            'type' => 'paid',
            'status' => 'active',
            'billing_cycle' => 'yearly',
            'starts_at' => now()->subDay(),
            'ends_at' => now()->addYear(),
        ]);

        $this->get("/admin/merchants/{$merchant->id}")
            ->assertOk()
            ->assertSee('Detailed Merchant')
            ->assertSee($merchant->email)
            ->assertSee('Detailed Store')
            ->assertSee('Riyadh')
            ->assertSee('Active paid subscription')
            ->assertSee('Growth Annual')
            ->assertSee('Subscription history')
            ->assertSee('Expired Trial')
            ->assertSee($paid->ends_at->format('M j, Y'));
    }

    public function test_admin_can_approve_external_payment_request_and_activate_correct_yearly_period(): void
    {
        $admin = User::factory()->admin()->create();
        $merchant = User::factory()->merchant()->create();
        $plan = Plan::factory()->create(['display_name' => 'Annual Pro']);
        $request = SubscriptionRequest::factory()
            ->forUser($merchant)
            ->forPlan($plan)
            ->create(['billing_cycle' => 'yearly', 'status' => 'pending']);

        $before = now();
        $this->actingAs($admin, 'web')
            ->post("/admin/merchants/{$merchant->id}/subscription-requests/{$request->id}/approve")
            ->assertRedirect(route('admin.merchants.show', $merchant))
            ->assertSessionHas('status');

        $subscription = Subscription::query()->where('user_id', $merchant->id)->latest('id')->firstOrFail();

        $this->assertDatabaseHas('subscription_requests', [
            'id' => $request->id,
            'status' => 'approved',
            'reviewed_by' => $admin->id,
        ]);
        $this->assertSame('paid', $subscription->type);
        $this->assertSame('active', $subscription->status);
        $this->assertSame('yearly', $subscription->billing_cycle);
        $this->assertTrue($subscription->starts_at->greaterThanOrEqualTo($before->subSecond()));
        $this->assertTrue($subscription->ends_at->between(
            Carbon::now()->addMonths(11)->subDays(5),
            Carbon::now()->addMonths(13),
        ));
    }

    public function test_approval_refreshes_real_state_and_rejects_invalid_actions(): void
    {
        $admin = User::factory()->admin()->create();
        $merchant = User::factory()->merchant()->create();
        $otherMerchant = User::factory()->merchant()->create();
        $request = SubscriptionRequest::factory()->forUser($otherMerchant)->create();

        $this->actingAs($admin, 'web')
            ->get('/admin/merchants/999999')
            ->assertNotFound();

        $this->post("/admin/merchants/{$merchant->id}/subscription-requests/{$request->id}/approve")
            ->assertNotFound();

        $ownRequest = SubscriptionRequest::factory()->forUser($merchant)->create();
        $this->post("/admin/merchants/{$merchant->id}/subscription-requests/{$ownRequest->id}/reject")
            ->assertSessionHasErrors('rejection_reason');
        $this->assertDatabaseHas('subscription_requests', [
            'id' => $ownRequest->id,
            'status' => 'pending',
        ]);

        $reviewedRequest = SubscriptionRequest::factory()
            ->forUser($merchant)
            ->approved($admin)
            ->create();

        $this->post("/admin/merchants/{$merchant->id}/subscription-requests/{$reviewedRequest->id}/approve")
            ->assertRedirect()
            ->assertSessionHasErrors('subscription');
    }
}