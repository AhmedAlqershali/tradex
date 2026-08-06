<?php

namespace App\Exceptions;

use RuntimeException;

class SubscriptionException extends RuntimeException
{
    /**
     * Thrown when a merchant submits a subscription request for a plan
     * that is not currently active. Caller should surface this as a 422.
     */
    public static function planInactive(string $planName): self
    {
        return new self("The '{$planName}' plan is not currently available.");
    }

    /**
     * Thrown when an admin tries to approve/reject a request that has
     * already been reviewed. Caller should surface this as a 409.
     */
    public static function alreadyReviewed(string $status): self
    {
        return new self("This request has already been {$status} and cannot be reviewed again.");
    }

    /**
     * Thrown when a merchant tries to submit a new subscription request
     * while they already have a pending one. Caller should surface this as a 422.
     */
    public static function pendingRequestExists(): self
    {
        return new self('You already have a pending subscription request. Please wait for it to be reviewed.');
    }

    /**
     * Thrown when an admin attempts to delete a plan that still has
     * subscriptions or subscription requests referencing it.
     * Caller should surface this as a 409.
     */
    public static function planInUse(string $planName): self
    {
        return new self(
            "Cannot delete '{$planName}': it has active subscriptions or requests referencing it. " .
            'Deactivate the plan instead of deleting it.'
        );
    }
}
