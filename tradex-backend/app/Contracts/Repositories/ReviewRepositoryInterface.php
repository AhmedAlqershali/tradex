<?php

namespace App\Contracts\Repositories;

use App\Models\Review;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ReviewRepositoryInterface
{
    public function getForProduct(int $productId, array $filters): LengthAwarePaginator;

    public function findById(int $id): ?Review;

    public function findByProductAndUser(int $productId, int $userId): ?Review;

    public function create(array $data): Review;

    public function delete(Review $review): bool;

    public function getAverageRatingForProduct(int $productId): float;

    public function getCountForProduct(int $productId): int;
}
