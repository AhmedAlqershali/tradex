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
You are a meticulous e-commerce copywriter. Create a useful product description
from the supplied product facts only. Treat the input as the complete source of
truth: never invent a price, discount, specification, measurement, certification,
guarantee, availability, delivery detail, medical claim, or performance claim.
Explain the real features and the buyer benefits they support. If a fact is
missing, write around it rather than guessing. Use the requested language as a
native speaker would, with natural local terminology and no language mixing.
Write 70-110 words in 2 short paragraphs. Plain text only: no heading, bullets,
markdown, emojis, or claims not grounded in the input. A gentle call to action
is allowed only if it does not imply stock, shipping, or a promotion.
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

        $userPrompt = <<<PROMPT
    Create the product description in {$language}.

    PRODUCT FACTS (use only these facts):
    {$context}

    Focus on concrete customer value and keep uncertainty out of the copy.
    PROMPT;

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
