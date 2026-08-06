<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Block banned or inactive users on every authenticated API request.
 *
 * Applied after auth:sanctum so $request->user() is always resolved.
 * If the user's status is not 'active', the current token is revoked
 * immediately (so the client must re-authenticate if the ban is lifted),
 * and a 403 JSON response is returned.
 */
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // Always fetch a fresh copy from the database.
        //
        // The auth guard caches the resolved User instance in memory for the
        // lifetime of the application container (which in tests spans multiple
        // simulated HTTP requests in the same test method). Without ->fresh(),
        // a user banned between two consecutive requests in the same test would
        // still appear as 'active' here because the guard returns the stale
        // cached instance.
        //
        // In production each real HTTP request has its own process/container
        // so caching is never an issue, but the ->fresh() DB hit is cheap
        // (a single indexed PK lookup) and ensures correctness in all contexts.
        if ($user) {
            $user = $user->fresh();
        }

        if ($user && $user->status !== 'active') {
            // Invalidate this token so further requests with the same
            // bearer token fail at the auth:sanctum layer, not here.
            $request->user()->currentAccessToken()->delete();

            $message = match ($user->status) {
                'banned'   => 'Your account has been banned. Please contact support.',
                'inactive' => 'Your account is inactive. Please contact support.',
                default    => 'Your account is not active.',
            };

            return response()->json([
                'success' => false,
                'message' => $message,
                'data'    => null,
            ], 403);
        }

        return $next($request);
    }
}
