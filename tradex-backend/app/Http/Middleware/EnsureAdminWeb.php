<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Protect the Laravel admin web surface with the session guard.
 *
 * The mobile/API role middleware intentionally returns JSON. This middleware
 * is kept separate so browser requests get a login redirect while retaining
 * the same server-side role and active-account checks.
 */
class EnsureAdminWeb
{
    public function handle(Request $request, Closure $next): Response
    {
        $guard = Auth::guard('web');

        if (! $guard->check()) {
            return redirect()->guest(route('admin.login'));
        }

        // Refresh the authenticated record so role/status changes are honored
        // even when a guard or a test has cached an older model instance.
        $user = $guard->user()?->fresh();

        if (! $user instanceof User || ! $user->isAdmin() || ! $user->isActive()) {
            $guard->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            abort(403, 'Only active admin accounts may access this dashboard.');
        }

        return $next($request);
    }
}