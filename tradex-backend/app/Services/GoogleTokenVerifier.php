<?php

namespace App\Services;

use App\Contracts\Services\GoogleTokenVerifierInterface;
use App\Exceptions\GoogleAuthenticationException;
use Google\Client;
use Throwable;

class GoogleTokenVerifier implements GoogleTokenVerifierInterface
{
    public function verify(string $credential): array
    {
        $clientId = config('services.google.client_id');

        if (! is_string($clientId) || trim($clientId) === '') {
            throw new GoogleAuthenticationException(
                'Google authentication is not configured.',
                503
            );
        }

        try {
            // The official Google client validates the JWT signature, issuer,
            // expiry, and audience against this OAuth client ID.
            $payload = (new Client(['client_id' => $clientId]))->verifyIdToken($credential);
        } catch (Throwable) {
            throw new GoogleAuthenticationException('Invalid or expired Google credential.');
        }

        if (! is_array($payload)
            || ! is_string($payload['sub'] ?? null)
            || trim($payload['sub']) === ''
            || ! is_string($payload['email'] ?? null)
            || filter_var($payload['email'], FILTER_VALIDATE_EMAIL) === false
            || ($payload['email_verified'] ?? false) !== true
        ) {
            throw new GoogleAuthenticationException('Invalid or expired Google credential.');
        }

        return [
            'sub'   => $payload['sub'],
            'email' => strtolower(trim($payload['email'])),
            'name'  => is_string($payload['name'] ?? null) && trim($payload['name']) !== ''
                ? trim($payload['name'])
                : null,
        ];
    }
}