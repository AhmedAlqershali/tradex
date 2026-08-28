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

    private const INSTAGRAM_PROMPT = <<<'PROMPT'
You are an experienced social media editor for e-commerce brands. Create a
publish-ready Instagram package from the supplied facts only. Open with a
specific, natural hook, communicate the product's real value, and end with a
clear but non-pushy call to action. Never invent prices, discounts, features,
results, availability, shipping, policies, or guarantees. Use the requested
language natively and do not mix languages. Avoid generic filler, hype cliches,
and excessive emojis; use no emoji unless the facts and tone clearly support it.

Return exactly three plain-text lines and no markdown:
Caption: one or two engaging sentences, 35-70 words
Hashtags: 4-6 distinct, relevant hashtags based on the product/category/audience
Tagline: one memorable sentence, without a fabricated offer
PROMPT;

    private const HASHTAGS_PROMPT = <<<'PROMPT'
You are a precise social media strategist. Generate hashtags from the supplied
product and category facts only. Return exactly one plain-text line beginning
with "Hashtags:" followed by 5-8 distinct hashtags. Mix specific product,
category, audience, and relevant context tags when supported by the input.
Exclude unrelated or broad filler tags, repeated ideas, campaign claims, prices,
discounts, locations, and unsupported audience or product attributes. Use the
requested language natively; do not add a caption, tagline, explanation, emojis,
or markdown. Do not invent facts to fill the list.
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
        $purpose  = $payload['purpose'] ?? 'instagram';

        $this->usageService->checkLimit($user, self::SERVICE_TYPE);

        $systemPrompt = $purpose === 'hashtags'
            ? self::HASHTAGS_PROMPT
            : self::INSTAGRAM_PROMPT;
        $userPrompt = <<<PROMPT
    Generate the {$purpose} content in {$language}.

    PRODUCT OR CAMPAIGN FACTS (use only these facts):
    {$context}
    PROMPT;

        $response = $this->provider->complete(
            $systemPrompt,
            $userPrompt,
            ['max_tokens' => 400, 'temperature' => 0.80]
        );

        $tokensUsed = $response['tokens_used'] ?? 0;
        $costUsd    = $response['cost_usd']    ?? 0.0;

        $this->usageService->record($user, self::SERVICE_TYPE, $tokensUsed, 1, $costUsd);
        $this->usageService->recordRequest(
            $user,
            self::SERVICE_TYPE,
            ['context' => $context, 'language' => $language, 'purpose' => $purpose],
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
