<?php

namespace App\Http\Resources\Order;

use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'status'         => $this->status,
            'total_amount'   => $this->total_amount,
            'notes'          => $this->notes,

            // Customer contact snapshot
            'customer_name'  => $this->customer_name,
            'customer_phone' => $this->customer_phone,
            'customer_city'  => $this->customer_city,

            // Store summary
            'store' => $this->whenLoaded('store', fn () => [
                'id'         => $this->store->id,
                'store_name' => $this->store->store_name,
                'logo'       => PublicMediaUrl::forPath($this->store->logo),
            ]),

            // Client summary (merchant view)
            'client' => $this->whenLoaded('client', fn () => [
                'id'    => $this->client->id,
                'name'  => $this->client->name,
                'phone' => $this->client->phone,
            ]),

            'items'      => OrderItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
