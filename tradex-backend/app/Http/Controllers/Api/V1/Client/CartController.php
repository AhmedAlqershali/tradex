<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\CartServiceInterface;
use App\Exceptions\CartException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Cart\AddCartItemRequest;
use App\Http\Requests\Cart\UpdateCartItemRequest;
use App\Http\Resources\Cart\CartResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client cart management.
 *
 * All routes require auth:sanctum + role:client.
 * GET    /api/v1/cart
 * POST   /api/v1/cart/items
 * PUT    /api/v1/cart/items/{id}
 * DELETE /api/v1/cart/items/{id}
 */
class CartController extends BaseApiController
{
    public function __construct(
        private readonly CartServiceInterface $cartService,
    ) {}

    // ── GET /api/v1/cart ──────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $cart = $this->cartService->getCart($request->user());

        return $this->success(new CartResource($cart), 'Cart retrieved successfully.');
    }

    // ── POST /api/v1/cart/items ───────────────────────────────────────────────

    public function addItem(AddCartItemRequest $request): JsonResponse
    {
        try {
            $cart = $this->cartService->addItem(
                $request->user(),
                $request->validated('product_id'),
                $request->validated('quantity'),
            );
        } catch (CartException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success(new CartResource($cart), 'Item added to cart.');
    }

    // ── PUT /api/v1/cart/items/{id} ───────────────────────────────────────────

    public function updateItem(UpdateCartItemRequest $request, int $id): JsonResponse
    {
        try {
            $cart = $this->cartService->updateItem(
                $request->user(),
                $id,
                $request->validated('quantity'),
            );
        } catch (ModelNotFoundException) {
            return $this->notFound('Cart item not found.');
        } catch (CartException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success(new CartResource($cart), 'Cart item updated.');
    }

    // ── DELETE /api/v1/cart/items/{id} ────────────────────────────────────────

    public function removeItem(Request $request, int $id): JsonResponse
    {
        try {
            $cart = $this->cartService->removeItem($request->user(), $id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Cart item not found.');
        }

        return $this->success(new CartResource($cart), 'Item removed from cart.');
    }

    // ── DELETE /api/v1/cart ──────────────────────────────────────────────────

    public function clear(Request $request): JsonResponse
    {
        $this->cartService->clearCart($request->user());

        return $this->success(
            new CartResource($this->cartService->getCart($request->user())),
            'Cart cleared.',
        );
    }
}
