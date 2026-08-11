<?php

namespace App\Http\Resources\Product;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'store_id'    => $this->store_id,
            'category_id' => $this->category_id,
            'category'    => $this->whenLoaded('category', fn () => [
                'id'   => $this->category?->id,
                'name' => $this->category?->name,
            ]),
            'name'        => $this->name,
            'description' => $this->description,
            'price'       => (float) $this->price,
            'quantity'    => $this->quantity,
            'status'      => $this->status,
            'is_available' => $this->isAvailable(),

            // Primary image (quick access thumbnail)
            'image'  => $this->image
                ? Storage::disk('public')->url($this->image)
                : null,

            // Full image gallery
            'images' => ProductImageResource::collection(
                $this->whenLoaded('images', fn () => $this->images->sortBy('sort_order'))
            ),

            // Store summary (only included for admin responses)
            'store' => $this->whenLoaded('store', fn () => [
                'id'         => $this->store->id,
                'store_name' => $this->store->store_name,
                'status'     => $this->store->status,
            ]),

            // Review stats (loaded via withAvg / withCount eager loading, or computed on demand)
            'average_rating' => isset($this->reviews_avg_rating)
                ? round((float) $this->reviews_avg_rating, 2)
                : null,
            'review_count' => isset($this->reviews_count)
                ? (int) $this->reviews_count
                : null,

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
