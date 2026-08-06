<?php

namespace App\Http\Resources\Favorite;

use App\Http\Resources\Product\ProductResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FavoriteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'product_id' => $this->product_id,
            'product'    => $this->whenLoaded('product', fn () => new ProductResource($this->product)),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
