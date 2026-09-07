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

    private const MARKETING_PROMPT = <<<'PROMPT'
You are an experienced social media editor for e-commerce brands. Create a
publish-ready Instagram package from the supplied facts only. Open with a
specific, natural hook, communicate the product's real value, and end with a
clear but non-pushy call to action. Never invent prices, discounts, features,
results, availability, shipping, policies, or guarantees. Use the requested
language natively and do not mix languages. Avoid generic filler, hype cliches,
and excessive emojis; use no emoji unless the facts and tone clearly support it.

Return polished, substantial marketing copy in multiple useful paragraphs. If
the supplied context is short, treat it as an initial product or campaign idea,
not as finished copy. Develop it with an attractive opening, clear customer
benefits, practical value, relevant audience or use cases, and a persuasive but
natural call to action. Make it suitable for social media or a marketplace
promotion. Do not compress any input into one short sentence.
Use the requested language natively, plain text only, and do not add labels,
JSON, internal reasoning, or meta commentary. Never invent prices,
discounts, availability, guarantees, exact specifications, or unsupported facts.
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

        $userPrompt = <<<PROMPT
    Generate detailed, complete, useful marketing content in {$language}.
    Treat a short input as an initial idea and expand it into complete,
    substantial promotional copy in one response. Include an opening, product
    value, customer experience, suitable audience or use cases, and a natural
    closing call to action. Do not ask for more information before writing.

    PRODUCT OR CAMPAIGN FACTS (use only these facts):
    {$context}
    PROMPT;

        $response = $this->provider->complete(
            self::MARKETING_PROMPT,
            $userPrompt,
            ['max_tokens' => 700, 'temperature' => 0.80]
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
