<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\SubscriptionRepositoryInterface;
use App\Models\Subscription;
use App\Models\User;

class SubscriptionRepository implements SubscriptionRepositoryInterface
{
    /**
     * Find the merchant's current active subscription (latest first).
     */
    public function findActiveForUser(User $user): ?Subscription
    {
        return Subscription::where('user_id', $user->id)
            ->where('status', 'active')
            ->with('plan')
            ->latest('starts_at')
            ->first();
    }

    public function findLatestForUser(User $user): ?Subscription
    {
        return Subscription::where('user_id', $user->id)
            ->with('plan')
            ->latest('starts_at')
            ->first();
    }

    public function markExpired(Subscription $subscription): Subscription
    {
        $subscription->forceFill(['status' => 'expired'])->save();

        return $subscription->fresh('plan');
    }

    /**
     * Mark all active subscription rows for the user as cancelled.
     * Rows are kept (not deleted) so subscription history is preserved.
     */
    public function cancelActiveForUser(User $user): void
    {
        Subscription::where('user_id', $user->id)
            ->where('status', 'active')
            ->update([
                'status'       => 'cancelled',
                'cancelled_at' => now(),
            ]);
    }

    /**
     * Create a new subscription record.
     */
    public function create(array $data): Subscription
    {
        return Subscription::create($data);
    }
}
