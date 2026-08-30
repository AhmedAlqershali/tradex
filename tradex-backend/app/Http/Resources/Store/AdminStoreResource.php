<?php

namespace App\Http\Resources\Store;

use App\Http\Resources\Product\ProductResource;
use App\Http\Resources\Subscription\SubscriptionResource;
use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Detailed store resource for admin endpoints.
 * Includes owner (merchant) info and product list.
 */
class AdminStoreResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'store_name'  => $this->store_name,
            'description' => $this->description,
            'logo'        => PublicMediaUrl::forPath($this->logo),
            'status'      => $this->status,

            // Counts (available when loaded with withCount)
            'products_count' => $this->products_count ?? null,
            'orders_count'   => $this->orders_count   ?? null,

            // Merchant / owner info
            'owner' => $this->whenLoaded('owner', function () {
                $owner = [
                    'id'     => $this->owner->id,
                    'name'   => $this->owner->name,
                    'email'  => $this->owner->email,
                    'phone'  => $this->owner->phone,
                    'role'   => $this->owner->role,
                    'status' => $this->owner->status,
                ];

                if ($this->owner->relationLoaded('subscriptions')) {
                    $subscriptions = $this->owner->subscriptions
                        ->sortByDesc('starts_at')
                        ->values();
                    $owner['current_subscription'] = $subscriptions->first()
                        ? new SubscriptionResource($subscriptions->first())
                        : null;
                    $owner['subscription_history'] =
                        SubscriptionResource::collection($subscriptions);
                }

                return $owner;
            }),

            // Products preview (first 10)
            'products' => $this->whenLoaded(
                'products',
                fn () => ProductResource::collection($this->products),
            ),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
