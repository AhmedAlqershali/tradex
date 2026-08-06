<?php

namespace App\Services;

use App\Contracts\Repositories\SubscriptionRepositoryInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;

class SubscriptionService implements SubscriptionServiceInterface
{
    public function __construct(
        private readonly SubscriptionRepositoryInterface $subscriptionRepository,
    ) {}

    public function getActiveForMerchant(User $merchant): ?Subscription
    {
        return $this->subscriptionRepository->findActiveForUser($merchant);
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
            'status'        => 'active',
            'starts_at'     => now(),
            'ends_at'       => $billingCycle === 'yearly'
                ? now()->addYear()
                : now()->addMonth(),
        ]);
    }
}
