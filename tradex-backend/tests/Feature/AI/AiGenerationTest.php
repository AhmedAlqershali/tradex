<?php

namespace Tests\Feature\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Models\AiUsage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests for successful AI generation (provider mocked) and request validation.
 */
class AiGenerationTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    private function merchantToken(): string
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);

        return $merchant->createToken('test')->plainTextToken;
    }

    private function adminToken(): string
    {
        return User::factory()->admin()->create()
            ->createToken('test')->plainTextToken;
    }

    /** Mock the AI provider to return a canned response. */
    private function mockProvider(string $fakeResult = 'AI generated content.', int $tokens = 150): void
    {
        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => $fakeResult, 'tokens_used' => $tokens]);
    }

    // =========================================================================
    // Product Description — success
    // =========================================================================

    public function test_merchant_can_generate_product_description(): void
    {
        $token = $this->merchantToken();
        $this->mockProvider('A high-quality wireless headphone with superior sound.', 120);

        $this->postJson('/api/v1/ai/product-description', [
            'context'  => 'Sony WH-1000XM5, noise-cancelling headphones, electronics category',
            'language' => 'English',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_PRODUCT_DESCRIPTION)
            ->assertJsonStructure(['success', 'message', 'data' => [
                'result', 'tokens_used', 'service_type', 'language',
            ]]);
    }

    public function test_product_description_records_usage(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Great product.', 'tokens_used' => 80]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Test product description context',
        ], $this->headers($token))->assertStatus(200);

        $this->assertDatabaseHas('ai_usages', [
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_PRODUCT_DESCRIPTION,
            'tokens_used'  => 80,
        ]);
    }

    // =========================================================================
    // Product Description — validation
    // =========================================================================

    public function test_product_description_requires_context(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/product-description', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['context']]);
    }

    public function test_product_description_context_min_length(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'abc',  // 3 chars, min is 5
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_product_description_context_max_length(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/product-description', [
            'context' => str_repeat('a', 501),
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Marketing Content — success + validation
    // =========================================================================

    public function test_merchant_can_generate_marketing_content(): void
    {
        $token = $this->merchantToken();
        $this->mockProvider("Caption: Summer sale!\nHashtags: #sale #summer\nTagline: Shop now.", 200);

        $this->postJson('/api/v1/ai/marketing-content', [
            'context'  => 'Summer sale on all clothing items, 50% off this weekend',
            'language' => 'English',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_MARKETING_CONTENT);
    }

    public function test_marketing_content_requires_context(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/marketing-content', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['context']]);
    }

    // =========================================================================
    // Customer Reply — success + validation
    // =========================================================================

    public function test_merchant_can_generate_customer_reply(): void
    {
        $token = $this->merchantToken();
        $this->mockProvider('Thank you for reaching out. We will resolve this promptly.', 90);

        $this->postJson('/api/v1/ai/customer-reply', [
            'context'    => 'My order has not arrived after 7 days.',
            'language'   => 'English',
            'store_name' => 'Tech Store',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_CUSTOMER_REPLY);
    }

    public function test_customer_reply_requires_context(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/customer-reply', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['context']]);
    }

    public function test_customer_reply_context_max_1000_chars(): void
    {
        $token = $this->merchantToken();

        $this->postJson('/api/v1/ai/customer-reply', [
            'context' => str_repeat('a', 1001),
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // AI Analytics — success + validation
    // =========================================================================

    public function test_admin_can_generate_ai_analytics(): void
    {
        $token = $this->adminToken();

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => "Key Highlights:\n- Orders up 20%\nRecommendations:\n- Focus on retention.", 'tokens_used' => 400]);

        $this->getJson('/api/v1/ai/analytics?type=overview&period_days=30', $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_ANALYTICS)
            ->assertJsonPath('data.type', 'overview')
            ->assertJsonPath('data.period_days', 30);
    }

    public function test_analytics_rejects_invalid_type(): void
    {
        $token = $this->adminToken();

        $this->getJson('/api/v1/ai/analytics?type=invalid_type', $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_analytics_rejects_period_over_365(): void
    {
        $token = $this->adminToken();

        $this->getJson('/api/v1/ai/analytics?period_days=400', $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Usage endpoint
    // =========================================================================

    public function test_merchant_can_view_ai_usage(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        AiUsage::factory()->create([
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_PRODUCT_DESCRIPTION,
            'tokens_used'  => 100,
        ]);

        $this->getJson('/api/v1/ai/usage', $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => [
                'today', 'this_month', 'daily_limit', 'monthly_limit', 'is_active',
                'credits_used_today', 'credits_used_this_month',
            ]]);
    }

    public function test_admin_can_view_ai_usage(): void
    {
        $token = $this->adminToken();

        $this->getJson('/api/v1/ai/usage', $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    // =========================================================================
    // Provider failure — 503
    // =========================================================================

    public function test_provider_failure_returns_503(): void
    {
        $token = $this->merchantToken();

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andThrow(new \App\Exceptions\AiProviderException('AI provider is unavailable.'));

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Wireless headphones',
        ], $this->headers($token))
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    // =========================================================================
    // Standard response envelope
    // =========================================================================

    public function test_response_has_standard_envelope(): void
    {
        $token = $this->merchantToken();
        $this->mockProvider('Generated text.', 50);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Product context here',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonStructure(['success', 'message', 'data']);
    }
}
