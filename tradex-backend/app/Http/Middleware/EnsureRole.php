<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gate access by user role.
 *
 * Usage in routes:
 *   ->middleware('role:merchant')
 *   ->middleware('role:admin')
 *   ->middleware('role:merchant,admin')   // OR logic — any of the listed roles pass
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user || ! in_array($user->role, $roles, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden. You do not have permission to access this resource.',
                'data'    => null,
            ], 403);
        }

        return $next($request);
    }
}
