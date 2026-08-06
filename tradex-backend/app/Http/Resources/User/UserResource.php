<?php

namespace App\Http\Resources\User;

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

        return $data;
    }
}
