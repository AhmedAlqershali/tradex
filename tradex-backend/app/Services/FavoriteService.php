<?php

namespace App\Services;

use App\Contracts\Repositories\FavoriteRepositoryInterface;
use App\Contracts\Services\FavoriteServiceInterface;
use App\Models\Favorite;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Pagination\LengthAwarePaginator;

class FavoriteService implements FavoriteServiceInterface
{
    public function __construct(
        private readonly FavoriteRepositoryInterface $favoriteRepository,
    ) {}

    public function getFavorites(User $user, int $perPage = 15): LengthAwarePaginator
    {
        return $this->favoriteRepository->getForUser($user, $perPage);
    }

    public function add(User $user, int $productId): array
    {
        $product = Product::find($productId);

        if (! $product) {
            throw new ModelNotFoundException("Product #{$productId} not found.");
        }

        if ($this->favoriteRepository->isFavorited($user, $productId)) {
            return [
                'already_favorited' => true,
                'favorite'          => Favorite::where('user_id', $user->id)
                    ->where('product_id', $productId)
                    ->with(['product.category', 'product.images', 'product.store'])
                    ->first(),
            ];
        }

        $favorite = $this->favoriteRepository->add($user, $productId);

        return [
            'already_favorited' => false,
            'favorite'          => $favorite,
        ];
    }

    public function remove(User $user, int $productId): void
    {
        $deleted = $this->favoriteRepository->remove($user, $productId);

        if (! $deleted) {
            throw new ModelNotFoundException("Favorite for product #{$productId} not found.");
        }
    }

    public function isFavorited(User $user, int $productId): bool
    {
        return $this->favoriteRepository->isFavorited($user, $productId);
    }
}
