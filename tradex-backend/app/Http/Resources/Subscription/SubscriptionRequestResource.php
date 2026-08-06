<?php

namespace App\Http\Resources\Subscription;

use App\Http\Resources\Plan\PlanResource;
use App\Http\Resources\User\UserResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class SubscriptionRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // SECURITY: payment proof images are stored on the PRIVATE local disk.
        // Only admins may access them, via the secure download route that
        // streams the file server-side. Merchants receive null for this field
        // (they uploaded it; they don't need to re-download it via API).
        $proofUrl = null;

        if ($this->payment_proof_image) {
            $user = $request->user();

            if ($user && $user->isAdmin()) {
                // Admin sees a secure download URL (served through the API,
                // not a direct storage URL that could be shared).
                $proofUrl = route('api.v1.admin.subscription-requests.proof', ['id' => $this->id]);
            }
        }

        return [
            'id'                    => $this->id,
            'merchant'              => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'plan'                  => $this->whenLoaded('plan', fn () => new PlanResource($this->plan)),
            'billing_cycle'         => $this->billing_cycle,
            'full_name'             => $this->full_name,
            'phone'                 => $this->phone,
            'payment_method'        => $this->payment_method,
            'payment_proof_url'     => $proofUrl,
            'notes'                 => $this->notes,
            'status'                => $this->status,
            'rejection_reason'      => $this->rejection_reason,
            'reviewed_by'           => $this->whenLoaded('reviewer', fn () => $this->reviewer ? new UserResource($this->reviewer) : null),
            'reviewed_at'           => $this->reviewed_at?->toIso8601String(),
            'created_at'            => $this->created_at?->toIso8601String(),
        ];
    }
}
