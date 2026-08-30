<?php

namespace App\Http\Resources\Product;

use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductImageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'url'        => PublicMediaUrl::forPath($this->path),
            'sort_order' => $this->sort_order,
        ];
    }
}
