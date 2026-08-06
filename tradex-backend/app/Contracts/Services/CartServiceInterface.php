<?php

namespace App\Contracts\Services;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\User;

interface CartServiceInterface
{
    /** Load the authenticated client's cart (creates one if it does not exist). */
    public function getCart(User $user): Cart;

    /**
     * Add a product to the cart.
     *
     * @throws \App\Exceptions\CartException  if product is inactive or out of stock
     */
    public function addItem(User $user, int $productId, int $quantity): Cart;

    /**
     * Update the quantity of a cart item.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function updateItem(User $user, int $itemId, int $quantity): Cart;

    /**
     * Remove an item from the cart.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function removeItem(User $user, int $itemId): Cart;

    /** Wipe all items from the cart. */
    public function clearCart(User $user): void;
}
