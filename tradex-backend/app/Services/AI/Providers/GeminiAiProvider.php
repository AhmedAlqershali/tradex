<?php

namespace App\Services\AI\Providers;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiProviderException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Gemini provider implementation bound by AiServiceProvider.
 *
 * NOTE: The active production binding is GeminiProviderService (bound in
 * RepositoryServiceProvider). This class exists for legacy compatibility
 * and implements the same complete() contract so both bindings are safe.
 */
class GeminiAiProvider implements AiProviderInterface
{
    private readonly string $apiKey;
    private readonly string $baseUrl;
    private readonly string $model;

    public function __construct()
    {
        $this->apiKey  = (string) config('services.gemini.key', '');
        $this->baseUrl = rtrim((string) config('services.gemini.base_url',
            'https://generativelanguage.googleapis.com/v1beta'), '/');
        $this->model   = (string) config('services.gemini.model', 'gemini-3.6-flash');
    }

    public function complete(string $systemPrompt, string $userPrompt, array $options = []): array
    {
        if (empty($this->apiKey)) {
            throw new AiProviderException('Gemini API key is not configured. Set GEMINI_API_KEY in .env');
        }

        $maxTokens   = (int)   ($options['max_tokens']  ?? 800);
        $temperature = (float) ($options['temperature'] ?? 0.7);

        $payload = [
            'systemInstruction' => ['parts' => [['text' => $systemPrompt]]],
            'contents'          => [['role' => 'user', 'parts' => [['text' => $userPrompt]]]],
            'generationConfig'  => [
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
                if (in_array($status, [401, 403], true)) {
                    $message = 'Gemini API key is invalid or lacks permission. ' . $message;
                }
                Log::error('GeminiAiProvider request failed', ['status' => $status, 'error' => $message]);
                throw new AiProviderException("Gemini provider error: {$message}");
            }

            $body = $response->json();
            $text = $body['candidates'][0]['content']['parts'][0]['text'] ?? '';

            if ($text === '' || $text === null) {
                $blockReason = $body['promptFeedback']['blockReason'] ?? null;
                throw new AiProviderException(
                    $blockReason
                        ? "Content blocked by Gemini safety filters (reason: {$blockReason})."
                        : 'Gemini returned an empty response.'
                );
            }

            $promptTokens    = (int) ($body['usageMetadata']['promptTokenCount']     ?? 0);
            $candidateTokens = (int) ($body['usageMetadata']['candidatesTokenCount'] ?? 0);
            $tokensUsed      = (int) ($body['usageMetadata']['totalTokenCount']      ?? ($promptTokens + $candidateTokens));
            $costUsd         = ($promptTokens * 0.000000075) + ($candidateTokens * 0.000000300);

            return [
                'result'      => trim($text),
                'tokens_used' => $tokensUsed,
                'cost_usd'    => round($costUsd, 8),
            ];

        } catch (AiProviderException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('GeminiAiProvider connection error', ['error' => $e->getMessage()]);
            throw new AiProviderException('Gemini provider is currently unavailable. Please try again later.');
        }
    }
}
