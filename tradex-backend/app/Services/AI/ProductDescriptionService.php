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
The merchant may provide only a short product idea or name, and that is valid
input. Expand a short input into a complete marketplace-ready description using
safe, general category-level benefits and practical use cases. Do not merely
repeat or summarize the supplied words, and do not ask the merchant for more
details before writing the description.
Write a complete, detailed, professional marketplace listing across multiple
well-spaced paragraphs. Do not stop after the opening sentence. Continue until
the description feels complete, covering the product introduction, general
benefits, user experience, practical uses, general design appeal, suitable
users, selling value, and a natural professional closing when appropriate.
Provide enough meaningful detail to be genuinely useful; do not reduce the
answer to a summary of the product name. Let the amount of detail follow the
product facts and the merchant's intended use.
Plain text only: no heading, bullets,
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
    Write only the final product description in {$language}, as if it will be
    pasted directly into a marketplace listing. Do not explain the task or
    your process. Do not include a heading, labels such as "Goal:" or "Task:",
    language notes such as "(in Arabic)", markdown, or any meta-commentary.

    PRODUCT FACTS (use only these facts):
    {$context}

    Treat the supplied facts as the full source of truth. When the input is
    only a product name, enrich the copy with natural general-purpose marketing
    language, user experience, suitable users, practical use, and value
    without inventing exact specifications, price, storage, processor, camera,
    battery, warranty, colors, availability, or other unsupported facts.
    Focus on concrete customer value and keep uncertainty out of the copy.
    Produce the complete final listing in one response. Do not stop after the
    first sentence, do not summarize the input, and do not ask for more facts.
    Return only the finished description text that the merchant can paste
    directly into a listing.
    PROMPT;

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 1200, 'temperature' => 0.75]
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
