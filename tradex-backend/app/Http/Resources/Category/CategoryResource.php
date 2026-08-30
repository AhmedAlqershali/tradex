<?php

namespace App\Http\Resources\Category;

use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'    => $this->id,
            'name'  => $this->name,
            'image' => PublicMediaUrl::forPath($this->image),
            'status'         => $this->status,
            // products_count is only present when the query eager-loaded it
            // (admin endpoints). Public marketplace responses omit this field.
            'products_count' => $this->when(
                isset($this->products_count),
                fn () => (int) $this->products_count,
            ),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
