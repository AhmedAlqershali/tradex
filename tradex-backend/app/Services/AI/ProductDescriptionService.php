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
You are a professional e-commerce copywriter. Write one useful, natural, detailed
product description from the supplied product information.

Use the supplied information as the complete source of truth. Do not invent or
assume specifications, features, materials, dimensions, prices, certifications,
guarantees, availability, performance claims, or other facts that were not
provided. When the information is brief, develop the description naturally by
explaining only safe, general benefits, everyday use, and suitable use cases that
can be reasonably inferred from the product information. Do not simply repeat
the product name and do not stop at a shallow one-sentence introduction.

Write in the requested language as a native speaker. Use clear, connected
paragraphs with enough substance for a marketplace listing, while keeping every
claim factual and appropriately general. Return only the finished description in
plain text, without headings, bullets, markdown, labels, emojis, or commentary
about the task.
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
    Requested language: {$language}

    Product information:
    {$context}

    Return only the finished product description.
    PROMPT;

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 1200, 'temperature' => 0.75, 'diagnostics' => true]
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
