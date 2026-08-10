<?php

namespace App\Services;

use App\Contracts\Repositories\UserNotificationRepositoryInterface;
use App\Contracts\Services\UserNotificationServiceInterface;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UserNotificationService implements UserNotificationServiceInterface
{
    public function __construct(
        private readonly UserNotificationRepositoryInterface $repository,
    ) {}

    public function listForUser(User $user, int $perPage = 20): LengthAwarePaginator
    {
        return $this->repository->listForUser($user, min(max($perPage, 1), 100));
    }

    public function create(
        User $user,
        string $type,
        string $title,
        string $message,
        array $data = [],
    ): UserNotification {
        return UserNotification::create([
            'user_id' => $user->id,
            'type'    => $type,
            'title'   => $title,
            'message' => $message,
            'data'    => $data ?: null,
        ]);
    }

    public function markRead(User $user, int $id): UserNotification
    {
        $notification = $this->repository->findForUser($user, $id);
        if (! $notification) {
            throw new ModelNotFoundException('Notification not found.');
        }

        if (! $notification->read_at) {
            $notification->forceFill(['read_at' => now()])->save();
        }

        return $notification;
    }

    public function markAllRead(User $user): int
    {
        return $this->repository->markAllRead($user);
    }
}