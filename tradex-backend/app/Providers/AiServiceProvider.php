<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

/**
 * AiServiceProvider — intentionally empty.
 *
 * AI interface bindings are handled by RepositoryServiceProvider to keep all
 * IoC registrations in one place. This provider is retained as a stub so
 * existing config/app.php references do not break.
 */
class AiServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bindings live in RepositoryServiceProvider.
    }

    public function boot(): void {}
}
