<?php

namespace App\Services\AI;

use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Models\AiUsage;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;

/**
 * Generates AI-powered business insights from platform data (admin only).
 *
 * Pulls live aggregate data from the database, builds a structured context
 * string, and asks the AI to surface trends, risks, and recommendations.
 */
class AiAnalyticsService implements AiServiceInterface
{
    private const SERVICE_TYPE = AiUsage::TYPE_ANALYTICS;

    private const SYSTEM_PROMPT = <<<'PROMPT'
You are a senior e-commerce business analyst with expertise in marketplace platforms.
Analyse the provided platform metrics and deliver a structured report with:
1. Key Highlights   — 2–3 most notable data points
2. Trends           — patterns or changes worth attention
3. Risks            — any concerning signals in the data
4. Recommendations  — 2–3 specific, actionable next steps

Be data-driven, concise, and prioritise business impact.
PROMPT;

    public function __construct(
        private readonly AiProviderInterface     $provider,
        private readonly AiUsageServiceInterface $usageService,
    ) {}

    /**
     * {@inheritDoc}
     *
     * Expected payload keys:
     *   user        \App\Models\User   — authenticated admin
     *   period_days int                — lookback window in days (default: 30)
     *   type        string             — overview | products | orders | users (default: overview)
     *   language    string             — report language (default: English)
     */
    public function generate(array $payload): array
    {
        $user       = $payload['user'];
        $periodDays = (int) ($payload['period_days'] ?? 30);
        $type       = $payload['type']     ?? 'overview';
        $language   = $payload['language'] ?? 'English';

        $this->usageService->checkLimit($user, self::SERVICE_TYPE);

        $context    = $this->buildContext($periodDays, $type);
        $userPrompt = "Provide a {$type} analytics report in {$language} for the last {$periodDays} days:\n\n{$context}";

        $response = $this->provider->complete(
            self::SYSTEM_PROMPT,
            $userPrompt,
            ['max_tokens' => 1000, 'temperature' => 0.50]
        );

        $tokensUsed = $response['tokens_used'] ?? 0;
        $costUsd    = $response['cost_usd']    ?? 0.0;

        $this->usageService->record($user, self::SERVICE_TYPE, $tokensUsed, 1, $costUsd);
        $this->usageService->recordRequest(
            $user,
            self::SERVICE_TYPE,
            [
                'type'        => $type,
                'period_days' => $periodDays,
                'language'    => $language,
            ],
            $response['result'],
            $tokensUsed,
            1,
            $costUsd,
        );

        return [
            'result'       => $response['result'],
            'tokens_used'  => $tokensUsed,
            'cost_usd'     => $costUsd,
            'service_type' => self::SERVICE_TYPE,
            'period_days'  => $periodDays,
            'type'         => $type,
            'language'     => $language,
        ];
    }

    // -------------------------------------------------------------------------
    // Context builders
    // -------------------------------------------------------------------------

    private function buildContext(int $periodDays, string $type): string
    {
        $since = now()->subDays($periodDays);

        return match ($type) {
            'products' => $this->buildProductsContext($since),
            'orders'   => $this->buildOrdersContext($since),
            'users'    => $this->buildUsersContext($since),
            default    => $this->buildOverviewContext($since),
        };
    }

    private function buildOverviewContext(\Illuminate\Support\Carbon $since): string
    {
        $totalOrders    = Order::where('created_at', '>=', $since)->count();
        $totalRevenue   = Order::where('created_at', '>=', $since)
            ->whereIn('status', ['delivered', 'processing', 'shipped'])
            ->sum('total_price');
        $newUsers       = User::where('created_at', '>=', $since)->where('role', 'client')->count();
        $newMerchants   = User::where('created_at', '>=', $since)->where('role', 'merchant')->count();
        $activeStores   = Store::where('status', 'active')->count();
        $totalProducts  = Product::where('status', 'active')->count();
        $pendingOrders  = Order::where('status', 'pending')->count();

        return <<<DATA
Platform Overview:
- Total orders placed: {$totalOrders}
- Confirmed revenue (delivered + in-progress): {$totalRevenue}
- New client registrations: {$newUsers}
- New merchant registrations: {$newMerchants}
- Active stores: {$activeStores}
- Active product listings: {$totalProducts}
- Currently pending orders: {$pendingOrders}
DATA;
    }

    private function buildProductsContext(\Illuminate\Support\Carbon $since): string
    {
        $totalActive   = Product::where('status', 'active')->count();
        $totalInactive = Product::where('status', 'inactive')->count();
        $outOfStock    = Product::where('status', 'out_of_stock')->count();
        $newListings   = Product::where('created_at', '>=', $since)->count();
        $topSelling    = Product::orderByDesc('total_sold')->limit(5)->get(['name', 'total_sold']);

        $topList = $topSelling->map(fn ($p) => "  - {$p->name}: {$p->total_sold} sold")->implode("\n");

        return <<<DATA
Product Metrics:
- Active listings: {$totalActive}
- Inactive listings: {$totalInactive}
- Out-of-stock listings: {$outOfStock}
- New listings in period: {$newListings}
- Top 5 best-sellers:
{$topList}
DATA;
    }

    private function buildOrdersContext(\Illuminate\Support\Carbon $since): string
    {
        $orders = Order::where('created_at', '>=', $since);

        $total     = $orders->count();
        $pending   = (clone $orders)->where('status', 'pending')->count();
        $confirmed = (clone $orders)->where('status', 'confirmed')->count();
        $shipped   = (clone $orders)->where('status', 'shipped')->count();
        $delivered = (clone $orders)->where('status', 'delivered')->count();
        $cancelled = (clone $orders)->where('status', 'cancelled')->count();
        $revenue   = (clone $orders)->whereIn('status', ['delivered', 'processing', 'shipped'])->sum('total_price');
        $avgOrder  = $total > 0
            ? round((clone $orders)->avg('total_price'), 2)
            : 0;

        return <<<DATA
Order Metrics:
- Total orders: {$total}
- Pending: {$pending}
- Confirmed: {$confirmed}
- Shipped: {$shipped}
- Delivered: {$delivered}
- Cancelled: {$cancelled}
- Confirmed revenue: {$revenue}
- Average order value: {$avgOrder}
DATA;
    }

    private function buildUsersContext(\Illuminate\Support\Carbon $since): string
    {
        $newClients   = User::where('role', 'client')  ->where('created_at', '>=', $since)->count();
        $newMerchants = User::where('role', 'merchant')->where('created_at', '>=', $since)->count();
        $totalClients = User::where('role', 'client')  ->count();
        $totalMerch   = User::where('role', 'merchant')->count();
        $banned       = User::where('status', 'banned')->count();
        $inactive     = User::where('status', 'inactive')->count();

        return <<<DATA
User Metrics:
- Total clients: {$totalClients} (+{$newClients} in period)
- Total merchants: {$totalMerch} (+{$newMerchants} in period)
- Banned accounts: {$banned}
- Inactive accounts: {$inactive}
DATA;
    }
}
