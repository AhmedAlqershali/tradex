<?php

namespace App\Services\AI;

use JsonException;

final class AiResponseSanitizer
{
    public static function clean(string $text): string
    {
        $text = trim(str_replace(["\r\n", "\r"], "\n", $text));

        try {
            $decoded = json_decode($text, true, 16, JSON_THROW_ON_ERROR);
            if (is_array($decoded)) {
                $text = self::extractText($decoded) ?? '';
            }
        } catch (JsonException) {
            // The provider normally returns plain text.
        }

        $text = preg_replace('/^```(?:json|text|markdown)?\s*|\s*```$/i', '', $text) ?? $text;
        $text = preg_replace('/\(\s*in\s+(?:Arabic|English)\s*\)/i', '', $text) ?? $text;
        $text = preg_replace('/^\s*(?:final\s+answer|answer|output|response)\s*:\s*/im', '', $text) ?? $text;

        $lines = preg_split('/\n/', trim($text)) ?: [];
        $internalLine = '/^\s*(?:(?:system|developer|internal|user)\s+)?(?:prompt|instructions?)\s*:/i';
        $lines = array_values(array_filter($lines, static function (string $line) use ($internalLine): bool {
            return !preg_match($internalLine, $line);
        }));

        return trim(implode("\n", $lines));
    }

    private static function extractText(array $value): ?string
    {
        foreach (['result', 'content', 'text', 'message'] as $key) {
            if (isset($value[$key]) && is_string($value[$key])) {
                return $value[$key];
            }
        }

        return null;
    }
}
