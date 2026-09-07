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
        $this->mockProvider("A high-quality wireless headphone with superior sound and a comfortable listening experience for everyday use.\n\nIts practical design supports convenient use at home, work, or while travelling, helping customers enjoy their audio content with ease.\n\nA suitable choice for listeners looking for a dependable addition to their daily routine.", 120);

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

    public function test_product_description_prompt_requests_only_final_text_in_requested_language(): void
    {
        $token = $this->merchantToken();
        $description = "هاتف ذكي حديث بتصميم عملي وتجربة استخدام مناسبة للاحتياجات اليومية.\n\nيوفر قيمة واضحة للمستخدم الذي يبحث عن جهاز يساعده في روتينه، مع الحفاظ على وصف عام دون افتراض مواصفات غير مذكورة.";

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')->once()
            ->withArgs(function (string $systemPrompt, string $userPrompt, array $options): bool {
                return str_contains($systemPrompt, 'professional e-commerce copywriter')
                    && str_contains($systemPrompt, 'Do not invent or')
                    && str_contains($systemPrompt, 'assume specifications')
                    && str_contains($userPrompt, 'Requested language: Arabic')
                    && str_contains($userPrompt, 'كرسي مكتب مريح')
                    && $options === [
                        'max_tokens' => 1200,
                        'temperature' => 0.75,
                        'diagnostics' => true,
                    ];
            })
            ->andReturn(['result' => $description, 'tokens_used' => 80]);

        $this->postJson('/api/v1/ai/product-description', [
            'context'  => 'كرسي مكتب مريح',
            'language' => 'Arabic',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.result', $description);
    }

    public function test_short_iphone_idea_returns_a_natural_arabic_description(): void
    {
        $token = $this->merchantToken();
        $description = "جوال ايفون حديث بتصميم أنيق وتجربة استخدام عملية تناسب تفاصيل الحياة اليومية.\n\nيجمع وصفه بين الحضور العصري والقيمة العملية، ويساعد المستخدم على تصور استخدامه في التواصل والمهام المعتادة دون افتراض مواصفات أو مزايا تقنية غير مذكورة.";

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')->once()
            ->withArgs(fn (string $systemPrompt, string $userPrompt): bool =>
                str_contains($userPrompt, 'جوال ايفون حديث')
                && str_contains($userPrompt, 'Requested language: Arabic'))
            ->andReturn(['result' => $description, 'tokens_used' => 90]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'جوال ايفون حديث',
            'language' => 'Arabic',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.language', 'Arabic')
            ->assertJsonPath('data.result', $description);
    }

    public function test_short_generic_idea_returns_a_detailed_description_without_product_specific_logic(): void
    {
        $token = $this->merchantToken();
        $description = "ساعة ذكية بتصميم عملي يساعد على إضافة قيمة واضحة إلى الروتين اليومي.\n\nتقدم تجربة استخدام عامة تناسب من يبحث عن وسيلة مريحة لمتابعة احتياجاته اليومية، مع الحفاظ على وصف واقعي لا يفترض خصائص أو أرقاماً غير معروفة.";

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')->once()
            ->withArgs(fn (string $systemPrompt, string $userPrompt): bool =>
                str_contains($userPrompt, 'ساعة ذكية')
                && !str_contains($systemPrompt, 'ساعة ذكية'))
            ->andReturn(['result' => $description, 'tokens_used' => 85]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'ساعة ذكية',
            'language' => 'Arabic',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.language', 'Arabic')
            ->assertJsonPath('data.result', $description);
    }

    public function test_detailed_product_input_returns_english_description(): void
    {
        $token = $this->merchantToken();
        $description = "A compact desk lamp with an adjustable neck and warm light for focused evening work.\n\nIts flexible shape makes it practical for a home office or reading corner, while the warm lighting supports a comfortable atmosphere.\n\nA useful choice for customers who want simple, focused lighting in their daily workspace.";

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')->once()
            ->withArgs(fn (string $systemPrompt, string $userPrompt): bool =>
                str_contains($userPrompt, 'Compact desk lamp')
                && str_contains($userPrompt, 'Requested language: English'))
            ->andReturn(['result' => $description, 'tokens_used' => 110]);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Compact desk lamp with adjustable neck and warm light for evening work',
            'language' => 'English',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.result', $description);
    }

    public function test_product_description_records_usage(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token    = $merchant->createToken('test')->plainTextToken;

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
                ->andReturn(['result' => "Great product with a practical everyday purpose and a comfortable user experience.\n\nIt provides useful general value for customers who want a simple addition to their routine without unsupported claims.\n\nA clear and professional choice for ordinary daily needs.", 'tokens_used' => 80]);

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

    public function test_short_product_description_context_is_valid(): void
    {
        $token = $this->merchantToken();

        $this->mockProvider("وصف كامل لمنتج جوال مناسب للاستخدام اليومي وتجربة عملية مرنة.\n\nيساعد المستخدم على إنجاز احتياجاته العامة بسهولة ضمن روتين يومي منظم، مع قيمة واضحة دون افتراض مواصفات غير مذكورة.\n\nخيار مناسب لمن يبحث عن استخدام مريح وبسيط.", 40);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'abc',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
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
        $this->mockProvider("Discover practical value and a polished shopping experience with our electronics collection.\n\nChoose a product that fits your daily needs and enjoy a confident, professional purchase experience.", 200);

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

    public function test_short_marketing_idea_returns_substantial_copy_in_one_request(): void
    {
        $token = $this->merchantToken();
        $marketingCopy = "هاتف آيفون بحضور أنيق وتجربة مناسبة للحياة اليومية.\n\nيجمع هذا المنتج بين القيمة العملية والانطباع العصري، ويساعد المستخدم على إنجاز تواصله ومهامه اليومية بسهولة. اختيار مناسب لمن يبحث عن منتج موثوق في استخداماته العامة، مع تجربة شراء تستحق الاهتمام.";

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->withArgs(fn (string $systemPrompt, string $userPrompt): bool =>
                str_contains($userPrompt, 'عطر فاخر')
                && str_contains($systemPrompt, 'substantial marketing copy'))
            ->andReturn(['result' => $marketingCopy, 'tokens_used' => 170]);

        $this->postJson('/api/v1/ai/marketing-content', [
            'context' => 'عطر فاخر',
            'language' => 'Arabic',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.result', $marketingCopy);
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

    public function test_short_customer_message_returns_a_natural_reply_in_one_request(): void
    {
        $token = $this->merchantToken();
        $reply = 'أهلاً بك، شكرًا لتواصلك معنا. سأتحقق من حالة توفر الجوال وأعود إليك بالمعلومة المؤكدة. هل تقصد إصدارًا أو لونًا محددًا؟';

        $this->mock(AiProviderInterface::class)
            ->shouldReceive('complete')
            ->once()
            ->withArgs(fn (string $systemPrompt, string $userPrompt): bool =>
                str_contains($userPrompt, 'هل الجوال متوفر؟')
                && str_contains($systemPrompt, 'customer-care representative'))
            ->andReturn(['result' => $reply, 'tokens_used' => 95]);

        $this->postJson('/api/v1/ai/customer-reply', [
            'context' => 'هل الجوال متوفر؟',
            'language' => 'Arabic',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonPath('data.result', $reply);
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
        $this->mockProvider("Generated text for a practical product experience in everyday use.\n\nIt offers useful general value for customers who want a simple addition to their routine without unsupported claims.\n\nA clear and professional choice for ordinary daily needs.", 50);

        $this->postJson('/api/v1/ai/product-description', [
            'context' => 'Product context here',
        ], $this->headers($token))
            ->assertStatus(200)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

}
