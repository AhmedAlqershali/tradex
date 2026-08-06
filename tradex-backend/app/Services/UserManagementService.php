<?php

namespace App\Services;

use App\Contracts\Services\UserManagementServiceInterface;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class UserManagementService implements UserManagementServiceInterface
{
    /** Allowed values for the status column. */
    public const STATUSES = ['active', 'inactive', 'banned'];

    /** Allowed values for the role column. */
    public const ROLES = ['client', 'merchant', 'admin'];

    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public function listUsers(array $filters): LengthAwarePaginator
    {
        $query = User::query();

        // Full-text search across name, email, and phone
        if (! empty($filters['search'])) {
            $term = '%' . $filters['search'] . '%';
            $query->where(function ($q) use ($term) {
                $q->where('name',  'like', $term)
                  ->orWhere('email', 'like', $term)
                  ->orWhere('phone', 'like', $term);
            });
        }

        if (! empty($filters['role']) && in_array($filters['role'], self::ROLES, true)) {
            $query->where('role', $filters['role']);
        }

        if (! empty($filters['status']) && in_array($filters['status'], self::STATUSES, true)) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        // Eager-load stores for merchants only to avoid N+1
        return $query->with(['stores:id,user_id,store_name,status'])
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findById(int $id): ?User
    {
        return User::with(['stores'])->find($id);
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    /**
     * Update a user's status.
     *
     * SECURITY: `status` is excluded from User::$fillable; use direct attribute
     * assignment + save() to prevent mass-assignment while still allowing this
     * trusted admin-only service to change the field.
     */
    public function updateStatus(User $user, string $status): User
    {
        $user->status = $status;
        $user->save();

        // Immediately invalidate all Sanctum tokens when a user is banned
        // or deactivated, so they cannot continue using the API with existing
        // credentials. If the ban is later lifted, they simply log in again.
        if (in_array($status, ['banned', 'inactive'], true)) {
            $user->tokens()->delete();
        }

        return $user->fresh();
    }

    /**
     * Update a user's role.
     *
     * SECURITY: `role` is excluded from User::$fillable; use direct attribute
     * assignment + save() to prevent mass-assignment while still allowing this
     * trusted admin-only service to change the field.
     */
    public function updateRole(User $user, string $role): User
    {
        $user->role = $role;
        $user->save();

        return $user->fresh(['stores']);
    }

    /**
     * Permanently delete a user account and all associated data.
     *
     * Cascading FK deletes handle: stores → products/images, orders,
     * favorites, cart, subscriptions, tokens.
     */
    public function deleteUser(User $user): void
    {
        // Revoke all tokens before deleting to avoid orphaned token lookups
        $user->tokens()->delete();
        $user->delete();
    }
}
