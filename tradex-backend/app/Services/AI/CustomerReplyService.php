<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Models\AiUsage;

/**
 * Suggests professional merchant replies to customer messages.
 *
 * Helps merchants respond to reviews, order inquiries, and support
 * requests quickly without losing a personal, professional tone.
 */
class CustomerReplyService implements AiServiceInterface
{
    private const SERVICE_TYPE = AiUsage::TYPE_CUSTOMER_REPLY;

    private const SYSTEM_PROMPT = <<<'PROMPT'
You are a skilled e-commerce customer-care representative writing on behalf of
the merchant. Address the customer's actual message directly and acknowledge
their concern before giving the most useful next step supported by the input.
Never invent order status, prices, refunds, delivery dates, stock, policies,
contact details, guarantees, or actions the merchant has not provided. If key
information is missing, ask one focused question or say that the merchant will
verify it; do not promise a result. Preserve the customer's language and use
natural, professional local phrasing without mixing languages.

Return only a concise plain-text reply of 2-4 sentences. No subject, bullets,
markdown, emojis, generic greeting, or automatic sign-off unless a store name is
provided.
PROMPT;

    public function __construct(
        private readonly AiProviderInterface     $provider,
        private readonly AiUsageServiceInterface $usageService,
    ) {}

    /**
     * {@inheritDoc}
     *
     * Expected payload keys:
     *   user             \App\Models\User  — authenticated merchant
     *   context          string            — the customer's message
     *   language         string            — reply language (default: English)
     *   store_name       string|null       — optional store name for sign-off
     */
    public function generate(array $payload): array
    {
        $user      = $payload['user'];
        $context   = $payload['context'];
        $language  = $payload['language']   ?? 'English';
        $storeName = $payload['store_name'] ?? null;

        $this->usageService->checkLimit($user, self::SERVICE_TYPE);

        $storeContext = $storeName ? "STORE NAME: {$storeName}" : 'STORE NAME: not provided';
        $userPrompt   = <<<PROMPT
    Write the reply in {$language}.

    CUSTOMER MESSAGE (address this directly):
    {$context}

    {$storeContext}
    PROMPT;

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 250, 'temperature' => 0.65]
        );

        $tokensUsed = $response['tokens_used'] ?? 0;
        $costUsd    = $response['cost_usd']    ?? 0.0;

        $this->usageService->record($user, self::SERVICE_TYPE, $tokensUsed, 1, $costUsd);
        $this->usageService->recordRequest(
            $user,
            self::SERVICE_TYPE,
            [
                'context'    => $context,
                'language'   => $language,
                'store_name' => $storeName,
            ],
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
