<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown by AiUsageService when a user has exhausted their daily or
 * monthly AI request allowance.
 *
 * Controllers catch this and return a 429 response.
 */
class AiRateLimitException extends RuntimeException {}
