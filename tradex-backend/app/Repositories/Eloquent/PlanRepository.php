<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\PlanRepositoryInterface;
use App\Models\Plan;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

class PlanRepository implements PlanRepositoryInterface
{
    /**
     * Paginated list of ALL plans — for admin management.
     *
     * Supported filters:
     *   search   — partial match on name / display_name
     *   status   — exact match (active | inactive)
     *   per_page — 1–100 (default: 20)
     */
    public function listAll(array $filters): LengthAwarePaginator
    {
        $query = Plan::query();

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', '%' . $search . '%')
                    ->orWhere('display_name', 'like', '%' . $search . '%');
            });
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 20), 100);

        return $query->orderBy('monthly_price')->paginate($perPage)->withQueryString();
    }

    /**
     * All active plans, cheapest first — for merchant plan selection.
     */
    public function listActive(): Collection
    {
        return Plan::active()->orderBy('monthly_price')->get();
    }

    /**
     * Find a plan by ID regardless of its status.
     */
    public function findById(int $id): ?Plan
    {
        return Plan::find($id);
    }

    /**
     * Create a new plan record.
     */
    public function create(array $data): Plan
    {
        return Plan::create($data);
    }

    /**
     * Update a plan and return the refreshed record.
     */
    public function update(Plan $plan, array $data): Plan
    {
        $plan->update($data);

        return $plan->fresh();
    }

    /**
     * Permanently delete a plan record.
     */
    public function delete(Plan $plan): bool
    {
        return (bool) $plan->delete();
    }
}
