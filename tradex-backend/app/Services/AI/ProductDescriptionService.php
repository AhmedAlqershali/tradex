<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Models\AiUsage;

/**
 * Generates professional product descriptions for merchant products.
 *
 * Requires: merchant user, product name + category context.
 * Records usage after every successful generation.
 */
class ProductDescriptionService implements AiServiceInterface
{
    private const SERVICE_TYPE = AiUsage::TYPE_PRODUCT_DESCRIPTION;

    private const SYSTEM_PROMPT = <<<'PROMPT'
You are an expert e-commerce copywriter specialising in product descriptions.
Write descriptions that are:
- Professional and engaging
- 80–150 words
- Benefit-focused (what the buyer gains, not just features)
- Natural, not spammy
- Ending with a subtle call-to-action

Return only the description text — no titles, no markdown, no extra commentary.
PROMPT;

    public function __construct(
        private readonly AiProviderInterface     $provider,
        private readonly AiUsageServiceInterface $usageService,
    ) {}

    /**
     * {@inheritDoc}
     *
     * Expected payload keys:
     *   user      \App\Models\User   — authenticated merchant
     *   context   string             — product name, category, key features
     *   language  string             — target language (default: English)
     */
    public function generate(array $payload): array
    {
        $user     = $payload['user'];
        $context  = $payload['context'];
        $language = $payload['language'] ?? 'English';

        $this->usageService->checkLimit($user, self::SERVICE_TYPE);

        $userPrompt = "Write a product description in {$language} for: {$context}";

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 300, 'temperature' => 0.75]
        );

        $tokensUsed = $response['tokens_used'] ?? 0;
        $costUsd    = $response['cost_usd']    ?? 0.0;

        $this->usageService->record($user, self::SERVICE_TYPE, $tokensUsed, 1, $costUsd);
        $this->usageService->recordRequest(
            $user,
            self::SERVICE_TYPE,
            ['context' => $context, 'language' => $language],
            $response['result'],
            $tokensUsed,
            1,
            $costUsd,
        );

        return [
            'result'       => $response['result'],
            'tokens_used'  => $tokensUsed,
            'cost_usd'     => $costUsd,
            'service_type' => self::SERVICE_TYPE,
            'language'     => $language,
        ];
    }
}
