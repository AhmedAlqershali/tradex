<?php

namespace Tests\Feature;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\SubscriptionRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class SubscriptionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_merchant_registration_to_paid_subscription_lifecycle(): void
    {
        Storage::fake('local');

        $registration = $this->postJson('/api/v1/auth/register/merchant', [
            'name'                  => 'Lifecycle Merchant',
            'email'                 => 'lifecycle@example.com',
            'phone'                 => '0509876543',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
            'store_name'            => 'Lifecycle Store',
        ])->assertCreated();

        $merchant = User::where('email', 'lifecycle@example.com')->firstOrFail();
        $merchantToken = $registration->json('data.token');
        $merchantHeaders = $this->headers($merchantToken);

        $trial = Subscription::where('user_id', $merchant->id)->firstOrFail();

        $this->assertSame('trial', $trial->type);
        $this->assertSame('active', $trial->status);
        $this->assertTrue($trial->ends_at->equalTo($trial->starts_at->copy()->addDays(14)));

        $this->getJson('/api/v1/merchant/subscription', $merchantHeaders)
            ->assertOk()
            ->assertJsonPath('data.type', 'trial')
            ->assertJsonPath('data.is_trial', true)
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.is_entitled', true);

        try {
            Carbon::setTestNow($trial->ends_at->copy()->addSecond());

            $this->getJson('/api/v1/merchant/subscription', $merchantHeaders)
                ->assertOk()
                ->assertJsonPath('data.type', 'trial')
                ->assertJsonPath('data.status', 'expired')
                ->assertJsonPath('data.is_trial', true)
                ->assertJsonPath('data.is_entitled', false);

            $paidPlan = Plan::factory()->active()->create([
                'monthly_price' => 29.99,
            ]);

            $renewal = $this->postJson('/api/v1/merchant/subscription-requests', [
                'plan_id'            => $paidPlan->id,
                'billing_cycle'      => 'monthly',
                'full_name'          => 'Lifecycle Merchant',
                'phone'              => '0509876543',
                'payment_method'     => 'bank_transfer',
                'payment_proof_image' => UploadedFile::fake()->image('proof.jpg'),
            ], $merchantHeaders)
                ->assertCreated()
                ->assertJsonPath('data.status', 'pending');

            $requestId = $renewal->json('data.id');
            $this->assertDatabaseHas('subscription_requests', [
                'id' => $requestId,
                'user_id' => $merchant->id,
                'plan_id' => $paidPlan->id,
                'status' => 'pending',
            ]);

            // Sanctum's request guard is cached by the in-process test
            // application. Flush it before switching from the merchant token
            // to the admin token so the next request resolves the new user.
            Auth::forgetGuards();
            $admin = User::factory()->admin()->create(['status' => 'active']);
            $adminToken = $admin->createToken('test')->plainTextToken;

            $approval = $this->putJson(
                "/api/v1/admin/subscription-requests/{$requestId}/approve",
                [],
                $this->headers($adminToken),
            );

            $approval->assertOk()
                ->assertJsonPath('data.status', 'approved');

            $paid = Subscription::where('user_id', $merchant->id)
                ->where('type', 'paid')
                ->latest('starts_at')
                ->firstOrFail();

            $this->assertSame('active', $paid->status);
            $this->assertSame('monthly', $paid->billing_cycle);
            $this->assertTrue($paid->starts_at->equalTo(now()));
            $this->assertTrue($paid->ends_at->equalTo($paid->starts_at->copy()->addMonth()));
            $this->assertDatabaseHas('subscriptions', [
                'id' => $trial->id,
                'status' => 'expired',
            ]);

            Auth::forgetGuards();
            $this->getJson('/api/v1/merchant/subscription', $merchantHeaders)
                ->assertOk()
                ->assertJsonPath('data.type', 'paid')
                ->assertJsonPath('data.billing_cycle', 'monthly')
                ->assertJsonPath('data.status', 'active')
                ->assertJsonPath('data.is_trial', false)
                ->assertJsonPath('data.is_entitled', true);

            $this->assertSame(2, Subscription::where('user_id', $merchant->id)->count());
            $this->assertSame('approved', SubscriptionRequest::findOrFail($requestId)->status);
            $this->assertDatabaseHas('user_notifications', [
                'user_id' => $merchant->id,
                'type'    => 'subscription_approved',
            ]);
        } finally {
            Carbon::setTestNow();
        }
    }

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ];
    }
}