<?php

namespace App\Contracts\Services;

use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface UserManagementServiceInterface
{
    /**
     * Paginated user list with optional search (name/email/phone),
     * role filter, and status filter.
     */
    public function listUsers(array $filters): LengthAwarePaginator;

    /**
     * Find a single user by ID; returns null if not found.
     */
    public function findById(int $id): ?User;

    /**
     * Update a user's status (active | inactive | banned).
     */
    public function updateStatus(User $user, string $status): User;

    /**
     * Update a user's role (client | merchant | admin).
     */
    public function updateRole(User $user, string $role): User;

    /**
     * Permanently delete a user and all their associated data.
     */
    public function deleteUser(User $user): void;
}
