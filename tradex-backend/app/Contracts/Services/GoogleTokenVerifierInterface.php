<?php

namespace App\Contracts\Services;

interface GoogleTokenVerifierInterface
{
    /**
     * Verify a Google ID token and return its trusted identity claims.
     *
     * @return array{sub:string,email:string,name:?string}
     */
    public function verify(string $credential): array;
}