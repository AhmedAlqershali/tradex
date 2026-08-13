<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

/**
 * Temporary, explicitly enabled avatar diagnostics.
 *
 * Remove this class and its call sites after one live upload is diagnosed.
 * AVATAR_TRACE must be explicitly true; it is false by default.
 */
final class AvatarTrace
{
    public static function enabled(): bool
    {
        return filter_var(env('AVATAR_TRACE', false), FILTER_VALIDATE_BOOL);
    }

    public static function begin(): void
    {
        self::write('[AVATAR_TRACE_BEGIN]');
    }

    public static function end(): void
    {
        self::write('[AVATAR_TRACE_END]');
    }

    public static function validation(bool $passed): void
    {
        self::write('[AVATAR_TRACE] validation', [
            'result' => $passed ? 'passed' : 'failed',
        ]);
    }

    public static function received(UploadedFile $file): void
    {
        $realPath = $file->getRealPath();
        self::write('[AVATAR_TRACE] upload', [
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'sha256' => $realPath && is_file($realPath)
                ? hash_file('sha256', $realPath)
                : 'unavailable',
        ]);
    }

    public static function stored(string $path): void
    {
        $disk = Storage::disk('public');
        $absolutePath = $disk->path($path);
        self::write('[AVATAR_TRACE] storage', [
            'relative_path' => $path,
            'exists' => $disk->exists($path),
            'file_size' => is_file($absolutePath) ? filesize($absolutePath) : null,
            'sha256' => is_file($absolutePath)
                ? hash_file('sha256', $absolutePath)
                : 'unavailable',
        ]);
    }

    public static function database(string $stage, ?string $path): void
    {
        self::write('[AVATAR_TRACE] database', [
            'stage' => $stage,
            'relative_avatar_path' => $path,
        ]);
    }

    public static function response(?string $url): void
    {
        self::write('[AVATAR_TRACE] response', [
            'avatar_url' => $url === null ? null : self::redactUrl($url),
        ]);
    }

    private static function write(string $message, array $context = []): void
    {
        if (self::enabled()) {
            // warning is used so the existing production LOG_LEVEL=warning
            // still captures this temporary trace when explicitly enabled.
            Log::warning($message, $context);
        }
    }

    private static function redactUrl(string $url): string
    {
        $parsed = parse_url($url);
        if ($parsed === false) {
            return strtok($url, '?') ?: $url;
        }

        $scheme = isset($parsed['scheme']) ? $parsed['scheme'].'://' : '';
        $host = $parsed['host'] ?? '';
        $port = isset($parsed['port']) ? ':'.$parsed['port'] : '';
        $path = $parsed['path'] ?? '';

        return $scheme.$host.$port.$path;
    }
}