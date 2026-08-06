<?php

namespace App\Contracts\Services\AI;

use App\Models\User;

interface AiUsageServiceInterface
{
    /**
     * Throw AiRateLimitException if the user has exhausted their daily limit
     * for the given service type.
     *
     * @throws \App\Exceptions\AiRateLimitException
     */
    public function checkLimit(User $user, string $serviceType): void;

    /**
     * Record a completed AI request in ai_usages (aggregate row per request).
     */
    public function record(
        User   $user,
        string $serviceType,
        int    $tokensUsed,
        int    $credits,
        float  $costUsd,
    ): void;

    /**
     * Record the full request/response detail in ai_requests.
     */
    public function recordRequest(
        User   $user,
        string $serviceType,
        array  $requestPayload,
        string $responseContent,
        int    $tokensUsed,
        int    $credits,
        float  $costUsd,
    ): void;

    /**
     * Return today's and this month's usage summary for the given user.
     */
    public function getUsageSummary(User $user): array;
}
