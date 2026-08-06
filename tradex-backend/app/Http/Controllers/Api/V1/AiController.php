<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\AiProviderException;
use App\Exceptions\AiRateLimitException;
use App\Http\Requests\AI\CustomerReplyRequest;
use App\Http\Requests\AI\MarketingContentRequest;
use App\Http\Requests\AI\ProductDescriptionRequest;
use App\Services\AI\AiAnalyticsService;
use App\Services\AI\AiUsageService;
use App\Services\AI\CustomerReplyService;
use App\Services\AI\MarketingContentService;
use App\Services\AI\ProductDescriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * AI SaaS endpoints.
 *
 * All routes require auth:sanctum.
 * Merchant tools additionally require role:merchant.
 * Admin analytics requires role:admin.
 *
 * Error contract:
 *   429 — AiRateLimitException (daily/monthly limit exceeded)
 *   503 — AiProviderException  (provider unavailable or misconfigured)
 */
class AiController extends BaseApiController
{
    public function __construct(
        private readonly ProductDescriptionService $productDescriptionService,
        private readonly MarketingContentService   $marketingContentService,
        private readonly CustomerReplyService      $customerReplyService,
        private readonly AiAnalyticsService        $analyticsService,
        private readonly AiUsageService            $usageService,
    ) {}

    // -------------------------------------------------------------------------
    // POST /api/v1/ai/product-description  (merchant)
    // -------------------------------------------------------------------------

    /**
     * Generate a professional product description.
     *
     * Body: { context: string, language?: string }
     */
    public function productDescription(ProductDescriptionRequest $request): JsonResponse
    {
        try {
            $result = $this->productDescriptionService->generate([
                'user'     => $request->user(),
                'context'  => $request->input('context'),
                'language' => $request->input('language', 'English'),
            ]);

            return $this->success($result, 'Product description generated successfully.');

        } catch (AiRateLimitException $e) {
            return $this->error($e->getMessage(), 429);
        } catch (AiProviderException $e) {
            return $this->error($e->getMessage(), 503);
        }
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/ai/marketing-content  (merchant)
    // -------------------------------------------------------------------------

    /**
     * Generate a marketing caption, hashtags, and tagline.
     *
     * Body: { context: string, language?: string }
     */
    public function marketingContent(MarketingContentRequest $request): JsonResponse
    {
        try {
            $result = $this->marketingContentService->generate([
                'user'     => $request->user(),
                'context'  => $request->input('context'),
                'language' => $request->input('language', 'English'),
            ]);

            return $this->success($result, 'Marketing content generated successfully.');

        } catch (AiRateLimitException $e) {
            return $this->error($e->getMessage(), 429);
        } catch (AiProviderException $e) {
            return $this->error($e->getMessage(), 503);
        }
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/ai/customer-reply  (merchant)
    // -------------------------------------------------------------------------

    /**
     * Suggest a professional reply to a customer message.
     *
     * Body: { context: string, language?: string, store_name?: string }
     */
    public function customerReply(CustomerReplyRequest $request): JsonResponse
    {
        try {
            $result = $this->customerReplyService->generate([
                'user'       => $request->user(),
                'context'    => $request->input('context'),
                'language'   => $request->input('language',   'English'),
                'store_name' => $request->input('store_name'),
            ]);

            return $this->success($result, 'Customer reply generated successfully.');

        } catch (AiRateLimitException $e) {
            return $this->error($e->getMessage(), 429);
        } catch (AiProviderException $e) {
            return $this->error($e->getMessage(), 503);
        }
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/ai/analytics  (admin)
    // -------------------------------------------------------------------------

    /**
     * Generate AI-powered platform analytics insights.
     *
     * Query params:
     *   type         overview | products | orders | users  (default: overview)
     *   period_days  int 1–365                             (default: 30)
     *   language     string                                (default: English)
     */
    public function analytics(Request $request): JsonResponse
    {
        $request->validate([
            'type'        => ['nullable', 'string', 'in:overview,products,orders,users'],
            'period_days' => ['nullable', 'integer', 'min:1', 'max:365'],
            'language'    => ['nullable', 'string', 'max:50'],
        ]);

        try {
            $result = $this->analyticsService->generate([
                'user'        => $request->user(),
                'type'        => $request->input('type',        'overview'),
                'period_days' => (int) $request->input('period_days', 30),
                'language'    => $request->input('language',   'English'),
            ]);

            return $this->success($result, 'Analytics insights generated successfully.');

        } catch (AiRateLimitException $e) {
            return $this->error($e->getMessage(), 429);
        } catch (AiProviderException $e) {
            return $this->error($e->getMessage(), 503);
        }
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/ai/usage  (auth — any role)
    // -------------------------------------------------------------------------

    /**
     * Return the authenticated user's AI usage summary for today and this month.
     */
    public function usage(Request $request): JsonResponse
    {
        $summary = $this->usageService->getUsageSummary($request->user());

        return $this->success($summary, 'AI usage retrieved successfully.');
    }
}
