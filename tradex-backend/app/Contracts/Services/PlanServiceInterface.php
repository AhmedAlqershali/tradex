<?php

namespace App\Contracts\Services;

use App\Models\Plan;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface PlanServiceInterface
{
    // ── Admin-facing ──────────────────────────────────────────────────────────

    /**
     * Return a paginated list of ALL plans (any status).
     *
     * @param  array{search?: string, status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Find a plan by ID regardless of its status. Returns null if not found.
     */
    public function findById(int $id): ?Plan;

    /**
     * Create a new plan.
     */
    public function create(array $data): Plan;

    /**
     * Update a plan's fields.
     */
    public function update(Plan $plan, array $data): Plan;

    /**
     * Delete a plan.
     */
    public function delete(Plan $plan): void;

    // ── Merchant-facing ──────────────────────────────────────────────────────

    /**
     * All active plans available for a merchant to choose from.
     */
    public function listActive(): Collection;
}
