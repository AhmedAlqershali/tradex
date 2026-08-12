<?php

namespace App\Services;

use App\Contracts\Services\AdminDashboardServiceInterface;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AdminDashboardService implements AdminDashboardServiceInterface
{
    // -------------------------------------------------------------------------
    // Dashboard
    // -------------------------------------------------------------------------

    public function getDashboard(): array
    {
        // ── System overview (two aggregation queries) ──────────────────────────
        $userStats = DB::table('users')
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN role = 'client'   THEN 1 ELSE 0 END) as clients,
                SUM(CASE WHEN role = 'merchant' THEN 1 ELSE 0 END) as merchants,
                SUM(CASE WHEN role = 'merchant' AND status = 'active' THEN 1 ELSE 0 END) as active_merchants,
                SUM(CASE WHEN role = 'admin'    THEN 1 ELSE 0 END) as admins
            ")->first();

        $storeStats = DB::table('stores')
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'active'    THEN 1 ELSE 0 END) as active,
                SUM(CASE WHEN status = 'inactive'  THEN 1 ELSE 0 END) as inactive,
                SUM(CASE WHEN status = 'suspended' THEN 1 ELSE 0 END) as suspended
            ")->first();

        $productStats = DB::table('products')
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'active'       THEN 1 ELSE 0 END) as active,
                SUM(CASE WHEN status = 'inactive'     THEN 1 ELSE 0 END) as inactive,
                SUM(CASE WHEN status = 'out_of_stock' THEN 1 ELSE 0 END) as out_of_stock
            ")->first();

        $orderStats = DB::table('orders')
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending'    THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'confirmed'  THEN 1 ELSE 0 END) as confirmed,
                SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing,
                SUM(CASE WHEN status = 'completed'  THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'cancelled'  THEN 1 ELSE 0 END) as cancelled,
                SUM(CASE WHEN status = 'completed'  THEN total_amount ELSE 0 END) as total_sales
            ")->first();

        $activeSubscriptionQuery = DB::table('subscriptions')
            ->where('status', 'active')
            ->where(function ($query) {
                $query->whereNull('ends_at')
                    ->orWhere('ends_at', '>', now());
            });

        $subscriptionStats = [
            'active' => (clone $activeSubscriptionQuery)->count(),
            'trials' => (clone $activeSubscriptionQuery)
                ->where('type', 'trial')
                ->distinct('user_id')
                ->count('user_id'),
        ];

        // ── Marketplace activity snapshots ─────────────────────────────────────
        $newestUsers = User::orderByDesc('created_at')->limit(5)->get(['id', 'name', 'email', 'role', 'status', 'created_at']);

        $newestStores = Store::with('owner:id,name,email')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get(['id', 'user_id', 'store_name', 'status', 'created_at']);

        $newestProducts = Product::with(['store:id,store_name', 'category:id,name'])
            ->orderByDesc('created_at')
            ->limit(5)
            ->get(['id', 'store_id', 'category_id', 'name', 'price', 'status', 'created_at']);

        $recentOrders = Order::with(['store:id,store_name', 'client:id,name,email'])
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        return [
            'system_overview' => [
                'users' => [
                    'total'            => (int) ($userStats->total            ?? 0),
                    'clients'          => (int) ($userStats->clients          ?? 0),
                    'merchants'        => (int) ($userStats->merchants        ?? 0),
                    'active_merchants' => (int) ($userStats->active_merchants ?? 0),
                    'admins'           => (int) ($userStats->admins           ?? 0),
                ],
                'stores' => [
                    'total'     => (int) ($storeStats->total     ?? 0),
                    'active'    => (int) ($storeStats->active    ?? 0),
                    'inactive'  => (int) ($storeStats->inactive  ?? 0),
                    'suspended' => (int) ($storeStats->suspended ?? 0),
                ],
                'products' => [
                    'total'        => (int) ($productStats->total        ?? 0),
                    'active'       => (int) ($productStats->active       ?? 0),
                    'inactive'     => (int) ($productStats->inactive     ?? 0),
                    'out_of_stock' => (int) ($productStats->out_of_stock ?? 0),
                ],
                'orders' => [
                    'total'      => (int) ($orderStats->total      ?? 0),
                    'pending'    => (int) ($orderStats->pending    ?? 0),
                    'confirmed'  => (int) ($orderStats->confirmed  ?? 0),
                    'processing' => (int) ($orderStats->processing ?? 0),
                    'completed'  => (int) ($orderStats->completed  ?? 0),
                    'cancelled'  => (int) ($orderStats->cancelled  ?? 0),
                ],
                'total_sales' => round((float) ($orderStats->total_sales ?? 0), 2),
                'subscriptions' => [
                    'active' => (int) $subscriptionStats['active'],
                    'trials' => (int) $subscriptionStats['trials'],
                ],
            ],
            'marketplace' => [
                'newest_users'    => $newestUsers,
                'newest_stores'   => $newestStores,
                'newest_products' => $newestProducts,
                'recent_orders'   => $recentOrders,
            ],
        ];
    }

    // -------------------------------------------------------------------------
    // Analytics
    // -------------------------------------------------------------------------

    public function getAnalytics(): array
    {
        $now             = Carbon::now();
        $twelveMonthsAgo = $now->copy()->subMonths(11)->startOfMonth();
        $exprs           = $this->yearMonthExpressions();

        // ── Monthly sales (last 12 months) ─────────────────────────────────────
        $monthlySales = DB::table('orders')
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

        // ── Monthly order stats by status (last 12 months) ────────────────────
        $orderStats = DB::table('orders')
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        // ── User growth — monthly registrations (last 12 months) ──────────────
        $userGrowth = DB::table('users')
            ->where('created_at', '>=', $twelveMonthsAgo)
            ->selectRaw("{$exprs['select']}, COUNT(*) as new_users")
            ->groupByRaw($exprs['group'])
            ->orderByRaw($exprs['order'])
            ->get()
            ->map(fn ($row) => [
                'year'      => (int) $row->year,
                'month'     => (int) $row->month,
                'new_users' => (int) $row->new_users,
            ]);

        // ── Merchant growth — monthly new merchants (last 12 months) ──────────
        $merchantGrowth = DB::table('users')
            ->where('role', 'merchant')
            ->where('created_at', '>=', $twelveMonthsAgo)
            ->selectRaw("{$exprs['select']}, COUNT(*) as new_merchants")
            ->groupByRaw($exprs['group'])
            ->orderByRaw($exprs['order'])
            ->get()
            ->map(fn ($row) => [
                'year'          => (int) $row->year,
                'month'         => (int) $row->month,
                'new_merchants' => (int) $row->new_merchants,
            ]);

        // ── Product statistics by category ─────────────────────────────────────
        $productsByCategory = DB::table('products')
            ->join('categories', 'products.category_id', '=', 'categories.id')
            ->selectRaw('categories.name as category_name, COUNT(products.id) as count')
            ->groupBy('categories.id', 'categories.name')
            ->orderByDesc('count')
            ->get()
            ->map(fn ($row) => [
                'category' => $row->category_name,
                'count'    => (int) $row->count,
            ]);

        $productsByStatus = DB::table('products')
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        return [
            'sales_statistics' => [
                'monthly_sales' => $monthlySales,
            ],
            'order_statistics' => [
                'by_status' => [
                    'pending'    => (int) ($orderStats['pending']    ?? 0),
                    'confirmed'  => (int) ($orderStats['confirmed']  ?? 0),
                    'processing' => (int) ($orderStats['processing'] ?? 0),
                    'completed'  => (int) ($orderStats['completed']  ?? 0),
                    'cancelled'  => (int) ($orderStats['cancelled']  ?? 0),
                ],
            ],
            'user_growth'     => $userGrowth,
            'merchant_growth' => $merchantGrowth,
            'product_statistics' => [
                'by_category' => $productsByCategory,
                'by_status'   => [
                    'active'       => (int) ($productsByStatus['active']       ?? 0),
                    'inactive'     => (int) ($productsByStatus['inactive']     ?? 0),
                    'out_of_stock' => (int) ($productsByStatus['out_of_stock'] ?? 0),
                ],
            ],
        ];
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

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
