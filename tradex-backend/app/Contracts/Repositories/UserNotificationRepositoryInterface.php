<?php

namespace App\Contracts\Repositories;

use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface UserNotificationRepositoryInterface
{
    public function listForUser(User $user, int $perPage = 20): LengthAwarePaginator;

    public function unreadCount(User $user): int;

    public function findForUser(User $user, int $id): ?UserNotification;

    public function markAllRead(User $user): int;
}