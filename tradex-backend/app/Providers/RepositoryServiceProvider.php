<?php

namespace App\Providers;

use App\Contracts\Repositories\ReviewRepositoryInterface;
use App\Contracts\Repositories\UserNotificationRepositoryInterface;
use App\Contracts\Services\ReviewServiceInterface;
use App\Repositories\Eloquent\ReviewRepository;
use App\Repositories\Eloquent\UserNotificationRepository;
use App\Services\ReviewService;
use App\Contracts\Services\AI\AiProviderInterface;
use App\Contracts\Services\AI\AiUsageServiceInterface;
use App\Services\AI\GeminiProviderService;
use App\Services\AI\OpenRouterProviderService;
use App\Services\AI\AiUsageService;
use App\Contracts\Repositories\CartRepositoryInterface;
use App\Contracts\Repositories\CategoryRepositoryInterface;
use App\Contracts\Repositories\FavoriteRepositoryInterface;
use App\Contracts\Repositories\OrderRepositoryInterface;
use App\Contracts\Repositories\PlanRepositoryInterface;
use App\Contracts\Repositories\ProductRepositoryInterface;
use App\Contracts\Repositories\StoreRepositoryInterface;
use App\Contracts\Repositories\SubscriptionRepositoryInterface;
use App\Contracts\Repositories\SubscriptionRequestRepositoryInterface;
use App\Contracts\Services\AdminDashboardServiceInterface;
use App\Contracts\Services\AdminStoreManagementServiceInterface;
use App\Contracts\Services\AuthServiceInterface;
use App\Contracts\Services\CartServiceInterface;
use App\Contracts\Services\ClientDashboardServiceInterface;
use App\Contracts\Services\CategoryServiceInterface;
use App\Contracts\Services\FavoriteServiceInterface;
use App\Contracts\Services\GoogleTokenVerifierInterface;
use App\Contracts\Services\MerchantDashboardServiceInterface;
use App\Contracts\Services\OrderServiceInterface;
use App\Contracts\Services\PlanServiceInterface;
use App\Contracts\Services\ProductServiceInterface;
use App\Contracts\Services\ProfileServiceInterface;
use App\Contracts\Services\StoreServiceInterface;
use App\Contracts\Services\SubscriptionRequestServiceInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Contracts\Services\UserManagementServiceInterface;
use App\Contracts\Services\UserNotificationServiceInterface;
use App\Repositories\Eloquent\CartRepository;
use App\Repositories\Eloquent\CategoryRepository;
use App\Repositories\Eloquent\FavoriteRepository;
use App\Repositories\Eloquent\OrderRepository;
use App\Repositories\Eloquent\PlanRepository;
use App\Repositories\Eloquent\ProductRepository;
use App\Repositories\Eloquent\StoreRepository;
use App\Repositories\Eloquent\SubscriptionRepository;
use App\Repositories\Eloquent\SubscriptionRequestRepository;
use App\Services\AdminDashboardService;
use App\Services\AdminStoreManagementService;
use App\Services\AuthService;
use App\Services\CartService;
use App\Services\ClientDashboardService;
use App\Services\CategoryService;
use App\Services\FavoriteService;
use App\Services\GoogleTokenVerifier;
use App\Services\MerchantDashboardService;
use App\Services\OrderService;
use App\Services\PlanService;
use App\Services\ProductService;
use App\Services\ProfileService;
use App\Services\StoreService;
use App\Services\SubscriptionRequestService;
use App\Services\SubscriptionService;
use App\Services\UserManagementService;
use App\Services\UserNotificationService;
use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    /**
     * Bind interfaces to their concrete implementations.
     */
    public function register(): void
    {
        // ── Services ──────────────────────────────────────────────────────────
        $this->app->bind(AuthServiceInterface::class,                AuthService::class);
        $this->app->bind(ProductServiceInterface::class,             ProductService::class);
        $this->app->bind(CategoryServiceInterface::class,            CategoryService::class);
        $this->app->bind(StoreServiceInterface::class,               StoreService::class);
        $this->app->bind(CartServiceInterface::class,                CartService::class);
        $this->app->bind(ClientDashboardServiceInterface::class,    ClientDashboardService::class);
        $this->app->bind(OrderServiceInterface::class,               OrderService::class);
        $this->app->bind(FavoriteServiceInterface::class,            FavoriteService::class);
        $this->app->bind(GoogleTokenVerifierInterface::class,         GoogleTokenVerifier::class);
        $this->app->bind(ProfileServiceInterface::class,             ProfileService::class);
        $this->app->bind(PlanServiceInterface::class,                PlanService::class);
        $this->app->bind(SubscriptionServiceInterface::class,        SubscriptionService::class);
        $this->app->bind(SubscriptionRequestServiceInterface::class, SubscriptionRequestService::class);
        $this->app->bind(ReviewServiceInterface::class,             ReviewService::class);
        $this->app->bind(UserNotificationServiceInterface::class,  UserNotificationService::class);

        // ── Dashboard & management services ───────────────────────────────────
        $this->app->bind(MerchantDashboardServiceInterface::class,    MerchantDashboardService::class);
        $this->app->bind(AdminDashboardServiceInterface::class,        AdminDashboardService::class);
        $this->app->bind(UserManagementServiceInterface::class,        UserManagementService::class);
        $this->app->bind(AdminStoreManagementServiceInterface::class,  AdminStoreManagementService::class);

        // ── Repositories ──────────────────────────────────────────────────────
        $this->app->bind(ProductRepositoryInterface::class,              ProductRepository::class);
        $this->app->bind(CartRepositoryInterface::class,                 CartRepository::class);
        $this->app->bind(OrderRepositoryInterface::class,                OrderRepository::class);
        $this->app->bind(FavoriteRepositoryInterface::class,             FavoriteRepository::class);
        $this->app->bind(StoreRepositoryInterface::class,                StoreRepository::class);
        $this->app->bind(CategoryRepositoryInterface::class,             CategoryRepository::class);
        $this->app->bind(PlanRepositoryInterface::class,                 PlanRepository::class);
        $this->app->bind(SubscriptionRepositoryInterface::class,         SubscriptionRepository::class);
        $this->app->bind(SubscriptionRequestRepositoryInterface::class,  SubscriptionRequestRepository::class);
        $this->app->bind(ReviewRepositoryInterface::class,               ReviewRepository::class);
        $this->app->bind(UserNotificationRepositoryInterface::class,      UserNotificationRepository::class);

        // ── AI SaaS ───────────────────────────────────────────────────────────
        $this->app->bind(AiProviderInterface::class, function ($app) {
            $provider = match (config('services.ai_provider', 'gemini')) {
                'openrouter' => OpenRouterProviderService::class,
                default      => GeminiProviderService::class,
            };

            return $app->make($provider);
        });
        $this->app->bind(AiUsageServiceInterface::class, AiUsageService::class);
    }

    public function boot(): void {}
}
