<?php

namespace App\Contracts\Services;

use App\Models\Product;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface ProductServiceInterface
{
    /**
     * List products for the authenticated merchant with optional filters.
     */
    public function listForMerchant(User $user, array $filters): LengthAwarePaginator;

    /**
     * List all products for admin monitoring.
     */
    public function listAll(array $filters): LengthAwarePaginator;

    /**
     * Find a single product owned by this merchant.
     * Throws ModelNotFoundException if not found or not owned.
     */
    public function findForMerchant(int $id, User $user): Product;

    /**
     * Find any product (admin use).
     * Throws ModelNotFoundException if not found.
     */
    public function findById(int $id): Product;

    /**
     * Create a product with optional uploaded images.
     * $data includes validated fields; $imageFiles is an array of UploadedFile.
     */
    public function create(User $user, array $data, array $imageFiles = []): Product;

    /**
     * Update an existing product.
     */
    public function update(Product $product, array $data, array $imageFiles = []): Product;

    /**
     * Delete a product and its images from storage.
     */
    public function delete(Product $product): bool;

    // ── Client marketplace ────────────────────────────────────────────────────

    /**
     * Paginated list of active products for client browsing.
     *
     * Supports: search, category_id, store_id, price_min, price_max,
     *           sort (newest | oldest | price_asc | price_desc), per_page
     */
    public function listForClient(array $filters): LengthAwarePaginator;

    /**
     * Find a single active product (from an active store) by ID.
     * Throws ModelNotFoundException if not found, inactive, or store inactive.
     */
    public function findActiveById(int $id): Product;
}
