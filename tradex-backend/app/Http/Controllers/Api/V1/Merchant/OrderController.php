<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Contracts\Services\OrderServiceInterface;
use App\Exceptions\OrderException;
use App\Http\Controllers\Api\V1\BaseApiController;
use App\Http\Requests\Order\UpdateOrderStatusRequest;
use App\Http\Resources\Order\OrderCollection;
use App\Http\Resources\Order\OrderResource;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Merchant order management.
 *
 * All routes require auth:sanctum + role:merchant.
 * GET /api/v1/merchant/orders              — incoming orders
 * GET /api/v1/merchant/orders/{id}         — order detail
 * PUT /api/v1/merchant/orders/{id}/status  — update status
 */
class OrderController extends BaseApiController
{
    public function __construct(
        private readonly OrderServiceInterface $orderService,
    ) {}

    // ── GET /api/v1/merchant/orders ───────────────────────────────────────────

    /**
     * List orders for the merchant's stores with optional filters.
     *
     * Query parameters:
     *   status    string — confirmed | completed | cancelled
     *   date_from string — Y-m-d (inclusive)
     *   date_to   string — Y-m-d (inclusive)
     *   per_page  int    — 1-100 (default: 15)
     */
    public function index(Request $request): JsonResponse
    {
        $filters    = $request->only(['status', 'date_from', 'date_to', 'per_page']);
        $paginator  = $this->orderService->listForMerchant($request->user(), $filters);
        $collection = new OrderCollection($paginator);

        return $this->success($collection->toArray($request), 'Orders retrieved successfully.');
    }

    // ── GET /api/v1/merchant/orders/{id} ─────────────────────────────────────

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $order = $this->orderService->findForMerchant($id, $request->user());
        } catch (ModelNotFoundException) {
            return $this->notFound('Order not found.');
        }

        return $this->success(new OrderResource($order), 'Order retrieved successfully.');
    }

    // ── PUT /api/v1/merchant/orders/{id}/status ───────────────────────────────

    public function updateStatus(UpdateOrderStatusRequest $request, int $id): JsonResponse
    {
        try {
            $order = $this->orderService->updateStatus(
                $request->user(),
                $id,
                $request->validated('status'),
            );
        } catch (ModelNotFoundException) {
            return $this->notFound('Order not found.');
        } catch (OrderException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success(new OrderResource($order), 'Order status updated.');
    }
}
