<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * OpenAI-backed implementation of AiProviderInterface.
 *
 * To swap providers: implement AiProviderInterface in a new class and
 * update the binding in RepositoryServiceProvider — nothing else changes.
 *
 * Config keys (config/services.php → env):
 *   OPENAI_API_KEY    — required
 *   OPENAI_MODEL      — default: gpt-4o-mini
 *   OPENAI_BASE_URL   — default: https://api.openai.com/v1
 */
class AiProviderService implements AiProviderInterface
{
    private readonly string $apiKey;
    private readonly string $model;
    private readonly string $baseUrl;

    public function __construct()
    {
        $this->apiKey  = (string) config('services.openai.key',     '');
        $this->model   = (string) config('services.openai.model',   'gpt-4o-mini');
        $this->baseUrl = rtrim((string) config('services.openai.base_url', 'https://api.openai.com/v1'), '/');
    }

    /**
     * {@inheritDoc}
     */
    public function complete(string $systemPrompt, string $userPrompt, array $options = []): array
    {
        if (empty($this->apiKey)) {
            throw new AiProviderException(
                'OpenAI API key is not configured. Set OPENAI_API_KEY in .env'
            );
        }

        $payload = [
            'model'       => $this->model,
            'messages'    => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user',   'content' => $userPrompt],
            ],
            'max_tokens'  => (int) ($options['max_tokens']  ?? 800),
            'temperature' => (float) ($options['temperature'] ?? 0.7),
        ];

        try {
            $response = Http::withToken($this->apiKey)
                ->timeout(30)
                ->acceptJson()
                ->post("{$this->baseUrl}/chat/completions", $payload);

            if ($response->failed()) {
                $errorMessage = $response->json('error.message', 'Unknown error from AI provider.');

                Log::error('AI provider request failed', [
                    'status'       => $response->status(),
                    'error'        => $errorMessage,
                    'model'        => $this->model,
                ]);

                throw new AiProviderException("AI provider error: {$errorMessage}");
            }

            $body             = $response->json();
            $result           = $body['choices'][0]['message']['content'] ?? '';
            $promptTokens     = (int) ($body['usage']['prompt_tokens']     ?? 0);
            $completionTokens = (int) ($body['usage']['completion_tokens'] ?? 0);
            $tokensUsed       = (int) ($body['usage']['total_tokens']      ?? ($promptTokens + $completionTokens));

            if (empty($result)) {
                throw new AiProviderException('AI provider returned an empty response.');
            }

            // GPT-4o-mini pricing (per 1M tokens, as of 2026):
            //   Input:  $0.150 / 1M tokens
            //   Output: $0.600 / 1M tokens
            $costUsd = ($promptTokens * 0.000000150) + ($completionTokens * 0.000000600);

            return [
                'result'      => trim($result),
                'tokens_used' => $tokensUsed,
                'cost_usd'    => round($costUsd, 8),
            ];

        } catch (AiProviderException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('AI provider connection error', [
                'error' => $e->getMessage(),
                'model' => $this->model,
            ]);

            throw new AiProviderException(
                'AI provider is currently unavailable. Please try again later.'
            );
        }
    }
}
