<?php

namespace App\Contracts\Services;

use App\Models\Order;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface OrderServiceInterface
{
    /**
     * Checkout: convert the client's cart into one Order per store.
     * Clears the cart on success.
     *
     * @return Collection<Order>
     * @throws \App\Exceptions\CartException  if cart is empty
     */
    public function checkout(User $client, array $contactData): Collection;

    /**
     * Paginated order list for client.
     * Supports filters: status, date_from, date_to, per_page.
     */
    public function listForClient(User $client, array $filters): LengthAwarePaginator;

    /**
     * Single order detail for client.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function findForClient(int $orderId, User $client): Order;

    /**
     * Cancel a pending order on behalf of a client.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException  if order not found for this client
     * @throws \App\Exceptions\OrderException  if the order cannot be cancelled (wrong status)
     */
    public function cancelForClient(User $client, int $orderId): Order;

    /**
     * Paginated order list for merchant (own store only).
     * Supports filters: status, date_from, date_to, per_page.
     */
    public function listForMerchant(User $merchant, array $filters): LengthAwarePaginator;

    /**
     * Single order detail for merchant.
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function findForMerchant(int $orderId, User $merchant): Order;

    /**
     * Update order status (merchant only).
     *
     * @throws \App\Exceptions\OrderException  if status transition is invalid
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function updateStatus(User $merchant, int $orderId, string $newStatus): Order;
}
