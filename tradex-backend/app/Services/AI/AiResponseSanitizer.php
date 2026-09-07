<?php

namespace App\Services\AI;

use JsonException;

final class AiResponseSanitizer
{
    public static function clean(string $text): string
    {
        $text = trim(str_replace(["\r\n", "\r"], "\n", $text));
        $text = preg_replace('/^```(?:json|text|markdown)?\s*|\s*```$/i', '', $text) ?? $text;

        foreach ([$text, ...self::embeddedJsonCandidates($text)] as $candidate) {
            try {
                $decoded = json_decode($candidate, true, 16, JSON_THROW_ON_ERROR);
                if (is_array($decoded)) {
                    $extracted = self::extractText($decoded);
                    if ($extracted !== null) {
                        $text = $extracted;
                        break;
                    }
                }
            } catch (JsonException) {
                // The provider normally returns plain text.
            }
        }

        $text = preg_replace('/\(\s*in\s+(?:Arabic|English)\s*\)/i', '', $text) ?? $text;
        $text = preg_replace('/^\s*(?:final\s+answer|answer|output|response)\s*:\s*/im', '', $text) ?? $text;

        $lines = preg_split('/\n/', trim($text)) ?: [];
        $internalLine = '/^\s*(?:(?:system|developer|internal|user)\s+)?(?:prompt|instructions?)\s*:/i';
        $lines = array_filter($lines, static function (string $line) use ($internalLine): bool {
            return !preg_match($internalLine, $line)
                && !preg_match('/^\s*(?:evaluate input facts(?:\s+vs\.?\s+constraints)?|analyze input|constraints|system prompt|developer instruction|internal reasoning)\s*:?/i', $line);
        });

        return trim(implode("\n", $lines));
    }

    private static function embeddedJsonCandidates(string $text): array
    {
        return preg_match('/\{.*\}/s', $text, $matches) === 1
            ? [$matches[0]]
            : [];
    }

    private static function extractText(array $value): ?string
    {
        foreach (['result', 'content', 'text', 'output', 'message'] as $key) {
            if (isset($value[$key]) && is_string($value[$key]) && trim($value[$key]) !== '') {
                return $value[$key];
            }
        }

        foreach ($value as $item) {
            if (is_array($item)) {
                $text = self::extractText($item);
                if ($text !== null) {
                    return $text;
                }
            }
        }

        return null;
    }
}