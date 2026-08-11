<?php

namespace App\Exceptions;

use RuntimeException;

class GoogleAuthenticationException extends RuntimeException
{
    public function __construct(string $message, public readonly int $statusCode = 401)
    {
        parent::__construct($message);
    }
}