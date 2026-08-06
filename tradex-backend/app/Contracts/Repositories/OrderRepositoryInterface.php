<?php

namespace App\Contracts\Repositories;

use App\Models\Order;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface OrderRepositoryInterface
{
    /**
     * Create an order with its items in one transaction.
     *
     * $data: client_id, store_id, customer_name, customer_phone, customer_city,
     *        total_amount, status, notes
     * $items: array of [product_id, product_name, unit_price, quantity, subtotal]
     */
    public function createWithItems(array $data, array $items): Order;

    /**
     * Paginated order history for a client.
     * Supports filters: status, date_from, date_to, per_page.
     */
    public function listForClient(User $client, array $filters): LengthAwarePaginator;

    /** Single order, verified to belong to this client. */
    public function findForClient(int $orderId, User $client): ?Order;

    /**
     * Paginated orders that contain at least one product belonging to
     * this merchant's stores.
     * Supports filters: status, date_from, date_to, per_page.
     */
    public function listForMerchant(User $merchant, array $filters): LengthAwarePaginator;

    /** Single order, verified to contain products from this merchant's store. */
    public function findForMerchant(int $orderId, User $merchant): ?Order;

    /** Update the status of an order. */
    public function updateStatus(Order $order, string $status): Order;

    /**
     * Cancel a pending order for a client (client-initiated cancellation).
     * Only orders in 'pending' status may be cancelled by the client.
     */
    public function cancelForClient(Order $order): Order;
}
