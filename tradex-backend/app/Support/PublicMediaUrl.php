<?php

namespace App\Support;

final class PublicMediaUrl
{
    public const PROD_ORIGIN = 'https://tradex-v2us.onrender.com';

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
            return self::PROD_ORIGIN . '/storage';
        }

        return self::PROD_ORIGIN . '/storage/' . ltrim($value, '/');
    }
}
