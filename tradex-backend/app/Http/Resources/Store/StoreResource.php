<?php

namespace App\Http\Resources\Store;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StoreResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'store_name' => $this->store_name,
            'description' => $this->description,
            'region'     => $this->region,
            'logo'       => $this->logo
                ? url('/storage/'.ltrim($this->logo, '/'))
                : null,
            'status'         => $this->status,
            'products_count' => $this->products_count ?? 0,
            'phone'         => $this->whenLoaded('owner', fn () => $this->owner?->phone),
            'created_at'     => $this->created_at?->toIso8601String(),
        ];
    }
}
