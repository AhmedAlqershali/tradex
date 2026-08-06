<?php

namespace App\Http\Resources\Review;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

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
                'avatar' => $this->user->avatar
                    ? Storage::disk('public')->url($this->user->avatar)
                    : null,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
