<?php

namespace Tests\Feature\Security;

use App\Models\Plan;
use App\Models\Store;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MerchantSubscriptionAccessTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    private function merchantWithToken(array $attributes = []): array
    {
        $merchant = User::factory()->merchant()->create(array_merge([
            'status' => 'active',
        ], $attributes));
        $token = $merchant->createToken('test')->plainTextToken;

        return compact('merchant', 'token');
    }

    private function businessUrl(): string
    {
        return '/api/v1/merchant/dashboard';
    }

    public function test_active_trial_allows_merchant_business_access(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantWithToken();
        Subscription::factory()->forUser($merchant)->active()->create([
            'type' => 'trial',
        ]);

        $this->getJson($this->businessUrl(), $this->headers($token))
            ->assertOk();
    }

    public function test_active_paid_subscription_allows_merchant_business_access(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantWithToken();
        Subscription::factory()->forUser($merchant)->active()->create([
            'type' => 'paid',
        ]);

        $this->getJson($this->businessUrl(), $this->headers($token))
            ->assertOk();
    }

    public function test_future_dated_subscription_does_not_grant_business_access(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantWithToken();
        Subscription::factory()->forUser($merchant)->active()->create([
            'type'      => 'paid',
            'starts_at' => now()->addMinute(),
            'ends_at'   => now()->addMonth(),
        ]);

        $this->getJson($this->businessUrl(), $this->headers($token))
            ->assertForbidden();
    }

    public function test_expired_trial_denies_merchant_business_access(): void
    {
        $this->assertBusinessAccessDeniedForSubscription(['type' => 'trial', 'status' => 'active']);
    }

    public function test_expired_paid_subscription_denies_merchant_business_access(): void
    {
        $this->assertBusinessAccessDeniedForSubscription(['type' => 'paid', 'status' => 'active']);
    }

    public function test_no_subscription_denies_merchant_business_access(): void
    {
        ['token' => $token] = $this->merchantWithToken();

        $this->getJson($this->businessUrl(), $this->headers($token))
            ->assertForbidden()
            ->assertJsonPath('message', 'An active trial or paid subscription is required to access merchant business features.');
    }

    public function test_expired_merchant_can_still_login_and_view_profile(): void
    {
        $password = 'Password123!';
        ['merchant' => $merchant] = $this->merchantWithToken([
            'email'    => 'expired-login@example.com',
            'password' => Hash::make($password),
        ]);
        $this->expiredSubscription($merchant, 'trial');

        $login = $this->postJson('/api/v1/auth/login', [
            'email'    => $merchant->email,
            'password' => $password,
        ])->assertOk();

        $this->getJson('/api/v1/profile', $this->headers($login->json('data.token')))
            ->assertOk();
    }

    public function test_expired_merchant_can_submit_subscription_request(): void
    {
        Storage::fake('public');
        ['merchant' => $merchant, 'token' => $token] = $this->merchantWithToken();
        $this->expiredSubscription($merchant, 'paid');
        $plan = Plan::factory()->active()->create();

        $this->postJson('/api/v1/merchant/subscription-requests', [
            'plan_id'             => $plan->id,
            'billing_cycle'       => 'monthly',
            'full_name'           => $merchant->name,
            'phone'               => $merchant->phone,
            'payment_method'      => 'bank_transfer',
            'payment_proof_image' => UploadedFile::fake()->image('proof.jpg'),
        ], $this->headers($token))
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending');
    }

    public function test_admin_and_client_behavior_remains_unchanged(): void
    {
        $client = User::factory()->client()->create();
        $admin = User::factory()->admin()->create();

        foreach ([$client, $admin] as $user) {
            $token = $user->createToken('test')->plainTextToken;

            $this->getJson($this->businessUrl(), $this->headers($token))
                ->assertForbidden();
        }

        $this->getJson('/api/v1/client/dashboard', $this->headers(
            $client->createToken('client-test')->plainTextToken
        ))->assertOk();

        Auth::forgetGuards();
        $this->getJson('/api/v1/admin/dashboard', $this->headers(
            $admin->createToken('admin-test')->plainTextToken
        ))->assertOk();
    }

    private function assertBusinessAccessDeniedForSubscription(array $attributes): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantWithToken();
        $this->expiredSubscription($merchant, $attributes['type']);

        $this->getJson($this->businessUrl(), $this->headers($token))
            ->assertForbidden()
            ->assertJsonPath('message', 'An active trial or paid subscription is required to access merchant business features.');
    }

    private function expiredSubscription(User $merchant, string $type): Subscription
    {
        return Subscription::factory()->forUser($merchant)->create([
            'type'    => $type,
            'status'  => 'active',
            'ends_at' => Carbon::now()->subSecond(),
        ]);
    }
}