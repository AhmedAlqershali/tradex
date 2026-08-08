<?php

namespace App\Http\Resources\User;

use App\Http\Resources\Subscription\SubscriptionResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $data = [
            'id'     => $this->id,
            'name'   => $this->name,
            'email'  => $this->email,
            'phone'  => $this->phone,
            'role'   => $this->role,
            'status' => $this->status,
            'avatar' => $this->avatar
                ? Storage::disk('public')->url($this->avatar)
                : null,
            'email_verified_at' => $this->email_verified_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];

        // Include stores for merchants when the relation is loaded
        if ($this->isMerchant() && $this->relationLoaded('stores')) {
            $data['stores'] = $this->stores->map(fn ($store) => [
                'id'          => $store->id,
                'store_name'  => $store->store_name,
                'description' => $store->description,
                'logo'        => $store->logo,
                'status'      => $store->status,
            ])->values();
        }

        // Admin merchant views include the current period and preserved
        // subscription history when the relationship was explicitly loaded.
        // Other user payloads do not pay the cost or expose these fields.
        if ($this->isMerchant() && $this->relationLoaded('subscriptions')) {
            $subscriptions = $this->subscriptions
                ->sortByDesc('starts_at')
                ->values();

            $data['current_subscription'] = $subscriptions->first()
                ? new SubscriptionResource($subscriptions->first())
                : null;
            $data['subscription_history'] = SubscriptionResource::collection($subscriptions);
        }

        return $data;
    }
}
