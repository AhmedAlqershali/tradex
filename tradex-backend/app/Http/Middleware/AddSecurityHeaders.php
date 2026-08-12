<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Attach security-relevant HTTP response headers to every API response.
 *
 * Headers applied:
 *
 * X-Content-Type-Options: nosniff
 *   Prevents MIME-type sniffing. Even though this is a pure JSON API,
 *   it is a defense-in-depth measure.
 *
 * X-Frame-Options: DENY
 *   Prevents the API from being embedded in an iframe (clickjacking
 *   protection). Irrelevant for a headless API but still best practice.
 *
 * X-XSS-Protection: 0
 *   Disables the legacy browser XSS auditor, which can introduce new
 *   vulnerabilities. Modern browsers use CSP instead.
 *
 * Referrer-Policy: no-referrer
 *   Prevents the browser from sending the Referer header in outbound
 *   requests, avoiding leaking URLs containing tokens or IDs.
 *
 * Permissions-Policy: camera=(), microphone=(), geolocation=()
 *   Disables browser feature APIs not required by this API.
 *
 * Strict-Transport-Security (HSTS):
 *   Only added in production to instruct clients to use HTTPS exclusively.
 *   Skipped in local/testing environments to avoid breaking HTTP dev servers.
 *
 * Content-Security-Policy:
 *   API responses keep a restrictive `default-src 'none'` policy because the
 *   API serves JSON only. Browser-facing admin pages allow only same-origin
 *   assets so the dashboard's compiled CSS and JavaScript can load.
 *
 * Cache-Control: no-store
 *   Prevents sensitive API responses from being cached in shared proxies
 *   or browsers. Individual endpoints may override this if appropriate.
 */
class AddSecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '0');
        $response->headers->set('Referrer-Policy', 'no-referrer');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
        $contentSecurityPolicy = $request->is('api/*')
            ? "default-src 'none'"
            : "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:";

        $response->headers->set('Content-Security-Policy', $contentSecurityPolicy);
        $response->headers->set('Cache-Control', 'no-store, private');

        // HSTS — only in production; prevents accidental lock-out during development
        if (app()->isProduction()) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=63072000; includeSubDomains; preload'
            );
        }

        return $response;
    }
}
