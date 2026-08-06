<?php

namespace App\Services;

use App\Contracts\Repositories\ReviewRepositoryInterface;
use App\Contracts\Services\ReviewServiceInterface;
use App\Exceptions\ReviewException;
use App\Models\Product;
use App\Models\Review;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ReviewService implements ReviewServiceInterface
{
    public function __construct(
        private readonly ReviewRepositoryInterface $reviewRepository,
    ) {}

    public function listForProduct(int $productId, array $filters): LengthAwarePaginator
    {
        // Verify product exists and is active (public / client-facing)
        if (! Product::where('id', $productId)->where('status', 'active')->exists()) {
            throw new ModelNotFoundException("Product #{$productId} not found.");
        }

        return $this->reviewRepository->getForProduct($productId, $filters);
    }

    public function listForAnyProduct(int $productId, array $filters): LengthAwarePaginator
    {
        // Admin use — only check the product exists (any status)
        if (! Product::where('id', $productId)->exists()) {
            throw new ModelNotFoundException("Product #{$productId} not found.");
        }

        return $this->reviewRepository->getForProduct($productId, $filters);
    }

    public function create(User $client, int $productId, array $data): Review
    {
        // Verify product exists and is active
        $product = Product::where('id', $productId)
            ->where('status', 'active')
            ->whereHas('store', fn ($q) => $q->where('status', 'active'))
            ->first();

        if (! $product) {
            throw new ModelNotFoundException("Product #{$productId} not found.");
        }

        // Check duplicate
        if ($this->reviewRepository->findByProductAndUser($productId, $client->id)) {
            throw ReviewException::alreadyReviewed();
        }

        $review = $this->reviewRepository->create([
            'product_id' => $productId,
            'user_id'    => $client->id,
            'rating'     => $data['rating'],
            'comment'    => $data['comment'] ?? null,
        ]);

        return $review->load('user:id,name,avatar');
    }

    public function delete(User $actor, int $reviewId): void
    {
        $review = $this->reviewRepository->findById($reviewId);

        if (! $review) {
            throw new ModelNotFoundException("Review #{$reviewId} not found.");
        }

        // Clients can only delete their own reviews; admins can delete any
        if (! $actor->isAdmin() && $review->user_id !== $actor->id) {
            throw ReviewException::notOwner();
        }

        $this->reviewRepository->delete($review);
    }
}
