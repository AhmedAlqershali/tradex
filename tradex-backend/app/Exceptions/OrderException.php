<?php

namespace App\Exceptions;

use RuntimeException;

class OrderException extends RuntimeException
{
    public static function invalidStatusTransition(string $from, string $to): self
    {
        return new self("Cannot transition order from '{$from}' to '{$to}'.");
    }

    public static function invalidStatusFilter(string $status): self
    {
        return new self("Unknown order status filter: '{$status}'.");
    }

    /**
     * Thrown when a client tries to cancel an order that is no longer
     * in a cancellable state (i.e., status is not 'pending_review').
     */
    public static function notCancellableByClient(string $currentStatus): self
    {
        return new self(
            "Order cannot be cancelled. Only pending-review orders may be cancelled by the client. Current status: '{$currentStatus}'."
        );
    }

    /**
     * Thrown at checkout time when a product's available stock is lower
     * than the quantity requested (checked under a row lock to prevent
     * race conditions between concurrent checkouts).
     */
    public static function insufficientStock(string $productName, int $available, int $requested): self
    {
        return new self(
            "Insufficient stock for '{$productName}'. Available: {$available}, requested: {$requested}."
        );
    }
}
