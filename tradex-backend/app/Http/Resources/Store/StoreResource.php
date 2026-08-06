<?php

namespace App\Http\Resources\Store;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class StoreResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'store_name' => $this->store_name,
            'description' => $this->description,
            'logo'       => $this->logo
                ? Storage::disk('public')->url($this->logo)
                : null,
            'status'         => $this->status,
            'products_count' => $this->products_count ?? 0,
            'created_at'     => $this->created_at?->toIso8601String(),
        ];
    }
}
