<?php

namespace App\Policies;

use App\Models\Plan;
use App\Models\User;

/**
 * Governs plan management.
 *
 * Roles:
 *  - admin    : full CRUD over plans
 *  - merchant : may browse active plans via a separate, unguarded
 *               index endpoint (Merchant\PlanController) — no policy
 *               object involved, since it is a simple read of active
 *               plans and carries no per-record ownership concept
 *  - client   : no access
 *
 * Auto-discovered by Laravel: App\Models\Plan → App\Policies\PlanPolicy.
 */
class PlanPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    public function view(User $user, Plan $plan): bool
    {
        return $user->isAdmin();
    }

    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    public function update(User $user, Plan $plan): bool
    {
        return $user->isAdmin();
    }

    public function delete(User $user, Plan $plan): bool
    {
        return $user->isAdmin();
    }
}
