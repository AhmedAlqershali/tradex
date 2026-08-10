<?php

namespace App\Contracts\Services;

use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface UserNotificationServiceInterface
{
    public function listForUser(User $user, int $perPage = 20): LengthAwarePaginator;

    public function create(
        User $user,
        string $type,
        string $title,
        string $message,
        array $data = [],
    ): UserNotification;

    public function markRead(User $user, int $id): UserNotification;

    public function markAllRead(User $user): int;
}