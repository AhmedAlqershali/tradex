<?php

namespace App\Http\Resources\Subscription;

use App\Http\Resources\Plan\PlanResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'            => $this->id,
            'plan'          => $this->when($this->isTrial(), null, fn () => $this->whenLoaded('plan', fn () => new PlanResource($this->plan))),
            'billing_cycle' => $this->billing_cycle,
            'type'          => $this->type,
            'is_trial'      => $this->isTrial(),
            'status'        => $this->status,
            'is_entitled'   => $this->isEntitled(),
            'starts_at'     => $this->starts_at?->toIso8601String(),
            'ends_at'       => $this->ends_at?->toIso8601String(),
            'cancelled_at'  => $this->cancelled_at?->toIso8601String(),
            'created_at'    => $this->created_at?->toIso8601String(),
        ];
    }
}
