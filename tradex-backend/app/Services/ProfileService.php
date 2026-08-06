<?php

namespace App\Services;

use App\Contracts\Services\ProfileServiceInterface;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ProfileService implements ProfileServiceInterface
{
    public function getProfile(User $user): array
    {
        $user = $user->fresh(['stores']);
        return $this->userPayload($user);
    }

    public function updateProfile(User $user, array $data): array
    {
        // Guard against email conflict with another user
        if (isset($data['email']) && $data['email'] !== $user->email) {
            $exists = User::where('email', $data['email'])
                ->where('id', '!=', $user->id)
                ->exists();

            if ($exists) {
                throw ValidationException::withMessages([
                    'email' => ['This email address is already taken.'],
                ]);
            }
        }

        $user->update(array_filter([
            'name'  => $data['name']  ?? null,
            'email' => $data['email'] ?? null,
            'phone' => $data['phone'] ?? null,
        ], fn ($v) => ! is_null($v)));

        return $this->userPayload($user->fresh(['stores']));
    }

    public function changePassword(User $user, string $currentPassword, string $newPassword): void
    {
        if (! Hash::check($currentPassword, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['The current password is incorrect.'],
            ]);
        }

        $user->update(['password' => Hash::make($newPassword)]);
    }

    public function updateAvatar(User $user, UploadedFile $file): array
    {
        // Delete the old avatar if it exists
        if ($user->avatar && Storage::disk('public')->exists($user->avatar)) {
            Storage::disk('public')->delete($user->avatar);
        }

        $path = $file->store('avatars', 'public');

        $user->update(['avatar' => $path]);

        return $this->userPayload($user->fresh(['stores']));
    }

    // ── Payload helpers ───────────────────────────────────────────────────────

    private function userPayload(User $user): array
    {
        $payload = [
            'id'     => $user->id,
            'name'   => $user->name,
            'email'  => $user->email,
            'phone'  => $user->phone,
            'role'   => $user->role,
            'avatar' => $user->avatar
                ? Storage::disk('public')->url($user->avatar)
                : null,
        ];

        if ($user->isMerchant() && $user->relationLoaded('stores')) {
            $payload['stores'] = $user->stores->map(fn (Store $s) => [
                'id'          => $s->id,
                'store_name'  => $s->store_name,
                'description' => $s->description,
                'logo'        => $s->logo,
                'status'      => $s->status,
            ])->values();
        }

        return $payload;
    }
}
