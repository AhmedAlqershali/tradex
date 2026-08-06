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
You are a professional customer success manager for an e-commerce platform.
Draft a reply on behalf of a merchant to a customer message.
Your reply must be:
- Polite, empathetic, and professional
- Solution-focused (address the customer's concern directly)
- Concise: 2–4 sentences maximum
- Signed off naturally (e.g. "Best regards, [Store Team]")

Return only the reply text — no extra commentary, no subject line.
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

        $storeContext = $storeName ? " The store name is \"{$storeName}\"." : '';
        $userPrompt   = "Write a customer reply in {$language}.{$storeContext} Customer message: {$context}";

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
