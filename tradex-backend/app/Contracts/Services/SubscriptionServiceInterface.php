<?php

namespace App\Contracts\Services;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;

interface SubscriptionServiceInterface
{
    /**
     * The merchant's current active subscription, if any.
     */
    public function getActiveForMerchant(User $merchant): ?Subscription;

    /**
     * The latest trial or paid period, including an expired period.
     */
    public function getCurrentForMerchant(User $merchant): ?Subscription;

    /**
     * Create the merchant's initial 14-day trial.
     */
    public function startTrial(User $merchant): Subscription;

    /**
     * Activate a plan for a merchant.
     *
     * Any currently active subscription is cancelled (history preserved,
     * not deleted) and a new active subscription row is created.
     * Intended to be called from within a DB transaction by the caller
     * (SubscriptionRequestService, on approval).
     */
    public function activateForMerchant(User $merchant, Plan $plan, string $billingCycle): Subscription;
}
