<?php

namespace App\Services;

use App\Contracts\Services\UserManagementServiceInterface;
use App\Models\AiRequest;
use App\Models\AiSetting;
use App\Models\AiUsage;
use App\Models\User;
use App\Models\UserDeviceToken;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Kreait\Firebase\Factory;
use Throwable;

class UserManagementService implements UserManagementServiceInterface
{
    /** Allowed values for the status column. */
    public const STATUSES = ['active', 'inactive', 'banned'];

    /** Allowed values for the role column. */
    public const ROLES = ['client', 'merchant', 'admin'];

    // -------------------------------------------------------------------------
    // Queries
    // -------------------------------------------------------------------------

    public function listUsers(array $filters): LengthAwarePaginator
    {
        $query = User::query();

        // Full-text search across name, email, and phone
        if (! empty($filters['search'])) {
            $term = '%' . $filters['search'] . '%';
            $query->where(function ($q) use ($term) {
                $q->where('name',  'like', $term)
                  ->orWhere('email', 'like', $term)
                  ->orWhere('phone', 'like', $term);
            });
        }

        if (! empty($filters['role']) && in_array($filters['role'], self::ROLES, true)) {
            $query->where('role', $filters['role']);
        }

        if (! empty($filters['status']) && in_array($filters['status'], self::STATUSES, true)) {
            $query->where('status', $filters['status']);
        }

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        // Eager-load stores for merchants only to avoid N+1
        return $query->with([
                'stores:id,user_id,store_name,status',
                'subscriptions.plan',
            ])
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findById(int $id): ?User
    {
        return User::with(['stores', 'subscriptions.plan'])->find($id);
    }

    // -------------------------------------------------------------------------
    // Mutations
    // -------------------------------------------------------------------------

    /**
     * Update a user's status.
     *
     * SECURITY: `status` is excluded from User::$fillable; use direct attribute
     * assignment + save() to prevent mass-assignment while still allowing this
     * trusted admin-only service to change the field.
     */
    public function updateStatus(User $user, string $status): User
    {
        $user->status = $status;
        $user->save();

        // Immediately invalidate all Sanctum tokens when a user is banned
        // or deactivated, so they cannot continue using the API with existing
        // credentials. If the ban is later lifted, they simply log in again.
        if (in_array($status, ['banned', 'inactive'], true)) {
            $user->tokens()->delete();
        }

        return $user->fresh();
    }

    /**
     * Update a user's role.
     *
     * SECURITY: `role` is excluded from User::$fillable; use direct attribute
     * assignment + save() to prevent mass-assignment while still allowing this
     * trusted admin-only service to change the field.
     */
    public function updateRole(User $user, string $role): User
    {
        $user->role = $role;
        $user->save();

        return $user->fresh(['stores']);
    }

    /**
     * Permanently delete a user account and all associated data.
     *
     * The deletion is intentionally explicit so personal user-owned records are
     * removed before the user row itself disappears, while preserving unrelated
     * catalog/global data that is not owned by the user.
     */
    public function deleteUser(User $user): void
    {
        $storagePaths = $this->ownedStoragePaths($user);

        $firebaseFailure = $this->deleteFirebaseAccount($user);
        if ($firebaseFailure !== null) {
            Log::error('User deletion blocked because Firebase cleanup failed.', [
                'user_id' => $user->id,
                'failure' => $firebaseFailure,
            ]);

            throw new \RuntimeException('The account could not be deleted because its Firebase account could not be removed. Please contact support.');
        }

        DB::transaction(function () use ($user) {
            $user->tokens()->delete();
            UserDeviceToken::where('user_id', $user->id)->delete();
            UserNotification::where('user_id', $user->id)->delete();
            AiUsage::where('user_id', $user->id)->delete();
            AiRequest::where('user_id', $user->id)->delete();
            AiSetting::where('user_id', $user->id)->delete();
            DB::table('sessions')->where('user_id', $user->id)->delete();

            $user->delete();
        });

        $failures = $this->deleteStoragePaths($storagePaths);

        if ($failures !== []) {
            Log::error('User deletion completed with external cleanup failures.', [
                'user_id' => $user->id,
                'failures' => $failures,
            ]);

            throw new \RuntimeException('The account was removed, but some external resources could not be cleaned up. Please contact support.');
        }
    }

    /** @return array{public: string[], local: string[]} */
    private function ownedStoragePaths(User $user): array
    {
        $public = array_filter([$user->avatar]);
        $local = [];
        $user->loadMissing(['stores.products.images', 'subscriptionRequests']);

        foreach ($user->stores as $store) {
            $public[] = $store->logo;
            foreach ($store->products as $product) {
                $public[] = $product->image;
                foreach ($product->images as $image) {
                    $public[] = $image->path;
                }
            }
        }

        foreach ($user->subscriptionRequests as $request) {
            $local[] = $request->payment_proof_image;
        }

        return [
            'public' => array_values(array_filter(array_unique($public))),
            'local' => array_values(array_filter(array_unique($local))),
        ];
    }

    /** @param array{public: string[], local: string[]} $paths */
    private function deleteStoragePaths(array $paths): array
    {
        $failures = [];
        foreach (['public' => 'public', 'local' => 'local'] as $group => $diskName) {
            $disk = Storage::disk($diskName);
            foreach ($paths[$group] as $path) {
                try {
                    if ($disk->exists($path) && ! $disk->delete($path)) {
                        $failures[] = "{$diskName}:{$path}";
                    }
                } catch (Throwable $exception) {
                    $failures[] = "{$diskName}:{$path} ({$exception->getMessage()})";
                }
            }
        }

        return $failures;
    }

    private function deleteFirebaseAccount(User $user): ?string
    {
        $credentials = config('services.firebase.credentials');
        if (! $credentials) {
            return app()->environment('testing')
                ? null
                : "firebase:{$user->email} (Firebase credentials are not configured)";
        }

        try {
            $auth = (new Factory())->withServiceAccount($credentials)->createAuth();
            $firebaseUser = $auth->getUserByEmail($user->email);
            $auth->deleteUser($firebaseUser->uid);
        } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $exception) {
            return null;
        } catch (Throwable $exception) {
            return "firebase:{$user->email} ({$exception->getMessage()})";
        }

        return null;
    }
}
