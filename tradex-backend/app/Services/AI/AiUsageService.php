<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiUsageServiceInterface;
use Illuminate\Support\Facades\DB;

class AiUsageService implements AiUsageServiceInterface
{
    public function hasAvailableQuota(int $userId): bool
    {
        $dailyCount = DB::table("ai_usage_logs")
            ->where("user_id", $userId)
            ->whereDate("created_at", now()->today())
            ->count();

        $maxDailyQuota = config("services.ai.daily_limit", 50);

        return $dailyCount < $maxDailyQuota;
    }

    public function logUsage(int $userId, string $prompt, string $response): void
    {
        DB::table("ai_usage_logs")->insert([
            "user_id" => $userId,
            "prompt_tokens" => strlen($prompt),
            "response_tokens" => strlen($response),
            "created_at" => now(),
            "updated_at" => now(),
        ]);
    }
}
