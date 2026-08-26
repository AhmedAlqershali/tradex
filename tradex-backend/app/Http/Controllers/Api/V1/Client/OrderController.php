<?php

namespace App\Http\Controllers\Api\V1\Client;

use App\Contracts\Services\OrderServiceInterface;
use App\Exceptions\CartException;
use App\Exceptions\OrderException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Resources\Order\OrderCollection;
use App\Http\Resources\Order\OrderResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Client order management.
 *
 * All routes require auth:sanctum + role:client.
 * POST   /api/v1/orders           — checkout from cart
 * GET    /api/v1/orders           — order history (filterable)
 * GET    /api/v1/orders/{id}      — order detail
 * DELETE /api/v1/orders/{id}      — cancel a pending order
 */
class OrderController extends BaseApiController
{
    public function __construct(
        private readonly OrderServiceInterface $orderService,
    ) {}

    // ── POST /api/v1/orders ───────────────────────────────────────────────────

    /**
     * Checkout: convert the client's cart into orders (one per store).
     */
    public function store(CreateOrderRequest $request): JsonResponse
    {
        try {
            $orders = $this->orderService->checkout(
                $request->user(),
                $request->validated(),
            );
        } catch (CartException|OrderException $e) {
            return $this->error($e->getMessage(), 422);
        }

        $orders->each->loadMissing(['store', 'items']);
        $data = OrderResource::collection($orders);

        return $this->created($data, 'Order placed successfully.');
    }

    // ── GET /api/v1/orders ────────────────────────────────────────────────────

    /**
     * Paginated order history with optional filters.
     *
     * Query parameters:
     *   status    string — pending_review | confirmed | completed | cancelled
     *   date_from string — Y-m-d (inclusive)
     *   date_to   string — Y-m-d (inclusive)
     *   per_page  int    — 1-100 (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $request->only(['status', 'date_from', 'date_to', 'per_page']);
        try {
            $paginator = $this->orderService->listForClient($request->user(), $filters);
        } catch (OrderException $e) {
            return $this->error($e->getMessage(), 422);
        }
        $collection = new OrderCollection($paginator);

        return $this->success($collection->toArray($request), 'Orders retrieved successfully.');
    }

    // ── GET /api/v1/orders/{id} ───────────────────────────────────────────────

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $order = $this->orderService->findForClient($id, $request->user());
        } catch (ModelNotFoundException) {
            return $this->notFound('Order not found.');
        }

        return $this->success(new OrderResource($order), 'Order retrieved successfully.');
    }

    // ── DELETE /api/v1/orders/{id} ────────────────────────────────────────────

    /**
     * Cancel a pending order.
     *
     * Business rules enforced in OrderService:
     * - Only orders in 'pending_review' status can be cancelled by the client.
     * - Returns 422 if the order has already been confirmed or is in a later stage.
     */
    public function cancel(Request $request, int $id): JsonResponse
    {
        try {
            $order = $this->orderService->cancelForClient($request->user(), $id);
        } catch (ModelNotFoundException) {
            return $this->notFound('Order not found.');
        } catch (OrderException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success(new OrderResource($order), 'Order cancelled successfully.');
    }
}
