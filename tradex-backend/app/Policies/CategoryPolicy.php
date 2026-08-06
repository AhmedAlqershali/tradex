<?php

namespace App\Policies;

use App\Models\Category;
use App\Models\User;

/**
 * Governs admin access to category management.
 *
 * Only admins may manage categories. All operations are blocked for
 * merchants and clients — they use the public read-only endpoint instead.
 *
 * Auto-discovered by Laravel: App\Models\Category → App\Policies\CategoryPolicy.
 */
class CategoryPolicy
{
    /**
     * List all categories (admin dashboard view).
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * View a single category record.
     */
    public function view(User $user, Category $category): bool
    {
        return $user->isAdmin();
    }

    /**
     * Create a new category.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Update an existing category.
     */
    public function update(User $user, Category $category): bool
    {
        return $user->isAdmin();
    }

    /**
     * Delete a category.
     */
    public function delete(User $user, Category $category): bool
    {
        return $user->isAdmin();
    }
}
