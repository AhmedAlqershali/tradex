<?php

namespace App\Repositories\Eloquent;

use App\Contracts\Repositories\OrderRepositoryInterface;
use App\Exceptions\OrderException;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class OrderRepository implements OrderRepositoryInterface
{
    /**
     * Create an order with its items inside a DB transaction.
     *
     * SECURITY: uses Order::forceCreate() because `client_id`, `store_id`,
     * `total_amount`, and `status` are excluded from $fillable to prevent mass
     * assignment.  These values come from trusted service / session data, not
     * from user-supplied request input.
     *
     * @throws OrderException  if any item's requested quantity exceeds current stock
     */
    public function createWithItems(array $data, array $items): Order
    {
        return DB::transaction(function () use ($data, $items) {
            // ── Lock and validate stock for every product before writing anything ──
            // Row-level locks (lockForUpdate) prevent two concurrent checkouts from
            // both reading "stock available" and overselling the same last unit.
            foreach ($items as $item) {
                if (empty($item['product_id'])) {
                    continue;
                }

                $product = Product::whereKey($item['product_id'])->lockForUpdate()->first();

                if (
                    ! $product
                    || $product->status !== 'active'
                    || $product->quantity < $item['quantity']
                ) {
                    throw OrderException::insufficientStock(
                        $item['product_name'],
                        $product?->quantity ?? 0,
                        $item['quantity'],
                    );
                }
            }

            // forceCreate bypasses $fillable so we can set protected fields
            // (client_id, store_id, total_amount, status) from trusted service data.
            $order = Order::forceCreate([
                'client_id'     => $data['client_id'],
                'store_id'      => $data['store_id'],
                'customer_name' => $data['customer_name'],
                'customer_phone'=> $data['customer_phone'],
                'customer_city' => $data['customer_city'],
                'total_amount'  => $data['total_amount'],
                'status'        => $data['status'],
                'notes'         => $data['notes'] ?? null,
            ]);

            $order->items()->createMany($items);

            foreach ($items as $item) {
                if (empty($item['product_id'])) {
                    continue;
                }

                // AI Data Prep — increment cumulative units sold
                // Stock control — decrement remaining quantity, flip to
                // out_of_stock automatically once it hits zero.
                $qty = (int) $item['quantity'];

                DB::table('products')
                    ->where('id', $item['product_id'])
                    ->update([
                        'total_sold' => DB::raw("total_sold + {$qty}"),
                        'quantity'   => DB::raw("quantity - {$qty}"),
                        'status'     => DB::raw(
                            "CASE WHEN quantity - {$qty} <= 0 THEN 'out_of_stock' ELSE status END"
                        ),
                    ]);
            }

            return $order->load(['store', 'items']);
        });
    }

    /**
     * Paginated order list for a specific client.
     *
     * Supports optional filters: status, date_from (Y-m-d), date_to (Y-m-d), per_page.
     * An invalid status value is silently ignored (returns all statuses) to avoid
     * leaking the list of valid statuses in error responses and to keep UX smooth
     * when clients pass stale or unknown status strings.
     */
    public function listForClient(User $client, array $filters): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        // Only apply status filter when the value is a known valid status.
        $validStatuses = [
            Order::STATUS_PENDING,
            Order::STATUS_CONFIRMED,
            Order::STATUS_COMPLETED,
            Order::STATUS_CANCELLED,
        ];

        $statusFilter = isset($filters['status']) && in_array($filters['status'], $validStatuses, true)
            ? $filters['status']
            : null;

        return Order::with(['store:id,store_name', 'items'])
            ->forClient($client->id)
            ->when($statusFilter, fn ($q) => $q->where('status', $statusFilter))
            ->when(! empty($filters['date_from']), fn ($q) => $q->whereDate('created_at', '>=', $filters['date_from']))
            ->when(! empty($filters['date_to']),   fn ($q) => $q->whereDate('created_at', '<=', $filters['date_to']))
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Paginated order list for all stores belonging to a merchant.
     */
    public function listForMerchant(User $merchant, array $filters): LengthAwarePaginator
    {
        $storeIds = $merchant->stores()->pluck('id');

        $perPage = min((int) ($filters['per_page'] ?? 15), 100);

        $query = Order::with(['client:id,name,email,phone', 'store:id,store_name', 'items'])
            ->whereIn('store_id', $storeIds);

        $this->applyCommonFilters($query, $filters);

        return $query->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Find an order by ID, ensuring it belongs to the given client.
     */
    public function findForClient(int $id, User $client): ?Order
    {
        return Order::with(['store:id,store_name', 'items.product:id,name,image'])
            ->where('id', $id)
            ->where('client_id', $client->id)
            ->first();
    }

    /**
     * Find an order by ID, ensuring it belongs to one of the merchant's stores.
     */
    public function findForMerchant(int $id, User $merchant): ?Order
    {
        $storeIds = $merchant->stores()->pluck('id');

        return Order::with(['client:id,name,email,phone', 'store:id,store_name', 'items.product:id,name,image'])
            ->where('id', $id)
            ->whereIn('store_id', $storeIds)
            ->first();
    }

    public function listForAdmin(array $filters): LengthAwarePaginator
    {
        $perPage = min((int) ($filters['per_page'] ?? 15), 100);
        $query = Order::with(['client:id,name,email,phone', 'store:id,store_name', 'items']);

        $this->applyCommonFilters($query, $filters);

        return $query->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    public function findForAdmin(int $id): ?Order
    {
        return Order::with([
            'client:id,name,email,phone',
            'store:id,store_name,user_id',
            'store.owner:id,name,email,phone',
            'items.product:id,name,image',
        ])->find($id);
    }

    /**
     * Update the status of an order (merchant action).
     *
     * ATOMICITY: The status transition and stock restoration happen inside a
     * single transaction with a row-level lock (lockForUpdate) on the order.
     * A conditional UPDATE (`WHERE status != 'cancelled'`) is used as the
     * authoritative gate: it atomically records the new status only when the
     * order is not already cancelled.  If affected rows == 0 the order was
     * already cancelled by a concurrent request; stock is NOT restored again,
     * making double-cancellation idempotent under concurrency.
     *
     * SECURITY: The status column is written via raw DB::table() update (not
     * mass-assignment) because `status` is excluded from Order::$fillable.
     */
    public function updateStatus(Order $order, string $status): Order
    {
        DB::transaction(function () use ($order, $status) {
            // Lock this order row for the duration of the transaction.
            $locked = Order::lockForUpdate()->find($order->id);

            if (! $locked) {
                return; // order deleted concurrently — nothing to do
            }

            $previousStatus = $locked->status;

            // Conditional update: only proceed if the order has not already
            // been cancelled by a concurrent request.
            $affected = DB::table('orders')
                ->where('id', $order->id)
                ->where('status', '!=', Order::STATUS_CANCELLED)
                ->update(['status' => $status, 'updated_at' => now()]);

            // Restore stock only when we were the request that actually
            // performed the transition (affected == 1).
            if ($affected > 0 && $status === Order::STATUS_CANCELLED) {
                $this->restoreStockForOrder($order);
            }

            // Sync the in-memory instance for the caller.
            $order->status = $affected > 0 ? $status : $previousStatus;
        });

        return $order->fresh(['store', 'client', 'items']);
    }

    /**
     * Cancel an order on behalf of a client (sets status to cancelled).
     *
     * ATOMICITY: Identical concurrency guarantee to updateStatus().
     * The conditional UPDATE (`WHERE status = 'pending_review'`) acts as an atomic
     * compare-and-swap: only the first concurrent request wins and restores
     * stock; subsequent identical requests are no-ops.
     *
     * SECURITY: `status` is written via raw DB update; excluded from $fillable.
     */
    public function cancelForClient(Order $order): Order
    {
        DB::transaction(function () use ($order) {
            // Lock this order row for the duration of the transaction.
            Order::lockForUpdate()->find($order->id);

            // Conditional update: only a 'pending_review' order can be
            // client-cancelled.
            // This is the atomic gate — if two requests race, only one will
            // match the WHERE clause and trigger stock restoration.
            $affected = DB::table('orders')
                ->where('id', $order->id)
                ->where('status', Order::STATUS_PENDING)
                ->update(['status' => Order::STATUS_CANCELLED, 'updated_at' => now()]);

            if ($affected > 0) {
                $this->restoreStockForOrder($order);
            }

            $order->status = Order::STATUS_CANCELLED;
        });

        return $order->fresh(['store', 'items']);
    }

    /**
     * Restore product stock for every item in an order.
     *
     * Each product's quantity is incremented and its status flipped from
     * 'out_of_stock' back to 'active' atomically in a single UPDATE per row.
     * Must be called inside a transaction that has already acquired a row lock
     * on the parent order (so no other request is in the same transaction).
     *
     * Items with a null or missing product (soft-deleted products) are skipped
     * gracefully — the DB::table() WHERE clause simply matches 0 rows.
     */
    private function restoreStockForOrder(Order $order): void
    {
        $order->loadMissing('items');

        foreach ($order->items as $item) {
            if (! $item->product_id || ! $item->quantity) {
                continue;
            }

            $qty = (int) $item->quantity;

            DB::table('products')
                ->where('id', $item->product_id)
                ->update([
                    'quantity' => DB::raw("quantity + {$qty}"),
                    // Flip back to 'active' only if the product went out_of_stock;
                    // products manually set to 'inactive' stay inactive.
                    'status'   => DB::raw(
                        "CASE WHEN status = 'out_of_stock' THEN 'active' ELSE status END"
                    ),
                ]);
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function applyCommonFilters(Builder $query, array $filters): void
    {
        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['date_from'])) {
            $query->whereDate('created_at', '>=', $filters['date_from']);
        }

        if (! empty($filters['date_to'])) {
            $query->whereDate('created_at', '<=', $filters['date_to']);
        }
    }
}
