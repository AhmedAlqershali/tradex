<?php

namespace App\Support;

final class PublicMediaUrl
{
    public const DEFAULT_ORIGIN = 'https://tradex-v2us.onrender.com';
    public const PROD_ORIGIN = self::DEFAULT_ORIGIN;

    public static function origin(): string
    {
        $origin = trim((string) config('app.url', self::DEFAULT_ORIGIN));
        $origin = rtrim($origin, '/');

        return $origin !== '' ? $origin : self::DEFAULT_ORIGIN;
    }

    public static function forPath(?string $path): ?string
    {
        if ($path === null || trim($path) === '') {
            return null;
        }

        $value = trim($path);
        $value = str_replace('\\', '/', $value);

        if (preg_match('#^https?://#i', $value) === 1) {
            $parsed = parse_url($value);
            $value = $parsed['path'] ?? '/';
        }

        $value = preg_replace('#^/+#', '', $value);
        $value = preg_replace('#^(?:api/v1/)?storage/?#i', '', $value);
        $value = preg_replace('#^/+#', '', $value);

        if ($value === '' || $value === 'storage') {
            return self::origin() . '/storage';
        }

        return self::origin() . '/storage/' . ltrim($value, '/');
    }
}
