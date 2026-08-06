<?php

namespace App\Contracts\Repositories;

use App\Models\Product;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ProductRepositoryInterface
{
    /**
     * Paginated list of products belonging to the authenticated merchant's stores.
     *
     * Supports: search, category_id, status, sort_by, sort_dir, per_page
     */
    public function getForMerchant(User $user, array $filters): LengthAwarePaginator;

    /**
     * Paginated list of ALL products (admin monitoring).
     */
    public function getAllPaginated(array $filters): LengthAwarePaginator;

    /**
     * Find a product by ID that belongs to one of the merchant's stores.
     * Returns null if not found or merchant does not own it.
     */
    public function findByIdForMerchant(int $id, User $user): ?Product;

    /**
     * Find any product by ID (for admin or policy checks).
     */
    public function findById(int $id): ?Product;

    /**
     * Create a product and return it.
     */
    public function create(array $data): Product;

    /**
     * Update a product model and return the updated instance.
     */
    public function update(Product $product, array $data): Product;

    /**
     * Delete a product.
     */
    public function delete(Product $product): bool;

    /**
     * Replace all images for a product.
     * Accepts an array of ['path' => '...', 'sort_order' => N] maps.
     */
    public function syncImages(Product $product, array $images): void;

    // ── Client marketplace ────────────────────────────────────────────────────

    /**
     * Paginated list of active products from active stores.
     *
     * Supports: search, category_id, store_id, price_min, price_max,
     *           sort (newest | oldest | price_asc | price_desc), per_page
     */
    public function getForClient(array $filters): LengthAwarePaginator;

    /**
     * Find a single active product (from an active store) by ID.
     * Returns null if not found, inactive, or its store is inactive.
     */
    public function findActiveById(int $id): ?Product;
}
