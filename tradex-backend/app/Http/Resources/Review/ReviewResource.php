<?php

namespace App\Http\Resources\Review;

use App\Support\PublicMediaUrl;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'      => $this->id,
            'rating'  => $this->rating,
            'comment' => $this->comment,
            'reviewer' => $this->whenLoaded('user', fn () => [
                'id'     => $this->user->id,
                'name'   => $this->user->name,
                'avatar' => PublicMediaUrl::forPath($this->user->avatar),
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
