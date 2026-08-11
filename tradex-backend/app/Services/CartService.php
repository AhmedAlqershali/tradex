<?php

namespace App\Services;

use App\Contracts\Repositories\CartRepositoryInterface;
use App\Contracts\Services\CartServiceInterface;
use App\Exceptions\CartException;
use App\Models\Cart;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class CartService implements CartServiceInterface
{
    public function __construct(
        private readonly CartRepositoryInterface $cartRepository,
    ) {}

    public function getCart(User $user): Cart
    {
        return $this->cartRepository->getOrCreateForUser($user);
    }

    public function addItem(User $user, int $productId, int $quantity): Cart
    {
        $product = Product::find($productId);

        if (! $product || $product->status !== 'active') {
            throw CartException::productUnavailable($product?->name ?? "Product #{$productId}");
        }

        // Validate requested quantity against current stock
        if ($quantity > $product->quantity) {
            throw CartException::insufficientStock($product->name, $product->quantity, $quantity);
        }

        // If the product is already in the cart, check that the combined quantity
        // doesn't exceed stock (existing qty + new qty).
        $cart            = $this->cartRepository->getOrCreateForUser($user);
        $existingItem    = $cart->items->firstWhere('product_id', $productId);
        $combinedQty     = $quantity + (int) ($existingItem?->quantity ?? 0);

        if ($combinedQty > $product->quantity) {
            throw CartException::insufficientStock($product->name, $product->quantity, $combinedQty);
        }

        $this->cartRepository->addItem($cart, $product, $quantity);

        return $this->cartRepository->getOrCreateForUser($user);
    }

    public function updateItem(User $user, int $itemId, int $quantity): Cart
    {
        $cart = $this->cartRepository->getOrCreateForUser($user);
        $item = $this->cartRepository->findItem($cart, $itemId);

        if (! $item) {
            throw new ModelNotFoundException("Cart item #{$itemId} not found.");
        }

        if (! $item->product || $item->product->status !== 'active') {
            throw CartException::productUnavailable(
                $item->product?->name ?? "Product #{$item->product_id}",
            );
        }

        // Validate new quantity against current stock
        if ($quantity > $item->product->quantity) {
            throw CartException::insufficientStock(
                $item->product->name,
                $item->product->quantity,
                $quantity,
            );
        }

        $this->cartRepository->updateItem($item, $quantity);

        return $this->cartRepository->getOrCreateForUser($user);
    }

    public function removeItem(User $user, int $itemId): Cart
    {
        $cart = $this->cartRepository->getOrCreateForUser($user);
        $item = $this->cartRepository->findItem($cart, $itemId);

        if (! $item) {
            throw new ModelNotFoundException("Cart item #{$itemId} not found.");
        }

        $this->cartRepository->removeItem($item);

        return $this->cartRepository->getOrCreateForUser($user);
    }

    public function clearCart(User $user): void
    {
        $cart = $this->cartRepository->getOrCreateForUser($user);
        $this->cartRepository->clearCart($cart);
    }
}
