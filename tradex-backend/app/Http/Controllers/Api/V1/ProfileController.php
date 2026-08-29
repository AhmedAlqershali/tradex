<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Services\ProfileServiceInterface;
use App\Http\Requests\Profile\ChangePasswordRequest;
use App\Http\Requests\Profile\UpdateProfileRequest;
use App\Models\AiRequest;
use App\Models\AiSetting;
use App\Models\AiUsage;
use App\Models\UserDeviceToken;
use App\Models\UserNotification;
use App\Support\AvatarTrace;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
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

    // ── DELETE /api/v1/profile ────────────────────────────────────────────────

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();

        DB::transaction(function () use ($user) {
            // Revoke every Sanctum token owned by this user before the account is
            // removed so the API rejects any still-cached client session.
            $user->tokens()->delete();

            // Explicitly remove user-owned personal records that are not covered by
            // a cascade path or that must be cleaned before the user record vanishes.
            UserDeviceToken::where('user_id', $user->id)->delete();
            UserNotification::where('user_id', $user->id)->delete();
            AiUsage::where('user_id', $user->id)->delete();
            AiRequest::where('user_id', $user->id)->delete();
            AiSetting::where('user_id', $user->id)->delete();
            DB::table('sessions')->where('user_id', $user->id)->delete();

            if ($user->avatar && Storage::disk('public')->exists($user->avatar)) {
                Storage::disk('public')->delete($user->avatar);
            }

            // Merchant-owned stores, products, favorites, carts, orders, and the
            // related foreign-key tables are left to the existing database cascade
            // rules. This preserves unrelated global catalog data while removing the
            // deleting user's personal data and current credentials.
            $user->delete();
        });

        return $this->success(null, 'Account deleted successfully.');
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
