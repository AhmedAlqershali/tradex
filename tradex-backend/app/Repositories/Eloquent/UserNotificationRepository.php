<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\UserNotificationRepositoryInterface;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class UserNotificationRepository implements UserNotificationRepositoryInterface
{
    public function listForUser(User $user, int $perPage = 20): LengthAwarePaginator
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->latest()
            ->paginate($perPage)
            ->withQueryString();
    }

    public function unreadCount(User $user): int
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();
    }

    public function findForUser(User $user, int $id): ?UserNotification
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->whereKey($id)
            ->first();
    }

    public function markAllRead(User $user): int
    {
        return UserNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now(), 'updated_at' => now()]);
    }
}