<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Replit/Render terminate TLS before forwarding requests to PHP. Trust
        // the proxy's forwarded scheme and host so Laravel generates canonical
        // public URLs from the original HTTPS request.
        $middleware->trustProxies(
            at: '*',
            headers: Request::HEADER_X_FORWARDED_FOR |
                Request::HEADER_X_FORWARDED_HOST |
                Request::HEADER_X_FORWARDED_PORT |
                Request::HEADER_X_FORWARDED_PROTO |
                Request::HEADER_X_FORWARDED_PREFIX,
        );

        // Security headers on every response, including unmatched-route 404s.
        // Registering globally (prepend) ensures the header is set even when no
        // API route matches, which would otherwise bypass the `api` group stack.
        $middleware->prepend(\App\Http\Middleware\AddSecurityHeaders::class);

        // Provide $errors variable in Blade views used by web routes (e.g., login form).
        // This middleware shares validation errors and old input from session to views.
        $middleware->web(append: [
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
        ]);

        // Security headers on every API response (also in api group for coverage)
        $middleware->api(prepend: [
            \Illuminate\Http\Middleware\HandleCors::class,
        ]);

        // Apply the general API rate limiter to all API routes.
        $middleware->throttleApi('api');

        // Register named middleware aliases
        $middleware->alias([
            'role'                 => \App\Http\Middleware\EnsureRole::class,
            'user.active'          => \App\Http\Middleware\EnsureUserIsActive::class,
            'merchant.subscription' => \App\Http\Middleware\EnsureMerchantHasSubscription::class,
            'admin.web'            => \App\Http\Middleware\EnsureAdminWeb::class,
        ]);

        // EnsureUserIsActive is NOT appended to the 'api' group here because the
        // 'api' group runs BEFORE route-level middlewares such as auth:sanctum.
        // If it were here, $request->user() would always be null (auth hasn't
        // resolved yet) and the ban check would never fire.
        //
        // Instead it is applied as 'user.active' alias directly on every route
        // group that already has auth:sanctum — see routes/api.php.
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // JSON 404 for all /api/* requests
        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Resource not found.',
                    'data'    => null,
                ], 404);
            }
        });

        // JSON 401 for unauthenticated API requests
        $exceptions->render(function (
            \Illuminate\Auth\AuthenticationException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated. Please provide a valid token.',
                    'data'    => null,
                ], 401);
            }
        });

        // JSON 422 for validation errors — use our standard envelope
        $exceptions->render(function (
            \Illuminate\Validation\ValidationException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed.',
                    'data'    => null,
                    'errors'  => $e->errors(),
                ], 422);
            }
        });

        // JSON 403 for policy / gate authorization failures
        $exceptions->render(function (
            \Illuminate\Auth\Access\AuthorizationException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Forbidden. You do not have permission to perform this action.',
                    'data'    => null,
                ], 403);
            }
        });

        // JSON 429 for AI rate limit exceeded
        $exceptions->render(function (
            \App\Exceptions\AiRateLimitException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage(),
                    'data'    => null,
                ], 429);
            }
        });

        // JSON 429 for framework-level throttle middleware (ThrottleRequestsException).
        $exceptions->render(function (
            \Illuminate\Http\Exceptions\ThrottleRequestsException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Too many requests. Please slow down.',
                    'data'    => null,
                ], 429);
            }
        });

        // JSON 405 for method-not-allowed
        $exceptions->render(function (
            \Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException $e,
            Request $request
        ) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Method not allowed.',
                    'data'    => null,
                ], 405);
            }
        });

        // JSON 500 for all unhandled exceptions — hide details in production
        $exceptions->render(function (
            \Throwable $e,
            Request $request
        ) {
            if ($request->is('api/*') && app()->isProduction()) {
                return response()->json([
                    'success' => false,
                    'message' => 'An unexpected error occurred. Please try again later.',
                    'data'    => null,
                ], 500);
            }
        });
    })
    ->create();
