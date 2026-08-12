<?php

namespace App\Services;

use App\Contracts\Repositories\CartRepositoryInterface;
use App\Contracts\Repositories\OrderRepositoryInterface;
use App\Contracts\Services\OrderServiceInterface;
use App\Contracts\Services\UserNotificationServiceInterface;
use App\Exceptions\CartException;
use App\Exceptions\OrderException;
use App\Models\Order;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class OrderService implements OrderServiceInterface
{
    public function __construct(
        private readonly OrderRepositoryInterface $orderRepository,
        private readonly CartRepositoryInterface  $cartRepository,
        private readonly UserNotificationServiceInterface $notificationService,
    ) {}

    /**
     * Checkout: group cart items by store and create one Order per store.
     * Clears the cart on success.
     *
     * The whole checkout (all per-store orders + stock decrements + cart
     * clearing) is wrapped in a single outer transaction: if any store's
     * order fails (e.g. insufficient stock), none of the orders for this
     * checkout are persisted — the client gets a clean "all or nothing"
     * result rather than a partially-placed multi-store order.
     *
     * @return Collection<Order>
     * @throws CartException   if the cart is empty
     * @throws OrderException  if any item's stock is insufficient at checkout time
     */
    public function checkout(User $client, array $contactData): Collection
    {
        $cart = $this->cartRepository->getOrCreateForUser($client);

        if ($cart->items->isEmpty()) {
            throw CartException::cartEmpty();
        }

        // Group items by store to create one order per store
        $grouped = $cart->items->groupBy(fn ($item) => $item->product->store_id);

        $orders = DB::transaction(function () use ($grouped, $client, $contactData, $cart) {
            $orders = collect();

            foreach ($grouped as $storeId => $items) {
                $total     = $items->sum(fn ($item) => $item->unit_price * $item->quantity);
                $itemData  = $items->map(fn ($item) => [
                    'product_id'   => $item->product_id,
                    'product_name' => $item->product->name,
                    'unit_price'   => $item->unit_price,
                    'quantity'     => $item->quantity,
                    'subtotal'     => round($item->unit_price * $item->quantity, 2),
                ])->values()->toArray();

                // May throw OrderException::insufficientStock() — propagates out
                // and rolls back the whole outer transaction, including any
                // orders already created for other stores in this checkout.
                $order = $this->orderRepository->createWithItems(
                    array_merge($contactData, [
                        'client_id'    => $client->id,
                        'store_id'     => $storeId,
                        'total_amount' => round($total, 2),
                        'status'       => Order::STATUS_PENDING,
                    ]),
                    $itemData,
                );

                $orders->push($order);
            }

            // Clear cart after all orders for this checkout succeed
            $this->cartRepository->clearCart($cart);

            return $orders;
        });

        foreach ($orders as $order) {
            $this->notificationService->create(
                $client,
                'order_placed',
                'تم استلام طلبك',
                "تم استلام طلبك رقم #{$order->id} بنجاح.",
                ['order_id' => $order->id, 'status' => $order->status],
            );

            $merchant = $order->store?->owner;
            if ($merchant) {
                $this->notificationService->create(
                    $merchant,
                    'new_order',
                    'طلب جديد',
                    "لديك طلب جديد رقم #{$order->id}.",
                    ['order_id' => $order->id, 'status' => $order->status],
                );
            }
        }

        return $orders;
    }

    public function listForClient(User $client, array $filters): LengthAwarePaginator
    {
        return $this->orderRepository->listForClient($client, $filters);
    }

    public function findForClient(int $orderId, User $client): Order
    {
        $order = $this->orderRepository->findForClient($orderId, $client);

        if (! $order) {
            throw new ModelNotFoundException("Order #{$orderId} not found.");
        }

        return $order;
    }

    /**
     * Cancel a pending order on behalf of the client.
     *
     * Business rules:
     * - Only orders in 'pending' status can be cancelled by the client.
     * - Once the merchant has confirmed/started processing, the client can
     *   no longer cancel (they must contact the merchant directly).
     *
     * @throws ModelNotFoundException  if the order does not belong to this client
     * @throws OrderException          if the order is not in a cancellable state
     */
    public function cancelForClient(User $client, int $orderId): Order
    {
        $order = $this->findForClient($orderId, $client);

        if ($order->status !== Order::STATUS_PENDING) {
            throw OrderException::notCancellableByClient($order->status);
        }

        $cancelled = $this->orderRepository->cancelForClient($order);

        $merchant = $cancelled->store?->owner;
        if ($merchant) {
            $this->notificationService->create(
                $merchant,
                'order_cancelled',
                'تم إلغاء طلب',
                "قام العميل بإلغاء الطلب رقم #{$cancelled->id}.",
                ['order_id' => $cancelled->id, 'status' => $cancelled->status],
            );
        }

        return $cancelled;
    }

    public function listForMerchant(User $merchant, array $filters): LengthAwarePaginator
    {
        return $this->orderRepository->listForMerchant($merchant, $filters);
    }

    public function findForMerchant(int $orderId, User $merchant): Order
    {
        $order = $this->orderRepository->findForMerchant($orderId, $merchant);

        if (! $order) {
            throw new ModelNotFoundException("Order #{$orderId} not found.");
        }

        return $order;
    }

    public function listForAdmin(array $filters): LengthAwarePaginator
    {
        return $this->orderRepository->listForAdmin($filters);
    }

    public function findForAdmin(int $orderId): Order
    {
        $order = $this->orderRepository->findForAdmin($orderId);

        if (! $order) {
            throw new ModelNotFoundException("Order #{$orderId} not found.");
        }

        return $order;
    }

    public function updateStatusForAdmin(int $orderId, string $newStatus): Order
    {
        $order = $this->findForAdmin($orderId);

        if (! in_array($newStatus, Order::MERCHANT_ALLOWED_STATUSES, true)) {
            throw OrderException::invalidStatusTransition($order->status, $newStatus);
        }

        return $this->updateStatusForOrder($order, $newStatus);
    }

    public function updateStatus(User $merchant, int $orderId, string $newStatus): Order
    {
        $order = $this->findForMerchant($orderId, $merchant);

        if (! in_array($newStatus, Order::MERCHANT_ALLOWED_STATUSES, true)) {
            throw OrderException::invalidStatusTransition($order->status, $newStatus);
        }

        return $this->updateStatusForOrder($order, $newStatus);
    }

    private function updateStatusForOrder(Order $order, string $newStatus): Order
    {
        $updated = $this->orderRepository->updateStatus($order, $newStatus);

        if ($updated->client) {
            $this->notificationService->create(
                $updated->client,
                'order_status_updated',
                'تحديث حالة الطلب',
                "تم تحديث حالة طلبك رقم #{$updated->id} إلى {$updated->status}.",
                ['order_id' => $updated->id, 'status' => $updated->status],
            );
        }

        return $updated;
    }
}
