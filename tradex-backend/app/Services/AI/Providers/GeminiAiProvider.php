<?php

namespace App\Services\AI\Providers;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Exceptions\AiNotImplementedException;
use Illuminate\Support\Facades\Http;
use Generator;

class GeminiAiProvider implements AiProviderInterface
{
    protected string $apiKey;
    protected string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config("services.ai.gemini_key", "");
        $this->baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/";

        if (empty($this->apiKey)) {
            throw new AiNotImplementedException("Gemini API Key is missing or not configured.");
        }
    }

    public function generateResponse(string $prompt, array $options = []): string
    {
        $model = $options["model"] ?? "gemini-1.5-flash";
        
        $response = Http::post("{$this->baseUrl}{$model}:generateContent?key={$this->apiKey}", [
            "contents" => [
                [
                    "parts" => [
                        ["text" => $prompt]
                    ]
                ]
            ],
            "generationConfig" => [
                "temperature" => $options["temperature"] ?? 0.7,
                "maxOutputTokens" => $options["max_tokens"] ?? 1000,
            ]
        ]);

        if ($response->failed()) {
            throw new \RuntimeException("Failed to communicate with Gemini API: " . $response->body());
        }

        return $response->json("candidates.0.content.parts.0.text") ?? "";
    }

    public function streamResponse(string $prompt, array $options = []): Generator
    {
        $text = $this->generateResponse($prompt, $options);
        $chunks = str_split($text, 20);
        foreach ($chunks as $chunk) {
            yield $chunk;
        }
    }
}
