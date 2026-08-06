<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Models\AiUsage;

/**
 * Generates marketing captions, social media posts, and promotional copy
 * for merchant products and campaigns.
 */
class MarketingContentService implements AiServiceInterface
{
    private const SERVICE_TYPE = AiUsage::TYPE_MARKETING_CONTENT;

    private const SYSTEM_PROMPT = <<<'PROMPT'
You are an expert social media marketer and copywriter for e-commerce brands.
Your output must include:
1. A short, punchy marketing caption (1–2 sentences, high energy)
2. 3–5 relevant hashtags
3. A one-sentence promotional tagline

Format your response exactly as:
Caption: <caption text>
Hashtags: <hashtag1> <hashtag2> ...
Tagline: <tagline text>

Keep it concise, brand-appropriate, and scroll-stopping.
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
     *   context   string             — product/campaign details
     *   language  string             — target language (default: English)
     */
    public function generate(array $payload): array
    {
        $user     = $payload['user'];
        $context  = $payload['context'];
        $language = $payload['language'] ?? 'English';

        $this->usageService->checkLimit($user, self::SERVICE_TYPE);

        $userPrompt = "Create marketing content in {$language} for: {$context}";

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 400, 'temperature' => 0.80]
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
