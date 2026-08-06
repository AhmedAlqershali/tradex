<?php

namespace App\Exceptions;

use RuntimeException;

class CartException extends RuntimeException
{
    public static function productUnavailable(string $productName): self
    {
        return new self("'{$productName}' is not available for purchase.");
    }

    public static function cartEmpty(): self
    {
        return new self('Your cart is empty. Add products before checking out.');
    }

    public static function insufficientStock(string $productName, int $available, int $requested): self
    {
        return new self(
            "Insufficient stock for '{$productName}'. "
            . "Requested: {$requested}, available: {$available}."
        );
    }
}
