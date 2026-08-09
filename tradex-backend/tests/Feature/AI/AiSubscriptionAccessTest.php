<?php

namespace Tests\Feature\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Models\AiSetting;
use App\Models\AiUsage;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Phase 3: merchant AI generation follows the canonical subscription gate.
 *
 * These tests intentionally exercise the HTTP routes so an entitlement check
 * cannot be accidentally moved below AI quota consumption or provider calls.
 */
class AiSubscriptionAccessTest extends TestCase
{
    use RefreshDatabase;

    private const ENTITLEMENT_MESSAGE =
        'An active trial or paid subscription is required to access merchant business features.';

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    private function merchantToken(string $type = 'paid', bool $expired = false): array
    {
        $merchant = User::factory()->merchant()->create();
        $plan = Plan::factory()->active()->create(['ai_usage_limit' => null]);

        Subscription::factory()->forUser($merchant)->forPlan($plan)->create([
            'type'    => $type,
            'status'  => 'active',
            'ends_at' => $expired ? now()->subDay() : now()->addDays(14),
        ]);

        return [
            'merchant' => $merchant,
            'token'    => $merchant->createToken('test')->plainTextToken,
        ];
    }

    private function generationRequests(): array
    {
        return [
            [
                'method'  => 'postJson',
                'uri'     => '/api/v1/ai/product-description',
                'payload' => ['context' => 'A useful marketplace product'],
            ],
            [
                'method'  => 'postJson',
                'uri'     => '/api/v1/ai/marketing-content',
                'payload' => ['context' => 'A campaign for a marketplace product'],
            ],
            [
                'method'  => 'postJson',
                'uri'     => '/api/v1/ai/customer-reply',
                'payload' => ['context' => 'The customer needs a helpful response'],
            ],
        ];
    }

    private function assertGenerationAllowed(string $token): void
    {
        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Generated content.', 'tokens_used' => 12]);

        $request = $this->generationRequests()[0];

        $this->{$request['method']}(
            $request['uri'],
            $request['payload'],
            $this->headers($token),
        )->assertOk()
            ->assertJsonPath('success', true);
    }

    private function assertGenerationDenied(string $token): void
    {
        foreach ($this->generationRequests() as $request) {
            $this->{$request['method']}(
                $request['uri'],
                $request['payload'],
                $this->headers($token),
            )->assertForbidden()
                ->assertJsonPath('success', false)
                ->assertJsonPath('message', self::ENTITLEMENT_MESSAGE)
                ->assertJsonPath('data', null);
        }
    }

    public function test_active_trial_allows_ai_generation(): void
    {
        ['token' => $token] = $this->merchantToken('trial');

        $this->assertGenerationAllowed($token);
    }

    public function test_active_paid_subscription_allows_ai_generation(): void
    {
        ['token' => $token] = $this->merchantToken('paid');

        $this->assertGenerationAllowed($token);
    }

    public function test_expired_subscription_cannot_supply_an_ai_plan_limit(): void
    {
        $merchant = User::factory()->merchant()->create();
        $plan = Plan::factory()->active()->create(['ai_usage_limit' => 1]);
        Subscription::factory()->forUser($merchant)->forPlan($plan)->create([
            'type'      => 'paid',
            'status'    => 'active',
            'starts_at' => now()->subMonth(),
            'ends_at'   => now()->subDay(),
        ]);
        $token = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->never();

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Expired plan must not provide AI access.',
        ], $this->headers($token))
            ->assertForbidden()
            ->assertJsonPath('success', false);
    }

    public function test_expired_trial_denies_every_merchant_ai_generation_endpoint(): void
    {
        ['token' => $token] = $this->merchantToken('trial', true);

        $this->assertGenerationDenied($token);
    }

    public function test_expired_paid_subscription_denies_every_merchant_ai_generation_endpoint(): void
    {
        ['token' => $token] = $this->merchantToken('paid', true);

        $this->assertGenerationDenied($token);
    }

    public function test_merchant_without_a_subscription_is_denied_every_merchant_ai_generation_endpoint(): void
    {
        $merchant = User::factory()->merchant()->create();

        $this->assertGenerationDenied(
            $merchant->createToken('test')->plainTextToken,
        );
    }

    public function test_subscription_gate_runs_before_usage_is_consumed(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantToken('paid', true);

        AiUsage::factory()->create(['user_id' => $merchant->id]);
        $this->assertDatabaseCount('ai_usages', 1);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'This request must be denied before the provider.',
        ], $this->headers($token))
            ->assertForbidden();

        $this->assertDatabaseCount('ai_usages', 1);
    }

    public function test_active_subscription_with_quota_available_allows_ai(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantToken();

        AiSetting::create([
            'user_id'     => $merchant->id,
            'daily_limit' => 2,
            'is_active'   => true,
        ]);

        $this->assertGenerationAllowed($token);
        $this->assertDatabaseHas('ai_usages', ['user_id' => $merchant->id]);
    }

    public function test_active_subscription_with_exhausted_quota_preserves_existing_429_response(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantToken();

        AiSetting::create([
            'user_id'     => $merchant->id,
            'daily_limit' => 1,
            'is_active'   => true,
        ]);
        AiUsage::factory()->create(['user_id' => $merchant->id]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'This request should be blocked by quota.',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    public function test_ai_kill_switch_still_denies_an_entitled_merchant(): void
    {
        ['merchant' => $merchant, 'token' => $token] = $this->merchantToken();

        AiSetting::create([
            'user_id'   => $merchant->id,
            'is_active' => false,
        ]);

        $this->postJson('/api/v1/ai/customer-reply', [
            'context' => 'The AI account setting is disabled.',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    public function test_admin_ai_analytics_remains_available_without_a_merchant_subscription(): void
    {
        $admin = User::factory()->admin()->create();

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Platform insights.', 'tokens_used' => 20]);

        $this->getJson('/api/v1/ai/analytics', $this->headers(
            $admin->createToken('test')->plainTextToken,
        ))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_ANALYTICS);
    }

    public function test_client_remains_blocked_from_merchant_ai_generation(): void
    {
        $client = User::factory()->client()->create();

        foreach ($this->generationRequests() as $request) {
            $this->{$request['method']}(
                $request['uri'],
                $request['payload'],
                $this->headers($client->createToken('test')->plainTextToken),
            )->assertForbidden()
                ->assertJsonPath('success', false);
        }
    }
}