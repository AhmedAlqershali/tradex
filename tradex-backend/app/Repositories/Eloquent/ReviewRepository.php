<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\ReviewRepositoryInterface;
use App\Models\Review;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ReviewRepository implements ReviewRepositoryInterface
{
    public function getForProduct(int $productId, array $filters): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        return Review::with('user:id,name,avatar')
            ->where('product_id', $productId)
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findById(int $id): ?Review
    {
        return Review::with('user:id,name,avatar')->find($id);
    }

    public function findByProductAndUser(int $productId, int $userId): ?Review
    {
        return Review::where('product_id', $productId)
            ->where('user_id', $userId)
            ->first();
    }

    /**
     * Create a review record.
     *
     * SECURITY: `product_id` and `user_id` are excluded from Review::$fillable
     * to prevent impersonation (submitting reviews as other users). We use
     * forceCreate() here because this is trusted service-layer code that has
     * already validated ownership and identity.
     */
    public function create(array $data): Review
    {
        return Review::forceCreate([
            'product_id' => $data['product_id'],
            'user_id'    => $data['user_id'],
            'rating'     => $data['rating'],
            'comment'    => $data['comment'] ?? null,
        ]);
    }

    public function delete(Review $review): bool
    {
        return (bool) $review->delete();
    }

    public function getAverageRatingForProduct(int $productId): float
    {
        return round(
            (float) Review::where('product_id', $productId)->avg('rating'),
            2
        );
    }

    public function getCountForProduct(int $productId): int
    {
        return Review::where('product_id', $productId)->count();
    }
}
