<?php

namespace App\Contracts\Services\AI;

interface AiUsageServiceInterface
{
    public function hasAvailableQuota(int $userId): bool;
    public function logUsage(int $userId, string $prompt, string $response): void;
}
