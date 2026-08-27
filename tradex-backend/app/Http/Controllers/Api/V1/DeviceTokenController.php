<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\UserDeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends BaseApiController
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:4096'],
            'platform' => ['nullable', 'string', 'in:android,ios,web'],
        ]);

        UserDeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $data['platform'] ?? 'android',
                'last_seen_at' => now(),
            ],
        );

        return $this->success(null, 'Device token registered.');
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->validate(['token' => ['required', 'string', 'max:4096']]);
        UserDeviceToken::where('user_id', $request->user()->id)
            ->where('token', $request->string('token'))
            ->delete();

        return $this->success(null, 'Device token removed.');
    }
}