<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\PlanServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Plan\StorePlanRequest;
use App\Http\Requests\Plan\UpdatePlanRequest;
use App\Http\Resources\Plan\PlanCollection;
use App\Http\Resources\Plan\PlanResource;
use App\Models\Plan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin plan management (SaaS Subscription Foundation — Phase 3 Step 1).
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 * Full CRUD — list, create, view, update, delete.
 *
 * GET    /api/v1/admin/plans       — list all (any status)
 * POST   /api/v1/admin/plans       — create
 * GET    /api/v1/admin/plans/{id}  — show
 * PUT    /api/v1/admin/plans/{id}  — update
 * DELETE /api/v1/admin/plans/{id}  — delete
 */
class PlanController extends BaseApiController
{
    public function __construct(
        private readonly PlanServiceInterface $planService,
    ) {}

    // ── GET /api/v1/admin/plans ─────────────────────────────────────────────

    /**
     * List all plans across all statuses.
     *
     * Query parameters:
     *   search    string  — partial match on name / display_name
     *   status    string  — active | inactive
     *   per_page  int     — 1–100 (default: 20)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Plan::class);

        $filters   = $request->only(['search', 'status', 'per_page']);
        $paginator = $this->planService->listAll($filters);

        return $this->success(
            (new PlanCollection($paginator))->toArray($request),
            'Plans retrieved successfully.',
        );
    }

    // ── POST /api/v1/admin/plans ────────────────────────────────────────────

    /**
     * Create a new plan.
     */
    public function store(StorePlanRequest $request): JsonResponse
    {
        $this->authorize('create', Plan::class);

        $plan = $this->planService->create($request->validated());

        return $this->created(new PlanResource($plan), 'Plan created successfully.');
    }

    // ── GET /api/v1/admin/plans/{id} ────────────────────────────────────────

    /**
     * Show a single plan by ID.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $plan = $this->planService->findById($id);

        if (! $plan) {
            return $this->notFound('Plan not found.');
        }

        $this->authorize('view', $plan);

        return $this->success(new PlanResource($plan), 'Plan retrieved successfully.');
    }

    // ── PUT /api/v1/admin/plans/{id} ────────────────────────────────────────

    /**
     * Update a plan's fields.
     */
    public function update(UpdatePlanRequest $request, int $id): JsonResponse
    {
        $plan = $this->planService->findById($id);

        if (! $plan) {
            return $this->notFound('Plan not found.');
        }

        $this->authorize('update', $plan);

        $updated = $this->planService->update($plan, $request->validated());

        return $this->success(new PlanResource($updated), 'Plan updated successfully.');
    }

    // ── DELETE /api/v1/admin/plans/{id} ─────────────────────────────────────

    /**
     * Delete a plan.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $plan = $this->planService->findById($id);

        if (! $plan) {
            return $this->notFound('Plan not found.');
        }

        $this->authorize('delete', $plan);

        $this->planService->delete($plan);

        return $this->success(null, 'Plan deleted successfully.');
    }
}
