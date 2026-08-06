<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Contracts\Services\UserManagementServiceInterface;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Admin\UpdateUserRoleRequest;
use App\Http\Requests\Admin\UpdateUserStatusRequest;
use App\Http\Resources\User\UserCollection;
use App\Http\Resources\User\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin User Management
 *
 * All routes are behind auth:sanctum + role:admin middleware.
 *
 * GET /api/v1/admin/users              — paginated list with search/filter
 * GET /api/v1/admin/users/{id}         — view a single user
 * PUT /api/v1/admin/users/{id}/status  — activate / deactivate / ban
 * PUT /api/v1/admin/users/{id}/role    — change user role
 */
class UserController extends BaseApiController
{
    public function __construct(
        private readonly UserManagementServiceInterface $userService,
    ) {}

    // ── GET /api/v1/admin/users ─────────────────────────────────────────────

    /**
     * Paginated list of all users.
     *
     * Query parameters:
     *   search    string  — partial match on name / email / phone
     *   role      string  — client | merchant | admin
     *   status    string  — active | inactive | banned
     *   per_page  int     — 1–100 (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', User::class);

        $paginator = $this->userService->listUsers(
            $request->only(['search', 'role', 'status', 'per_page']),
        );

        return $this->success(
            (new UserCollection($paginator))->toArray($request),
            'Users retrieved successfully.',
        );
    }

    // ── GET /api/v1/admin/users/{id} ────────────────────────────────────────

    public function show(int $id): JsonResponse
    {
        $user = $this->userService->findById($id);

        if (! $user) {
            return $this->notFound('User not found.');
        }

        $this->authorize('view', $user);

        return $this->success(new UserResource($user), 'User retrieved successfully.');
    }

    // ── PUT /api/v1/admin/users/{id}/status ─────────────────────────────────

    public function updateStatus(UpdateUserStatusRequest $request, int $id): JsonResponse
    {
        $user = $this->userService->findById($id);

        if (! $user) {
            return $this->notFound('User not found.');
        }

        $this->authorize('updateStatus', $user);

        $updated = $this->userService->updateStatus($user, $request->validated('status'));

        return $this->success(new UserResource($updated), 'User status updated successfully.');
    }

    // ── PUT /api/v1/admin/users/{id}/role ───────────────────────────────────

    public function updateRole(UpdateUserRoleRequest $request, int $id): JsonResponse
    {
        $user = $this->userService->findById($id);

        if (! $user) {
            return $this->notFound('User not found.');
        }

        $this->authorize('updateRole', $user);

        $updated = $this->userService->updateRole($user, $request->validated('role'));

        return $this->success(new UserResource($updated), 'User role updated successfully.');
    }

    // ── DELETE /api/v1/admin/users/{id} ─────────────────────────────────────

    /**
     * Permanently delete a user account.
     *
     * An admin cannot delete their own account.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $this->userService->findById($id);

        if (! $user) {
            return $this->notFound('User not found.');
        }

        // Prevent self-deletion before authorization so it returns 422, not 403
        if ($user->id === $request->user()->id) {
            return $this->error('You cannot delete your own account.', 422);
        }

        $this->authorize('delete', $user);

        $this->userService->deleteUser($user);

        return $this->success(null, 'User deleted successfully.');
    }
}
