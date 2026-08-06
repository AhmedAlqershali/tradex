<?php

namespace App\Services;

use App\Contracts\Repositories\PlanRepositoryInterface;
use App\Contracts\Services\PlanServiceInterface;
use App\Exceptions\SubscriptionException;
use App\Models\Plan;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

class PlanService implements PlanServiceInterface
{
    public function __construct(
        private readonly PlanRepositoryInterface $planRepository,
    ) {}

    // ── Admin-facing ──────────────────────────────────────────────────────────

    public function listAll(array $filters): LengthAwarePaginator
    {
        return $this->planRepository->listAll($filters);
    }

    public function findById(int $id): ?Plan
    {
        return $this->planRepository->findById($id);
    }

    public function create(array $data): Plan
    {
        $data['status'] ??= 'active';
        $data['store_limit'] ??= 1;

        return $this->planRepository->create($data);
    }

    public function update(Plan $plan, array $data): Plan
    {
        return $this->planRepository->update($plan, $data);
    }

    /**
     * @throws SubscriptionException  if the plan has subscriptions or requests referencing it
     */
    public function delete(Plan $plan): void
    {
        if ($plan->subscriptions()->exists() || $plan->subscriptionRequests()->exists()) {
            throw SubscriptionException::planInUse($plan->display_name);
        }

        $this->planRepository->delete($plan);
    }

    // ── Merchant-facing ──────────────────────────────────────────────────────

    public function listActive(): Collection
    {
        return $this->planRepository->listActive();
    }
}
