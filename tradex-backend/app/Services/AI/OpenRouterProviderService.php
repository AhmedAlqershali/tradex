<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * OpenRouter implementation of AiProviderInterface.
 *
 * OpenRouter exposes an OpenAI-compatible chat completions API. The default
 * model is OpenRouter's free router, which selects an available free model.
 */
class OpenRouterProviderService implements AiProviderInterface
{
    private readonly string $apiKey;
    private readonly string $model;
    private readonly string $baseUrl;

    public function __construct()
    {
        $this->apiKey  = (string) config('services.openrouter.key', '');
        $this->model   = (string) config('services.openrouter.model', 'openrouter/free');
        $this->baseUrl = rtrim((string) config(
            'services.openrouter.base_url',
            'https://openrouter.ai/api/v1'
        ), '/');
    }

    public function complete(string $systemPrompt, string $userPrompt, array $options = []): array
    {
        if ($this->apiKey === '') {
            throw new AiProviderException(
                'OpenRouter API key is not configured. Set OPENROUTER_API_KEY in Replit Secrets.'
            );
        }

        $payload = [
            'model'       => $this->model,
            'messages'    => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => $userPrompt],
            ],
            'max_tokens'  => (int) ($options['max_tokens'] ?? 800),
            'temperature' => (float) ($options['temperature'] ?? 0.7),
        ];

        try {
            $response = Http::withToken($this->apiKey)
                ->timeout(60)
                ->acceptJson()
                ->post("{$this->baseUrl}/chat/completions", $payload);

            if ($response->failed()) {
                $message = $response->json('error.message', 'Unknown error from OpenRouter.');

                Log::error('OpenRouter provider request failed', [
                    'status' => $response->status(),
                    'model'  => $this->model,
                    'error'  => $message,
                ]);

                throw new AiProviderException("OpenRouter provider error: {$message}");
            }

            $body = $response->json();
            $text = $body['choices'][0]['message']['content'] ?? '';
            $text = is_string($text) ? trim($text) : '';

            if ($text === '') {
                throw new AiProviderException('OpenRouter returned an empty response.');
            }

            $promptTokens     = (int) ($body['usage']['prompt_tokens'] ?? 0);
            $completionTokens = (int) ($body['usage']['completion_tokens'] ?? 0);
            $tokensUsed       = (int) ($body['usage']['total_tokens'] ?? ($promptTokens + $completionTokens));

            return [
                'result'      => $text,
                'tokens_used' => $tokensUsed,
                'cost_usd'    => (float) ($body['usage']['cost'] ?? 0.0),
            ];
        } catch (AiProviderException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('OpenRouter provider connection error', [
                'model' => $this->model,
                'error' => $e->getMessage(),
            ]);

            throw new AiProviderException(
                'OpenRouter provider is currently unavailable. Please try again later.'
            );
        }
    }
}