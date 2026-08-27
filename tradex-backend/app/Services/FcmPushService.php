<?php

namespace App\Services;

use App\Models\UserDeviceToken;
use Google\Client;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmPushService
{
    public function send(UserDeviceToken $device, string $title, string $body, array $data): void
    {
        $projectId = config('services.fcm.project_id');
        $credentials = config('services.fcm.credentials');
        if (! $projectId || ! $credentials || ! is_file($credentials)) {
            return;
        }

        try {
            $client = new Client();
            $client->setAuthConfig($credentials);
            $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
            $token = $client->fetchAccessTokenWithAssertion()['access_token'] ?? null;
            if (! $token) return;

            $response = Http::withToken($token)
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $device->token,
                        'notification' => ['title' => $title, 'body' => $body],
                        'data' => array_map('strval', $data),
                        'android' => ['notification' => ['channel_id' => 'tradex_notifications']],
                    ],
                ]);

            $errorCode = $response->json('error.details.0.errorCode');
            if ($response->status() === 404 || $response->status() === 410 || $errorCode === 'UNREGISTERED') {
                $device->delete();
            }
        } catch (\Throwable $exception) {
            Log::warning('FCM push failed', ['device_token_id' => $device->id, 'error' => $exception->getMessage()]);
        }
    }
}