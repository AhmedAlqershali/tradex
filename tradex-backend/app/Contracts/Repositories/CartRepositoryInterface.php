<?php

namespace App\Contracts\Repositories;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\User;

interface CartRepositoryInterface
{
    /** Get or create the cart for this user (with items.product eager-loaded). */
    public function getOrCreateForUser(User $user): Cart;

    /** Add a product to the cart or increment quantity if it already exists. */
    public function addItem(Cart $cart, Product $product, int $quantity): CartItem;

    /** Update quantity of an existing cart item. */
    public function updateItem(CartItem $item, int $quantity): CartItem;

    /** Remove a single cart item. */
    public function removeItem(CartItem $item): bool;

    /** Delete all items in this cart. */
    public function clearCart(Cart $cart): void;

    /** Find a specific item by ID that belongs to this cart. */
    public function findItem(Cart $cart, int $itemId): ?CartItem;
}
