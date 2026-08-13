<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Services\ProfileServiceInterface;
use App\Http\Requests\Profile\ChangePasswordRequest;
use App\Http\Requests\Profile\UpdateProfileRequest;
use App\Support\AvatarTrace;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/**
 * Profile management — available to all authenticated roles.
 *
 * All routes require auth:sanctum.
 * GET  /api/v1/profile
 * PUT  /api/v1/profile
 * PUT  /api/v1/profile/password
 * POST /api/v1/profile/avatar
 */
class ProfileController extends BaseApiController
{
    public function __construct(
        private readonly ProfileServiceInterface $profileService,
    ) {}

    // ── GET /api/v1/profile ───────────────────────────────────────────────────

    public function show(Request $request): JsonResponse
    {
        return $this->success(
            $this->profileService->getProfile($request->user()),
            'Profile retrieved successfully.',
        );
    }

    // ── PUT /api/v1/profile ───────────────────────────────────────────────────

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        try {
            $profile = $this->profileService->updateProfile($request->user(), $request->validated());
        } catch (ValidationException $e) {
            return $this->validationError($e->errors(), 'Profile update failed.');
        }

        return $this->success($profile, 'Profile updated successfully.');
    }

    // ── PUT /api/v1/profile/password ──────────────────────────────────────────

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        try {
            $this->profileService->changePassword(
                $request->user(),
                $request->validated('current_password'),
                $request->validated('new_password'),
            );
        } catch (ValidationException $e) {
            return $this->validationError($e->errors(), 'Password change failed.');
        }

        return $this->success(null, 'Password changed successfully.');
    }

    // ── POST /api/v1/profile/avatar ───────────────────────────────────────────

    public function updateAvatar(Request $request): JsonResponse
    {
        AvatarTrace::begin();

        try {
            try {
                $request->validate([
                    'avatar' => ['required', 'image', 'mimes:jpeg,jpg,png,webp', 'max:2048'],
                ]);
                AvatarTrace::validation(true);
            } catch (ValidationException $exception) {
                AvatarTrace::validation(false);
                throw $exception;
            }

            $profile = $this->profileService->updateAvatar(
                $request->user(),
                $request->file('avatar'),
            );
            AvatarTrace::response($profile['avatar'] ?? null);

            return $this->success($profile, 'Avatar updated successfully.');
        } finally {
            AvatarTrace::end();
        }
    }
}
