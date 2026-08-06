<?php

namespace App\Http\Resources\Plan;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'name'           => $this->name,
            'display_name'   => $this->display_name,
            'monthly_price'  => (float) $this->monthly_price,
            'yearly_price'   => (float) $this->yearly_price,
            'ai_usage_limit' => $this->ai_usage_limit,
            'product_limit'  => $this->product_limit,
            'store_limit'    => $this->store_limit,
            'features'       => $this->features ?? [],
            'status'         => $this->status,
            'created_at'     => $this->created_at?->toIso8601String(),
        ];
    }
}
