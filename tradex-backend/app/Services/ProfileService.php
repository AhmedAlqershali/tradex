<?php

namespace App\Services;

use App\Contracts\Services\ProfileServiceInterface;
use App\Models\Store;
use App\Models\User;
use App\Support\AvatarTrace;
use App\Support\PublicMediaUrl;
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
        AvatarTrace::database('before_upload', $oldPath);
        AvatarTrace::received($file);

        $cloudinaryDisk = Storage::disk('cloudinary');
        $storedPath = $cloudinaryDisk->putFileAs('avatars', $file, $file->hashName());

        if ($storedPath === false) {
            throw new \RuntimeException('User avatar could not be persisted.');
        }

        $url = $cloudinaryDisk->url($storedPath);

        if (! is_string($url) || trim($url) === '') {
            throw new \RuntimeException('User avatar URL could not be generated.');
        }

        try {
            $user->update(['avatar' => $url]);
        } catch (\Throwable $exception) {
            // Do not leave an orphaned Cloudinary upload when the database write fails.
            $cloudinaryDisk->delete($storedPath);
            throw $exception;
        }

        // Remove only legacy local uploaded avatars after persisting the replacement.
        if ($oldPath && $oldPath !== $url) {
            $this->deleteLegacyAvatarIfExists($oldPath);
        }

        AvatarTrace::stored($url);
        $freshUser = $user->fresh(['stores']);
        AvatarTrace::database('after_upload', $freshUser->avatar);
        $payload = $this->userPayload($freshUser);
        AvatarTrace::response($payload['avatar'] ?? null);

        return $payload;
    }

    private function deleteLegacyAvatarIfExists(?string $path): void
    {
        if (! is_string($path) || trim($path) === '') {
            return;
        }

        if (preg_match('#^https?://#i', $path) === 1) {
            return;
        }

        $publicPath = preg_replace('#^/?storage/?#i', '', $path);
        $publicPath = preg_replace('#^/+#', '', $publicPath);

        if ($publicPath === '' || $publicPath === 'storage') {
            return;
        }

        if (Storage::disk('public')->exists($publicPath)) {
            Storage::disk('public')->delete($publicPath);
        }
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
                'logo'        => PublicMediaUrl::forPath($s->logo),
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

        return PublicMediaUrl::forPath($path);
    }
}
