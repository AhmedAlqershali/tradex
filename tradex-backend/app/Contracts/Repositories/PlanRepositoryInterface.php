<?php

namespace App\Contracts\Repositories;

use App\Models\Plan;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface PlanRepositoryInterface
{
    /**
     * Paginated list of ALL plans (any status) — admin use.
     *
     * @param  array{search?: string, status?: string, per_page?: int}  $filters
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * All active plans, ordered for display — merchant plan-selection use.
     */
    public function listActive(): Collection;

    /**
     * Find a plan by primary key regardless of status.
     */
    public function findById(int $id): ?Plan;

    /**
     * Persist a new plan record and return it.
     */
    public function create(array $data): Plan;

    /**
     * Update a plan and return the refreshed record.
     */
    public function update(Plan $plan, array $data): Plan;

    /**
     * Permanently delete a plan.
     */
    public function delete(Plan $plan): bool;
}
