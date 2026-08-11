<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\FavoriteRepositoryInterface;
use App\Models\Favorite;
use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;

class FavoriteRepository implements FavoriteRepositoryInterface
{
    public function getForUser(User $user, int $perPage = 15): LengthAwarePaginator
    {
        return Favorite::where('user_id', $user->id)
            ->with(['product.category', 'product.images', 'product.store'])
            ->latest()
            ->paginate($perPage);
    }

    public function isFavorited(User $user, int $productId): bool
    {
        return Favorite::where('user_id', $user->id)
            ->where('product_id', $productId)
            ->exists();
    }

    public function add(User $user, int $productId): Favorite
    {
        $favorite = Favorite::firstOrCreate([
            'user_id'    => $user->id,
            'product_id' => $productId,
        ]);

        return $favorite->load(['product.category', 'product.images', 'product.store']);
    }

    public function remove(User $user, int $productId): bool
    {
        return (bool) Favorite::where('user_id', $user->id)
            ->where('product_id', $productId)
            ->delete();
    }
}
