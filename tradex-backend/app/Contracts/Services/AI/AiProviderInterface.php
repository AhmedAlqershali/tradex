<?php

namespace App\Contracts\Services\AI;

interface AiProviderInterface
{
    /**
     * Send a prompt to the AI provider and return the normalised response.
     *
     * @param  string  $systemPrompt  Instructions for the model's role/behaviour.
     * @param  string  $userPrompt    The actual request content.
     * @param  array   $options       Optional overrides: max_tokens, temperature.
     * @return array{result: string, tokens_used: int, cost_usd: float}
     *
     * @throws \App\Exceptions\AiProviderException  On provider error or misconfiguration.
     */
    public function complete(string $systemPrompt, string $userPrompt, array $options = []): array;
}
