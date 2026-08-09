<?php

namespace App\Services;

use App\Contracts\Repositories\SubscriptionRepositoryInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;

class SubscriptionService implements SubscriptionServiceInterface
{
    public const TRIAL_PLAN_NAME = 'free_trial';
    public const TRIAL_DAYS = 14;

    public function __construct(
        private readonly SubscriptionRepositoryInterface $subscriptionRepository,
    ) {}

    public function getActiveForMerchant(User $merchant): ?Subscription
    {
        $subscription = $this->getCurrentForMerchant($merchant);

        return $subscription?->isEntitled() ? $subscription : null;
    }

    public function getCurrentForMerchant(User $merchant): ?Subscription
    {
        $subscription = $this->subscriptionRepository->findLatestForUser($merchant);

        if (
            $subscription
            && $subscription->status === 'active'
            && $subscription->ends_at !== null
            && $subscription->ends_at->isPast()
        ) {
            $subscription = $this->subscriptionRepository->markExpired($subscription);
        }

        return $subscription;
    }

    public function startTrial(User $merchant): Subscription
    {
        $existing = $this->getCurrentForMerchant($merchant);

        if ($existing) {
            return $existing;
        }

        $startsAt = now();
        $trialPlan = Plan::firstOrCreate(
            ['name' => self::TRIAL_PLAN_NAME],
            [
                'display_name'   => 'Free Trial',
                'monthly_price'  => 0,
                'yearly_price'   => 0,
                'ai_usage_limit' => null,
                'product_limit'  => null,
                'store_limit'    => 1,
                'features'       => ['trial' => true],
                'status'         => 'active',
            ],
        );

        return $this->subscriptionRepository->create([
            'user_id'       => $merchant->id,
            'plan_id'       => $trialPlan->id,
            'billing_cycle' => 'monthly',
            'type'          => 'trial',
            'status'        => 'active',
            'starts_at'     => $startsAt,
            'ends_at'       => $startsAt->copy()->addDays(self::TRIAL_DAYS),
        ]);
    }

    /**
     * Cancel any existing active subscription and create a new active one.
     *
     * Called from within SubscriptionRequestService::approve(), which owns
     * the surrounding DB transaction.
     */
    public function activateForMerchant(User $merchant, Plan $plan, string $billingCycle): Subscription
    {
        $this->subscriptionRepository->cancelActiveForUser($merchant);

        return $this->subscriptionRepository->create([
            'user_id'       => $merchant->id,
            'plan_id'       => $plan->id,
            'billing_cycle' => $billingCycle,
            'type'          => 'paid',
            'status'        => 'active',
            'starts_at'     => now(),
            'ends_at'       => $billingCycle === 'yearly'
                ? now()->addYear()
                : now()->addMonth(),
        ]);
    }
}
