<?php

namespace App\Http\Resources\Cart;

use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CartItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $product = $this->product;

        return [
            'id'         => $this->id,
            'quantity'   => $this->quantity,
            'unit_price' => $this->unit_price,
            'line_total' => round($this->unit_price * $this->quantity, 2),
            'product'    => $product ? [
                'id'     => $product->id,
                'name'   => $product->name,
                'status' => $product->status,
                'image'  => PublicMediaUrl::forPath($product->image),
                'store'  => $product->store ? [
                    'id'         => $product->store->id,
                    'store_name' => $product->store->store_name,
                ] : null,
            ] : null,
        ];
    }
}
