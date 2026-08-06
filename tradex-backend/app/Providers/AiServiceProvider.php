<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiServiceInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Services\AI\Providers\GeminiAiProvider;
use App\Services\AI\AiService;
use App\Services\AI\AiUsageService;

class AiServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(AiUsageServiceInterface::class, AiUsageService::class);

        $this->app->singleton(AiProviderInterface::class, function ($app) {
            return new GeminiAiProvider();
        });

        $this->app->singleton(AiServiceInterface::class, AiService::class);
    }

    public function boot(): void
    {
        //
    }
}
