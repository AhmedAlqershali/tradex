<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\CartRepositoryInterface;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\User;

class CartRepository implements CartRepositoryInterface
{
    public function getOrCreateForUser(User $user): Cart
    {
        $cart = Cart::firstOrCreate(['user_id' => $user->id]);

        return $cart->load(['items.product.store']);
    }

    public function addItem(Cart $cart, Product $product, int $quantity): CartItem
    {
        $item = $cart->items()->where('product_id', $product->id)->first();

        if ($item) {
            $item->increment('quantity', $quantity);
            return $item->fresh();
        }

        return $cart->items()->create([
            'product_id' => $product->id,
            'quantity'   => $quantity,
        ]);
    }

    public function updateItem(CartItem $item, int $quantity): CartItem
    {
        $item->update(['quantity' => $quantity]);
        return $item->fresh();
    }

    public function removeItem(CartItem $item): bool
    {
        return (bool) $item->delete();
    }

    public function clearCart(Cart $cart): void
    {
        $cart->items()->delete();
    }

    public function findItem(Cart $cart, int $itemId): ?CartItem
    {
        return $cart->items()->with('product')->find($itemId);
    }
}
