<?php

namespace Tests\Feature\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use App\Models\AiUsage;
use App\Models\User;
use App\Services\AI\GeminiProviderService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Feature tests for GeminiProviderService and its integration with the AI
 * domain services through AiProviderInterface.
 *
 * Strategy:
 *   - All tests that flow through a domain service (ProductDescriptionService,
 *     etc.) mock AiProviderInterface — identical to AiGenerationTest.php — so
 *     the Gemini HTTP call is never made in CI.
 *   - Provider-unit tests use Http::fake() to verify GeminiProviderService
 *     request/response parsing in isolation.
 *
 * No test in this file makes a real network call to Google.
 */
class GeminiProviderTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function merchantHeaders(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token = $merchant->createToken('test')->plainTextToken;
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function adminHeaders(): array
    {
        $token = User::factory()->admin()->create()->createToken('test')->plainTextToken;
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    /** Mock the provider interface to return a canned result (no HTTP). */
    private function mockProvider(string $result = 'Gemini generated content.', int $tokens = 120): void
    {
        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => $result, 'tokens_used' => $tokens]);
    }

    // =========================================================================
    // 1. GeminiProviderService — unit via Http::fake()
    // =========================================================================

    public function test_gemini_provider_throws_when_api_key_is_missing(): void
    {
        config(['services.gemini.key' => '']);

        $provider = new GeminiProviderService();

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/GEMINI_API_KEY/');

        $provider->complete('system prompt', 'user prompt');
    }

    public function test_gemini_provider_parses_successful_response(): void
    {
        config(['services.gemini.key' => 'fake-test-key']);

        Http::fake([
            '*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [['text' => 'A beautiful product description.']],
                        ],
                    ],
                ],
                'usageMetadata' => ['totalTokenCount' => 95],
            ], 200),
        ]);

        $provider = new GeminiProviderService();
        $result   = $provider->complete('You are a copywriter.', 'Write a description.');

        $this->assertEquals('A beautiful product description.', $result['result']);
        $this->assertEquals(95, $result['tokens_used']);
    }

    public function test_gemini_provider_throws_on_401_invalid_key(): void
    {
        config(['services.gemini.key' => 'invalid-key']);

        Http::fake([
            '*' => Http::response([
                'error' => ['message' => 'API key not valid.'],
            ], 401),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/invalid or lacks permission/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_403_forbidden(): void
    {
        config(['services.gemini.key' => 'valid-looking-key']);

        Http::fake([
            '*' => Http::response([
                'error' => ['message' => 'Permission denied.'],
            ], 403),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/invalid or lacks permission/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_429_rate_limit(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => Http::response([
                'error' => ['message' => 'Resource exhausted.'],
            ], 429),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/Gemini provider error/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_503_service_unavailable(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => Http::response([
                'error' => ['message' => 'Service unavailable.'],
            ], 503),
        ]);

        $this->expectException(AiProviderException::class);

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_empty_candidates(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => Http::response([
                'candidates'    => [],
                'usageMetadata' => ['totalTokenCount' => 10],
            ], 200),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/empty response/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_whitespace_only_response(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [['text' => " \n\t "]],
                        ],
                    ],
                ],
            ], 200),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/empty response/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_safety_block(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => Http::response([
                'candidates'     => [],
                'promptFeedback' => ['blockReason' => 'SAFETY'],
                'usageMetadata'  => ['totalTokenCount' => 10],
            ], 200),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/safety filters/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    public function test_gemini_provider_throws_on_network_timeout(): void
    {
        config(['services.gemini.key' => 'fake-key']);

        Http::fake([
            '*' => fn () => throw new \Illuminate\Http\Client\ConnectionException('cURL error 28: timed out'),
        ]);

        $this->expectException(AiProviderException::class);
        $this->expectExceptionMessageMatches('/currently unavailable/i');

        (new GeminiProviderService())->complete('sys', 'user');
    }

    // =========================================================================
    // 2. Integration: domain services flow through AiProviderInterface (mocked)
    // =========================================================================

    public function test_product_description_uses_gemini_result(): void
    {
        $this->mockProvider('Wireless headphones with 30-hour battery and deep bass.', 110);

        $this->postJson('/api/v1/ai/product-description', [
            'context'  => 'Sony WH-XB910N, Extra-Bass headphones, electronics',
            'language' => 'English',
        ], $this->merchantHeaders())
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.result', 'Wireless headphones with 30-hour battery and deep bass.')
            ->assertJsonPath('data.tokens_used', 110)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_PRODUCT_DESCRIPTION);
    }

    public function test_marketing_content_uses_gemini_result(): void
    {
        $this->mockProvider("Caption: Grab the deal!\nHashtags: #sale #deals\nTagline: Don't miss out.", 95);

        $this->postJson('/api/v1/ai/marketing-content', [
            'context'  => 'Flash sale, 40% off all electronics',
            'language' => 'English',
        ], $this->merchantHeaders())
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_MARKETING_CONTENT)
            ->assertJsonPath('data.tokens_used', 95);
    }

    public function test_customer_reply_uses_gemini_result(): void
    {
        $this->mockProvider('We sincerely apologise for the delay. Your order ships today.', 75);

        $this->postJson('/api/v1/ai/customer-reply', [
            'context'    => 'My order is late, I am very unhappy.',
            'language'   => 'English',
            'store_name' => 'TradexShop',
        ], $this->merchantHeaders())
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_CUSTOMER_REPLY)
            ->assertJsonPath('data.tokens_used', 75);
    }

    public function test_analytics_uses_gemini_result(): void
    {
        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn([
                'result'      => "Key Highlights:\n- Revenue up 15%\nRecommendations:\n- Expand to new regions.",
                'tokens_used' => 380,
            ]);

        $this->getJson('/api/v1/ai/analytics?type=overview&period_days=30', $this->adminHeaders())
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.service_type', AiUsage::TYPE_ANALYTICS)
            ->assertJsonPath('data.tokens_used', 380);
    }

    // =========================================================================
    // 3. SaaS controls work with Gemini provider
    // =========================================================================

    public function test_credits_are_recorded_after_gemini_generation(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andReturn(['result' => 'Great description.', 'tokens_used' => 88]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Test product for credit tracking',
        ], ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'])
            ->assertStatus(200);

        $this->assertDatabaseHas('ai_usages', [
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_PRODUCT_DESCRIPTION,
            'tokens_used'  => 88,
        ]);

        $this->assertDatabaseHas('ai_requests', [
            'user_id'      => $merchant->id,
            'service_type' => AiUsage::TYPE_PRODUCT_DESCRIPTION,
            'tokens_used'  => 88,
            'status'       => 'completed',
        ]);
    }

    public function test_gemini_provider_failure_returns_503_and_does_not_record_usage(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->andThrow(new AiProviderException('Gemini provider is currently unavailable.'));

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Test product context',
        ], ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'])
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);

        // Usage must NOT be charged when the provider fails.
        $this->assertDatabaseMissing('ai_usages', ['user_id' => $merchant->id]);
    }

    public function test_gemini_provider_sends_correct_generationconfig_via_http_fake(): void
    {
        config(['services.gemini.key' => 'test-key-for-payload']);

        Http::fake([
            '*' => Http::response([
                'candidates'    => [
                    ['content' => ['parts' => [['text' => 'Generated text.']]]],
                ],
                'usageMetadata' => ['totalTokenCount' => 50],
            ], 200),
        ]);

        $provider = new GeminiProviderService();
        $result   = $provider->complete(
            'System instruction.',
            'User prompt.',
            ['max_tokens' => 300, 'temperature' => 0.75]
        );

        $this->assertEquals('Generated text.', $result['result']);

        // Verify the correct generationConfig was sent in the request body.
        Http::assertSent(function ($request) {
            $body = $request->data();
            return isset($body['generationConfig'])
                && $body['generationConfig']['maxOutputTokens'] === 300
                && $body['generationConfig']['temperature']     === 0.75
                && isset($body['systemInstruction']['parts'][0]['text'])
                && isset($body['contents'][0]['role'])
                && $body['contents'][0]['role'] === 'user';
        });
    }

    // =========================================================================
    // 4. AI is disabled (rate-limit) still returns 429 with Gemini bound
    // =========================================================================

    public function test_rate_limit_still_returns_429_with_gemini_provider(): void
    {
        $merchant  = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token     = $merchant->createToken('test')->plainTextToken;
        $headers   = ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];

        // Create an ai_settings record that has AI disabled.
        \App\Models\AiSetting::factory()->create([
            'user_id'   => $merchant->id,
            'is_active' => false,
        ]);

        // Provider should never be called — the limit check fires first.
        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->never();

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Product that should be blocked',
        ], $headers)
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }
}
