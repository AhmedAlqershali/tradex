<?php

namespace App\Contracts\Services\AI;

interface AiServiceInterface
{
    /**
     * Generate AI content for the given payload.
     *
     * @param  array  $payload  Service-specific context (user, context, language, …)
     * @return array            Normalised result array (keys depend on the service)
     */
    public function generate(array $payload): array;
}
