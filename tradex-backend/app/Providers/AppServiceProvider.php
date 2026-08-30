<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $rootUrl = trim((string) env('APP_URL', 'https://tradex-v2us.onrender.com'));
        if ($rootUrl !== '') {
            $normalized = rtrim($rootUrl, '/');
            $isLocal = preg_match('/^(https?:\/\/)?(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?$/i', $normalized) === 1;
            if (! $isLocal) {
                URL::forceRootUrl($normalized);
            }
        }

        // Stricter limiter for brute-force-sensitive auth endpoints
        // (login, client/merchant registration). Keyed by IP so a single
        // client can't lock legitimate users out of their own accounts,
        // and scoped separately from the general API rate limits.
        // Brute-force protection for sensitive auth endpoints (login, register).
        // Keyed by IP only — keeps failed-auth lockouts scoped to the attacker.
        RateLimiter::for('auth', function ($request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        // General API rate limiter — 60 requests/minute per authenticated user
        // (by user ID so shared IPs don't collide), or per IP for guests.
        RateLimiter::for('api', function ($request) {
            return Limit::perMinute(60)->by(
                $request->user()?->id ?: $request->ip()
            );
        });

        // AI SaaS rate limiter — stricter limit since each call hits a paid
        // external provider.  Keyed by user ID (or IP for unauthenticated).
        RateLimiter::for('ai', function ($request) {
            return Limit::perMinute(20)->by(
                $request->user()?->id ?: $request->ip()
            );
        });

        // ── Email verification URL (Phase 2 — Step 3) ────────────────────────
        // Override the default Laravel verification URL so it points to our
        // named API route (api.v1.auth.verification.verify) instead of the
        // framework default ('verification.verify' on a web controller).
        //
        // The Flutter app intercepts this URL via a deep-link / custom URL
        // scheme and calls the endpoint to complete verification in-app.
        // The link expires in 60 minutes (aligns with password reset expiry).
        VerifyEmail::createUrlUsing(function ($notifiable) {
            return URL::temporarySignedRoute(
                'api.v1.auth.verification.verify',
                now()->addMinutes(60),
                [
                    'id'   => $notifiable->getKey(),
                    'hash' => sha1($notifiable->getEmailForVerification()),
                ]
            );
        });
    }
}
