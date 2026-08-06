<?php

namespace App\Contracts\Services;

use App\Models\Review;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ReviewServiceInterface
{
    /**
     * Paginated reviews for an active product (public / client-facing).
     * Throws ModelNotFoundException if the product does not exist or is not active.
     */
    public function listForProduct(int $productId, array $filters): LengthAwarePaginator;

    /**
     * Paginated reviews for any product regardless of status (admin use only).
     * Throws ModelNotFoundException if the product does not exist at all.
     */
    public function listForAnyProduct(int $productId, array $filters): LengthAwarePaginator;

    /**
     * Create a review. Throws if client already reviewed this product.
     *
     * @throws \App\Exceptions\ReviewException
     */
    public function create(User $client, int $productId, array $data): Review;

    /**
     * Delete a review. Clients may only delete their own; admins may delete any.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     * @throws \App\Exceptions\ReviewException
     */
    public function delete(User $actor, int $reviewId): void;
}
