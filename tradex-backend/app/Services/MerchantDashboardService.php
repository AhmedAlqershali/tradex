<?php

namespace App\Services;

use App\Contracts\Services\MerchantDashboardServiceInterface;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class MerchantDashboardService implements MerchantDashboardServiceInterface
{
    /** Products whose quantity is at or below this threshold are flagged as low-stock. */
    public const LOW_STOCK_THRESHOLD = 10;

    // -------------------------------------------------------------------------
    // Dashboard
    // -------------------------------------------------------------------------

    public function getDashboard(User $merchant): array
    {
        $storeIds = $merchant->stores()->pluck('id');

        // ── Product statistics (single aggregation query) ──────────────────────
        $productStats = DB::table('products')
            ->whereIn('store_id', $storeIds)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'active'        THEN 1 ELSE 0 END) as active,
                SUM(CASE WHEN status = 'out_of_stock'  THEN 1 ELSE 0 END) as out_of_stock,
                SUM(CASE WHEN status = 'active' AND quantity > 0 AND quantity <= " . self::LOW_STOCK_THRESHOLD . " THEN 1 ELSE 0 END) as low_stock
            ")->first();

        // ── Order statistics (single aggregation query) ────────────────────────
        $orderStats = DB::table('orders')
            ->whereIn('store_id', $storeIds)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending'    THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'confirmed'  THEN 1 ELSE 0 END) as confirmed,
                SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing,
                SUM(CASE WHEN status = 'completed'  THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'cancelled'  THEN 1 ELSE 0 END) as cancelled,
                SUM(CASE WHEN status = 'completed'  THEN total_amount ELSE 0 END) as total_sales
            ")->first();

        // ── Recent orders ──────────────────────────────────────────────────────
        $recentOrders = Order::with(['client', 'items'])
            ->whereIn('store_id', $storeIds)
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        // ── Top selling products ───────────────────────────────────────────────
        $topProducts = Product::with(['images', 'category'])
            ->whereIn('store_id', $storeIds)
            ->orderByDesc('total_sold')
            ->limit(5)
            ->get();

        // ── Low inventory products ─────────────────────────────────────────────
        $lowInventory = Product::with(['images'])
            ->whereIn('store_id', $storeIds)
            ->where('status', 'active')
            ->where('quantity', '>', 0)
            ->where('quantity', '<=', self::LOW_STOCK_THRESHOLD)
            ->orderBy('quantity')
            ->limit(10)
            ->get();

        return [
            'products' => [
                'total'        => (int) ($productStats->total        ?? 0),
                'active'       => (int) ($productStats->active       ?? 0),
                'out_of_stock' => (int) ($productStats->out_of_stock ?? 0),
                'low_stock'    => (int) ($productStats->low_stock    ?? 0),
            ],
            'orders' => [
                'total'      => (int) ($orderStats->total      ?? 0),
                'pending'    => (int) ($orderStats->pending    ?? 0),
                'confirmed'  => (int) ($orderStats->confirmed  ?? 0),
                'processing' => (int) ($orderStats->processing ?? 0),
                'completed'  => (int) ($orderStats->completed  ?? 0),
                'cancelled'  => (int) ($orderStats->cancelled  ?? 0),
            ],
            'total_sales'    => round((float) ($orderStats->total_sales ?? 0), 2),
            'recent_orders'  => $recentOrders,
            'top_products'   => $topProducts,
            'low_inventory'  => $lowInventory,
        ];
    }

    // -------------------------------------------------------------------------
    // Analytics
    // -------------------------------------------------------------------------

    public function getAnalytics(User $merchant): array
    {
        $storeIds = $merchant->stores()->pluck('id');
        $now      = Carbon::now();

        // ── Sales overview ─────────────────────────────────────────────────────
        $thisMonthStart = $now->copy()->startOfMonth();
        $lastMonthStart = $now->copy()->subMonth()->startOfMonth();
        $lastMonthEnd   = $now->copy()->subMonth()->endOfMonth();

        $totalRevenue     = (float) Order::whereIn('store_id', $storeIds)->where('status', 'completed')->sum('total_amount');
        $thisMonthRevenue = (float) Order::whereIn('store_id', $storeIds)->where('status', 'completed')->where('created_at', '>=', $thisMonthStart)->sum('total_amount');
        $lastMonthRevenue = (float) Order::whereIn('store_id', $storeIds)->where('status', 'completed')->whereBetween('created_at', [$lastMonthStart, $lastMonthEnd])->sum('total_amount');

        $growthPercent = $lastMonthRevenue > 0
            ? round((($thisMonthRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100, 2)
            : ($thisMonthRevenue > 0 ? 100.0 : 0.0);

        // ── Order statistics by status ─────────────────────────────────────────
        $orderStatusCounts = DB::table('orders')
            ->whereIn('store_id', $storeIds)
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        // ── Monthly sales — last 12 months ─────────────────────────────────────
        $twelveMonthsAgo = $now->copy()->subMonths(11)->startOfMonth();
        $exprs           = $this->yearMonthExpressions();

        $monthlySales = DB::table('orders')
            ->whereIn('store_id', $storeIds)
            ->where('status', 'completed')
            ->where('created_at', '>=', $twelveMonthsAgo)
            ->selectRaw("{$exprs['select']}, SUM(total_amount) as revenue, COUNT(*) as order_count")
            ->groupByRaw($exprs['group'])
            ->orderByRaw($exprs['order'])
            ->get()
            ->map(fn ($row) => [
                'year'        => (int) $row->year,
                'month'       => (int) $row->month,
                'revenue'     => round((float) $row->revenue, 2),
                'order_count' => (int) $row->order_count,
            ]);

        // ── Best products ──────────────────────────────────────────────────────
        $bestProducts = Product::with(['images', 'category'])
            ->whereIn('store_id', $storeIds)
            ->orderByDesc('total_sold')
            ->limit(10)
            ->get()
            ->map(fn ($p) => [
                'id'         => $p->id,
                'name'       => $p->name,
                'price'      => (float) $p->price,
                'total_sold' => (int) $p->total_sold,
                'quantity'   => (int) $p->quantity,
                'status'     => $p->status,
                'category'   => $p->category?->name,
                'image'      => $p->images->first()?->path,
            ]);

        // ── Store performance ──────────────────────────────────────────────────
        $stores = Store::withCount(['products', 'orders'])
            ->where('user_id', $merchant->id)
            ->get();

        $storeRevenues = DB::table('orders')
            ->whereIn('store_id', $storeIds)
            ->where('status', 'completed')
            ->selectRaw('store_id, SUM(total_amount) as revenue, COUNT(*) as order_count')
            ->groupBy('store_id')
            ->get()
            ->keyBy('store_id');

        $storePerformance = $stores->map(fn ($store) => [
            'id'           => $store->id,
            'store_name'   => $store->store_name,
            'status'       => $store->status,
            'products'     => $store->products_count,
            'total_orders' => $store->orders_count,
            'revenue'      => round((float) ($storeRevenues[$store->id]->revenue ?? 0), 2),
        ]);

        return [
            'sales_overview' => [
                'total_revenue'      => round($totalRevenue, 2),
                'this_month_revenue' => round($thisMonthRevenue, 2),
                'last_month_revenue' => round($lastMonthRevenue, 2),
                'growth_percent'     => $growthPercent,
            ],
            'order_statistics' => [
                'by_status' => [
                    'pending'    => (int) ($orderStatusCounts['pending']    ?? 0),
                    'confirmed'  => (int) ($orderStatusCounts['confirmed']  ?? 0),
                    'processing' => (int) ($orderStatusCounts['processing'] ?? 0),
                    'completed'  => (int) ($orderStatusCounts['completed']  ?? 0),
                    'cancelled'  => (int) ($orderStatusCounts['cancelled']  ?? 0),
                ],
            ],
            'monthly_sales'    => $monthlySales,
            'best_products'    => $bestProducts,
            'store_performance' => $storePerformance,
        ];
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Returns DB-driver-appropriate SQL expressions for grouping by year + month.
     * Supports MySQL (production) and SQLite (test suite).
     */
    private function yearMonthExpressions(): array
    {
        if (DB::connection()->getDriverName() === 'sqlite') {
            return [
                'select' => "CAST(strftime('%Y', created_at) AS INTEGER) as year, CAST(strftime('%m', created_at) AS INTEGER) as month",
                'group'  => "strftime('%Y', created_at), strftime('%m', created_at)",
                'order'  => "strftime('%Y', created_at) ASC, strftime('%m', created_at) ASC",
            ];
        }

        return [
            'select' => 'YEAR(created_at) as year, MONTH(created_at) as month',
            'group'  => 'YEAR(created_at), MONTH(created_at)',
            'order'  => 'YEAR(created_at) ASC, MONTH(created_at) ASC',
        ];
    }
}
