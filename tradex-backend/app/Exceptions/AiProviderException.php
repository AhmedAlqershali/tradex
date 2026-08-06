<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown when the external AI provider is unreachable, returns an error,
 * or is misconfigured (e.g. missing API key).
 *
 * Controllers catch this and return a 503 response so clients can retry.
 */
class AiProviderException extends RuntimeException {}
