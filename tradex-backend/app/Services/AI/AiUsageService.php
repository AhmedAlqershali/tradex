<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Exceptions\AiRateLimitException;
use App\Models\AiSetting;
use App\Models\AiUsage;
use App\Models\User;
use App\Contracts\Services\SubscriptionServiceInterface;
use Illuminate\Support\Facades\DB;

class AiUsageService implements AiUsageServiceInterface
{
    public function __construct(
        private readonly SubscriptionServiceInterface $subscriptionService,
    ) {}

    // -------------------------------------------------------------------------
    // Limit check
    // -------------------------------------------------------------------------

    /**
     * Block the request if the user has exhausted their AI quota or AI is disabled.
     *
     * Priority for daily limit:
     *   1. AiSetting.daily_limit  (per-user override, null = use global default)
     *   2. AI_DAILY_LIMIT         (global env default, default 50)
     *
     * Priority for monthly limit:
     *   1. Active subscription Plan.ai_usage_limit  (null = unlimited via plan)
     *   2. AiSetting.monthly_limit                  (null = unlimited)
     *
     * @throws AiRateLimitException
     */
    public function checkLimit(User $user, string $serviceType): void
    {
        $setting = AiSetting::where('user_id', $user->id)->first();

        // Global kill-switch
        if ($setting && $setting->is_active === false) {
            throw new AiRateLimitException('AI access is disabled for your account.');
        }

        // ── Daily limit ───────────────────────────────────────────────────────
        $globalDailyLimit = (int) config('services.ai.daily_limit', 50);
        $dailyLimit = ($setting && $setting->daily_limit !== null)
            ? $setting->daily_limit
            : $globalDailyLimit;

        $usedToday = AiUsage::where('user_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->sum('request_count');

        if ($dailyLimit > 0 && $usedToday >= $dailyLimit) {
            throw new AiRateLimitException(
                "Daily AI request limit of {$dailyLimit} reached. Please try again tomorrow."
            );
        }

        // ── Monthly limit (subscription plan or per-user setting) ─────────────
        $monthlyLimit = $this->effectiveMonthlyLimit($user, $setting);

        if ($monthlyLimit !== null) {
            $usedThisMonth = AiUsage::where('user_id', $user->id)
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->sum('credits_used');

            if ($usedThisMonth >= $monthlyLimit) {
                throw new AiRateLimitException(
                    "Monthly AI credit limit of {$monthlyLimit} reached."
                );
            }
        }
    }

    // -------------------------------------------------------------------------
    // Usage recording
    // -------------------------------------------------------------------------

    public function record(
        User   $user,
        string $serviceType,
        int    $tokensUsed,
        int    $credits,
        float  $costUsd,
    ): void {
        AiUsage::create([
            'user_id'       => $user->id,
            'service_type'  => $serviceType,
            'request_count' => 1,
            'credits_used'  => $credits,
            'tokens_used'   => $tokensUsed,
            'cost_usd'      => $costUsd,
        ]);
    }

    public function recordRequest(
        User   $user,
        string $serviceType,
        array  $requestPayload,
        string $responseContent,
        int    $tokensUsed,
        int    $credits,
        float  $costUsd,
    ): void {
        DB::table('ai_requests')->insert([
            'user_id'          => $user->id,
            'service_type'     => $serviceType,
            'request_payload'  => json_encode($requestPayload),
            'response_content' => $responseContent,
            'tokens_used'      => $tokensUsed,
            'credits_used'     => $credits,
            'cost_usd'         => $costUsd,
            'status'           => 'completed',
            'created_at'       => now(),
            'updated_at'       => now(),
        ]);
    }

    // -------------------------------------------------------------------------
    // Usage summary
    // -------------------------------------------------------------------------

    public function getUsageSummary(User $user): array
    {
        $setting = AiSetting::where('user_id', $user->id)->first();

        $globalDailyLimit = (int) config('services.ai.daily_limit', 50);
        $dailyLimit = ($setting && $setting->daily_limit !== null)
            ? $setting->daily_limit
            : $globalDailyLimit;

        $monthlyLimit = $this->effectiveMonthlyLimit($user, $setting);
        $isActive     = $setting ? (bool) $setting->is_active : true;

        // Today
        $todayRow = AiUsage::where('user_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->selectRaw('SUM(request_count) as requests, SUM(credits_used) as credits')
            ->first();

        $today             = (int) ($todayRow->requests ?? 0);
        $creditsUsedToday  = (int) ($todayRow->credits  ?? 0);

        // This month
        $monthRow = AiUsage::where('user_id', $user->id)
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->selectRaw('SUM(request_count) as requests, SUM(credits_used) as credits')
            ->first();

        $thisMonth             = (int) ($monthRow->requests ?? 0);
        $creditsUsedThisMonth  = (int) ($monthRow->credits  ?? 0);

        return [
            'today'                   => $today,
            'this_month'              => $thisMonth,
            'daily_limit'             => $dailyLimit,
            'monthly_limit'           => $monthlyLimit,
            'is_active'               => $isActive,
            'credits_used_today'      => $creditsUsedToday,
            'credits_used_this_month' => $creditsUsedThisMonth,
        ];
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Determine the effective monthly credit limit for a user.
     *
     * Precedence:
     *   1. Active subscription Plan.ai_usage_limit (if not null)
     *   2. AiSetting.monthly_limit                 (if not null)
     *   3. null = unlimited
     */
    private function effectiveMonthlyLimit(User $user, ?AiSetting $setting): ?int
    {
        // Use the canonical entitlement check so expired or future-dated
        // subscription periods cannot provide AI plan access.
        $subscription = $this->subscriptionService->getActiveForMerchant($user);

        if ($subscription && $subscription->plan && $subscription->plan->ai_usage_limit !== null) {
            return (int) $subscription->plan->ai_usage_limit;
        }

        // Per-user AiSetting monthly override
        if ($setting && $setting->monthly_limit !== null) {
            return (int) $setting->monthly_limit;
        }

        return null;
    }
}
