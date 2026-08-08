<?php

namespace App\Http\Middleware;

use App\Contracts\Services\SubscriptionServiceInterface;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Require a merchant's current trial or paid subscription entitlement.
 *
 * Subscription expiration is intentionally separate from account moderation:
 * expired merchants keep their account and can use renewal-related routes.
 */
class EnsureMerchantHasSubscription
{
    public function __construct(
        private readonly SubscriptionServiceInterface $subscriptionService,
    ) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $this->subscriptionService->getActiveForMerchant($user)) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'An active trial or paid subscription is required to access merchant business features.',
            'data'    => null,
        ], 403);
    }
}