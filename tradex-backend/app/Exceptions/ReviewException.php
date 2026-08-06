<?php

namespace App\Exceptions;

use Exception;

class ReviewException extends Exception
{
    public static function alreadyReviewed(): self
    {
        return new self('You have already reviewed this product.');
    }

    public static function notOwner(): self
    {
        return new self('You can only delete your own reviews.');
    }

    public static function productNotFound(): self
    {
        return new self('Product not found or not available for reviews.');
    }
}
