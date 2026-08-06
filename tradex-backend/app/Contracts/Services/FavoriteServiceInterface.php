<?php

namespace App\Contracts\Services;

use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;

interface FavoriteServiceInterface
{
    /** Return paginated favorite products for the user. */
    public function getFavorites(User $user, int $perPage = 15): LengthAwarePaginator;

    /**
     * Add a product to favorites if not already there.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException  if product not found
     * @throws \App\Exceptions\CartException                         (reused for domain conflicts)
     */
    public function add(User $user, int $productId): array;

    /**
     * Remove a product from favorites.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException  if favorite not found
     */
    public function remove(User $user, int $productId): void;

    /** Returns true if the product is currently favorited by the user. */
    public function isFavorited(User $user, int $productId): bool;
}
