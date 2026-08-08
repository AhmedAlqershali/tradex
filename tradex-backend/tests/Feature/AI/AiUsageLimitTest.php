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
 * Verify that AiUsageService correctly blocks requests when limits are hit.
 */
class AiUsageLimitTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    // =========================================================================
    // Daily limit
    // =========================================================================

    public function test_merchant_blocked_when_daily_limit_reached(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        // Set a daily limit of 2
        AiSetting::create([
            'user_id'     => $merchant->id,
            'daily_limit' => 2,
            'is_active'   => true,
        ]);

        // Simulate 2 requests already made today
        AiUsage::factory()->count(2)->create([
            'user_id'       => $merchant->id,
            'service_type'  => AiUsage::TYPE_PRODUCT_DESCRIPTION,
            'request_count' => 1,
        ]);

        // No provider mock — should be blocked before hitting the provider
        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Test product context',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Monthly limit
    // =========================================================================

    public function test_merchant_blocked_when_monthly_limit_reached(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        AiSetting::create([
            'user_id'       => $merchant->id,
            'monthly_limit' => 5,
            'is_active'     => true,
        ]);

        // Simulate 5 requests this month
        AiUsage::factory()->count(5)->create([
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_MARKETING_CONTENT,
        ]);

        $this->postJson('/api/v1/ai/marketing-content', [
            'context' => 'Test campaign context',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // AI disabled
    // =========================================================================

    public function test_merchant_blocked_when_ai_disabled(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        AiSetting::create([
            'user_id'   => $merchant->id,
            'is_active' => false,
        ]);

        $this->postJson('/api/v1/ai/customer-reply', [
            'context' => 'My order was late.',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // No limit → succeeds (null = unlimited)
    // =========================================================================

    public function test_merchant_without_settings_has_no_limit(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        // No AiSetting record = unlimited

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Generated.', 'tokens_used' => 60]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Product with no usage limits',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // =========================================================================
    // Daily limit not yet reached → succeeds
    // =========================================================================

    public function test_merchant_within_daily_limit_can_generate(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        AiSetting::create([
            'user_id'     => $merchant->id,
            'daily_limit' => 10,
            'is_active'   => true,
        ]);

        // Only 3 used so far
        AiUsage::factory()->count(3)->create([
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_PRODUCT_DESCRIPTION,
        ]);

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Within limit.', 'tokens_used' => 50]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Within daily limit context',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // =========================================================================
    // Usage is recorded on success
    // =========================================================================

    public function test_usage_count_increments_after_generation(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Content.', 'tokens_used' => 75]);

        $this->assertDatabaseCount('ai_usages', 0);

        $this->postJson('/api/v1/ai/marketing-content', [
            'context' => 'Campaign for new product launch',
        ], $this->headers($token))->assertStatus(200);

        $this->assertDatabaseCount('ai_usages', 1);
        $this->assertDatabaseHas('ai_usages', [
            'user_id'       => $merchant->id,
            'service_type'  => AiUsage::TYPE_MARKETING_CONTENT,
            'tokens_used'   => 75,
            'request_count' => 1,
            'credits_used'  => 1,
        ]);
        $this->assertDatabaseHas('ai_requests', [
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_MARKETING_CONTENT,
            'status'       => 'completed',
            'credits_used' => 1,
        ]);
    }

    public function test_active_subscription_plan_provides_monthly_credit_limit(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $plan = Plan::factory()->create(['ai_usage_limit' => 2]);
        Subscription::factory()->forUser($merchant)->forPlan($plan)->active()->create();

        AiUsage::factory()->count(2)->create(['user_id' => $merchant->id]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Subscription-limited product',
        ], $this->headers($token))
            ->assertStatus(429)
            ->assertJsonPath('success', false);

        $this->getJson('/api/v1/ai/usage', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.monthly_limit', 2)
            ->assertJsonPath('data.credits_used_this_month', 2);
    }
}
