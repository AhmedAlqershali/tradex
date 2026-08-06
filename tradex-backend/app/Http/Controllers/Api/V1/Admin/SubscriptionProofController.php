<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Api\V1\BaseApiController;
use App\Models\SubscriptionRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Secure payment-proof image download for admins.
 *
 * SECURITY: payment proof images are stored on the PRIVATE local disk and are
 * NEVER served as public URLs. This controller:
 *   - Requires auth:sanctum + role:admin (enforced in routes/api.php).
 *   - Streams the file directly from private storage without exposing its path.
 *   - Sets correct Content-Type and Content-Disposition headers.
 *   - Returns 404 if the file does not exist on disk.
 *
 * GET /api/v1/admin/subscription-requests/{id}/proof
 */
class SubscriptionProofController extends BaseApiController
{
    public function download(Request $request, int $id): StreamedResponse|\Illuminate\Http\JsonResponse
    {
        $subscriptionRequest = SubscriptionRequest::find($id);

        if (! $subscriptionRequest) {
            return $this->notFound('Subscription request not found.');
        }

        $path = $subscriptionRequest->payment_proof_image;

        if (! $path || ! Storage::disk('local')->exists($path)) {
            return $this->notFound('Payment proof image not found.');
        }

        $mime = Storage::disk('local')->mimeType($path) ?: 'application/octet-stream';
        $size = Storage::disk('local')->size($path);
        $filename = basename($path);

        return response()->streamDownload(
            function () use ($path) {
                echo Storage::disk('local')->get($path);
            },
            $filename,
            [
                'Content-Type'              => $mime,
                'Content-Length'            => $size,
                'Content-Disposition'       => 'inline; filename="' . $filename . '"',
                'X-Content-Type-Options'    => 'nosniff',
                'Cache-Control'             => 'no-store, private',
            ]
        );
    }
}
