<?php

namespace App\Http\Resources\Cart;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CartResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'item_count' => $this->itemCount(),
            'subtotal'   => round((float) $this->subtotal(), 2),
            'items'      => CartItemResource::collection($this->items),
        ];
    }
}
