<?php

namespace App\Contracts\Repositories;

use App\Models\Favorite;
use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;

interface FavoriteRepositoryInterface
{
    /** Return paginated favorites with their products for a user. */
    public function getForUser(User $user, int $perPage = 15): LengthAwarePaginator;

    /** Check whether a product is already favorited by a user. */
    public function isFavorited(User $user, int $productId): bool;

    /** Add a product to a user's favorites. Returns the created record. */
    public function add(User $user, int $productId): Favorite;

    /** Remove a product from a user's favorites. Returns true if deleted. */
    public function remove(User $user, int $productId): bool;
}
