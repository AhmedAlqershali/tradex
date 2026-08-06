<?php

namespace App\Exceptions;

use RuntimeException;

class CategoryException extends RuntimeException
{
    /**
     * Thrown when an admin attempts to delete a category that still has
     * products assigned to it. The caller should surface this as a 409.
     */
    public static function hasProducts(string $categoryName, int $count): self
    {
        return new self(
            "Cannot delete '{$categoryName}': it has {$count} product(s) assigned. " .
            'Reassign or remove those products before deleting the category.'
        );
    }
}
