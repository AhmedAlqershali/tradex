<?php

namespace App\Policies;

use App\Models\User;

/**
 * Authorization rules for admin user-management endpoints.
 *
 * The EnsureRole middleware already blocks non-admins from reaching
 * admin routes, so these policies act as a second, model-level defence.
 */
class UserPolicy
{
    /**
     * Any admin may list users.
     */
    public function viewAny(User $admin): bool
    {
        return $admin->isAdmin();
    }

    /**
     * Any admin may view an individual user profile.
     */
    public function view(User $admin, User $target): bool
    {
        return $admin->isAdmin();
    }

    /**
     * Admin may change a user's status, but cannot change their own status
     * or another admin's status.
     */
    public function updateStatus(User $admin, User $target): bool
    {
        return $admin->isAdmin()
            && $admin->id !== $target->id
            && ! $target->isAdmin();
    }

    /**
     * Admin may change a user's role, but cannot change their own role
     * or another admin's role.
     */
    public function updateRole(User $admin, User $target): bool
    {
        return $admin->isAdmin()
            && $admin->id !== $target->id
            && ! $target->isAdmin();
    }

    /**
     * Admin may delete a user, but not themselves or another admin.
     */
    public function delete(User $admin, User $target): bool
    {
        return $admin->isAdmin()
            && $admin->id !== $target->id
            && ! $target->isAdmin();
    }
}
