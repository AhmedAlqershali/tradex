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

        // Use array_key_exists instead of array_filter so a client can
        // intentionally clear the nullable phone field. Only fields sent by
        // the client are changed; omitted fields remain untouched.
        $updates = [];
        foreach ([
            'name',
            'email',
            'phone',
            'region',
            'location_name',
            'latitude',
            'longitude',
        ] as $field) {
            if (array_key_exists($field, $data)) {
                $updates[$field] = $data[$field];
            }
        }

        if ($updates !== []) {
            $user->update($updates);
        }

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
        $oldPath = $user->avatar;
        $path = $file->store('avatars', 'public');

        try {
            $user->update(['avatar' => $path]);
        } catch (\Throwable $exception) {
            // Do not leave an orphaned upload when the database write fails.
            Storage::disk('public')->delete($path);
            throw $exception;
        }

        // Remove the previous file only after the new reference is persisted.
        // This keeps the existing valid avatar available if storage or the
        // database rejects the replacement.
        if ($oldPath && $oldPath !== $path && Storage::disk('public')->exists($oldPath)) {
            Storage::disk('public')->delete($oldPath);
        }

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
            'region' => $user->region,
            'location_name' => $user->location_name,
            'latitude' => $user->latitude,
            'longitude' => $user->longitude,
            'role'   => $user->role,
            'created_at' => $user->created_at?->toIso8601String(),
            'avatar' => $this->avatarUrl($user->avatar),
        ];

        if ($user->isMerchant() && $user->relationLoaded('stores')) {
            $payload['stores'] = $user->stores->map(fn (Store $s) => [
                'id'          => $s->id,
                'store_name'  => $s->store_name,
                'description' => $s->description,
                'region'      => $s->region,
                'logo'        => $s->logo
                    ? Storage::disk('public')->url($s->logo)
                    : null,
                'status'      => $s->status,
            ])->values();
        }

        return $payload;
    }

    /**
     * Return an absolute URL for the public avatar.
     *
     * Storage::url() uses the configured APP_URL, which is commonly left at
     * Laravel's localhost default in local/Replit processes. Building the
     * public path through Laravel's URL generator keeps the response absolute
     * while using the current request host when one is available.
     */
    private function avatarUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return url('/storage/'.ltrim($path, '/'));
    }
}
