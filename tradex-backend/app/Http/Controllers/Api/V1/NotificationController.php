<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Services\UserNotificationServiceInterface;
use App\Http\Resources\UserNotificationResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends BaseApiController
{
    public function __construct(
        private readonly UserNotificationServiceInterface $notificationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $page = $this->notificationService->listForUser(
            $request->user(),
            (int) $request->input('per_page', 20),
        );

        return $this->success([
            'data'       => UserNotificationResource::collection($page->getCollection()),
            'pagination' => [
                'total'        => $page->total(),
                'per_page'     => $page->perPage(),
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'from'         => $page->firstItem(),
                'to'           => $page->lastItem(),
            ],
            'unread_count' => $this->notificationService->unreadCount($request->user()),
        ], 'Notifications retrieved successfully.');
    }

    public function markRead(Request $request, int $id): JsonResponse
    {
        try {
            $notification = $this->notificationService->markRead(
                $request->user(),
                $id,
            );
        } catch (ModelNotFoundException) {
            return $this->notFound('Notification not found.');
        }

        return $this->success(
            new UserNotificationResource($notification),
            'Notification marked as read.',
        );
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $count = $this->notificationService->markAllRead($request->user());

        return $this->success(
            ['updated_count' => $count],
            'All notifications marked as read.',
        );
    }
}