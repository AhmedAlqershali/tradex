<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Google Gemini implementation of AiProviderInterface.
 *
 * Uses the Gemini REST API (generateContent endpoint).
 * Auth is via the `x-goog-api-key` header.
 *
 * Config keys (config/services.php → env):
 *   GEMINI_API_KEY    — required
 *   GEMINI_MODEL      — default: gemini-2.0-flash
 *   GEMINI_BASE_URL   — default: https://generativelanguage.googleapis.com/v1beta
 *
 * To swap back to OpenAI: rebind AiProviderInterface → AiProviderService
 * in RepositoryServiceProvider. Nothing else changes.
 */
class GeminiProviderService implements AiProviderInterface
{
    private readonly string $apiKey;
    private readonly string $model;
    private readonly string $baseUrl;

    public function __construct()
    {
        $this->apiKey  = (string) config('services.gemini.key',     '');
        $this->model   = (string) config('services.gemini.model',   'gemini-2.0-flash');
        $this->baseUrl = rtrim((string) config('services.gemini.base_url',
            'https://generativelanguage.googleapis.com/v1beta'), '/');
    }

    /**
     * {@inheritDoc}
     *
     * Translates the OpenAI-style (systemPrompt, userPrompt, options) call into
     * Gemini's generateContent request, then maps the response back to the
     * shared internal format: { result: string, tokens_used: int }.
     *
     * Gemini error codes handled:
     *   400 — invalid request / bad API key format  → AiProviderException
     *   401/403 — invalid/missing API key           → AiProviderException (with key hint)
     *   429 — provider-side rate limit              → AiProviderException
     *   5xx — Gemini service unavailable            → AiProviderException
     *   timeout / network failure                   → AiProviderException
     *   empty candidates array                      → AiProviderException
     */
    public function complete(string $systemPrompt, string $userPrompt, array $options = []): array
    {
        if (empty($this->apiKey)) {
            throw new AiProviderException(
                'Gemini API key is not configured. Set GEMINI_API_KEY in .env'
            );
        }

        $maxTokens   = (int)   ($options['max_tokens']  ?? 800);
        $temperature = (float) ($options['temperature'] ?? 0.7);

        $payload = [
            'systemInstruction' => [
                'parts' => [['text' => $systemPrompt]],
            ],
            'contents' => [
                [
                    'role'  => 'user',
                    'parts' => [['text' => $userPrompt]],
                ],
            ],
            'generationConfig' => [
                'maxOutputTokens' => $maxTokens,
                'temperature'     => $temperature,
            ],
        ];

        $url = "{$this->baseUrl}/models/{$this->model}:generateContent";

        try {
            $response = Http::withHeader('x-goog-api-key', $this->apiKey)
                ->timeout(30)
                ->acceptJson()
                ->post($url, $payload);

            if ($response->failed()) {
                $status  = $response->status();
                $message = $response->json('error.message', 'Unknown error from Gemini.');

                // Surface a clear hint when the key is wrong so operators
                // can diagnose quickly without reading provider error prose.
                if (in_array($status, [401, 403], true)) {
                    $message = 'Gemini API key is invalid or lacks permission. '
                        . 'Check GEMINI_API_KEY in .env. Provider said: ' . $message;
                }

                Log::error('Gemini provider request failed', [
                    'status' => $status,
                    'error'  => $message,
                    'model'  => $this->model,
                ]);

                throw new AiProviderException("Gemini provider error: {$message}");
            }

            $body = $response->json();

            // Gemini may return an empty candidates array when content is
            // filtered by safety policies — treat that as a provider failure.
            $text = $body['candidates'][0]['content']['parts'][0]['text'] ?? '';
            $text = is_string($text) ? trim($text) : '';

            if ($text === '') {
                // Check for a prompt-feedback block reason before generic message.
                $blockReason = $body['promptFeedback']['blockReason'] ?? null;
                $detail      = $blockReason
                    ? "Content blocked by Gemini safety filters (reason: {$blockReason})."
                    : 'Gemini returned an empty response.';

                throw new AiProviderException($detail);
            }

            // `totalTokenCount` is the sum of prompt + candidate tokens.
            // Separate prompt/candidate counts are available for finer-grained
            // cost attribution if needed in the future.
            $promptTokens    = (int) ($body['usageMetadata']['promptTokenCount']     ?? 0);
            $candidateTokens = (int) ($body['usageMetadata']['candidatesTokenCount'] ?? 0);
            $tokensUsed      = (int) ($body['usageMetadata']['totalTokenCount']      ?? ($promptTokens + $candidateTokens));

            // Gemini 2.0 Flash pricing (per 1M tokens, as of 2026):
            //   Input:  $0.075 / 1M tokens
            //   Output: $0.300 / 1M tokens
            $costUsd = ($promptTokens * 0.000000075) + ($candidateTokens * 0.000000300);

            return [
                'result'      => $text,
                'tokens_used' => $tokensUsed,
                'cost_usd'    => round($costUsd, 8),
            ];

        } catch (AiProviderException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('Gemini provider connection error', [
                'error' => $e->getMessage(),
                'model' => $this->model,
            ]);

            throw new AiProviderException(
                'Gemini provider is currently unavailable. Please try again later.'
            );
        }
    }
}
