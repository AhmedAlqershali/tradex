<?php

use App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\Client;
use App\Http\Controllers\Api\V1\Merchant;
use App\Http\Controllers\Api\V1\ProfileController;
use Illuminate\Support\Facades\Route;

// Dashboard controllers
use App\Http\Controllers\Api\V1\Merchant\DashboardController as MerchantDashboardController;
use App\Http\Controllers\Api\V1\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\V1\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\V1\Admin\StoreController as AdminStoreController;

// Explicit imports to avoid ambiguity between Client\OrderController and Merchant\OrderController
use App\Http\Controllers\Api\V1\Client\CartController;
use App\Http\Controllers\Api\V1\Client\DashboardController as ClientDashboardController;
use App\Http\Controllers\Api\V1\Client\FavoriteController;
use App\Http\Controllers\Api\V1\Client\OrderController as ClientOrderController;
use App\Http\Controllers\Api\V1\Client\ReviewController as ClientReviewController;
use App\Http\Controllers\Api\V1\Merchant\OrderController as MerchantOrderController;
use App\Http\Controllers\Api\V1\Merchant\StoreController as MerchantStoreController;
use App\Http\Controllers\Api\V1\Merchant\SubscriptionController as MerchantSubscriptionController;
use App\Http\Controllers\Api\V1\Admin\ReviewController as AdminReviewController;
use App\Http\Controllers\Api\V1\Admin\SubscriptionRequestController as AdminSubscriptionRequestController;
use App\Http\Controllers\Api\V1\Admin\SubscriptionProofController;
use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\DeviceTokenController;

Route::prefix('v1')->name('api.v1.')->group(function () {

    // ── Health check ─────────────────────────────────────────────────────────
    Route::get('/health', function () {
        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data'    => [
                'status'  => 'ok',
                'version' => 'v1',
                'app'     => config('app.name'),
            ],
        ]);
    })->name('health');

    // ── Auth (public) ─────────────────────────────────────────────────────────
    Route::prefix('auth')->name('auth.')->group(function () {
        // Rate limited (5/min/IP) — brute-force and registration-spam protection.
        Route::middleware('throttle:auth')->group(function () {
            Route::prefix('register')->name('register.')->group(function () {
                Route::post('/client',   [AuthController::class, 'registerClient'])->name('client');
                Route::post('/merchant', [AuthController::class, 'registerMerchant'])->name('merchant');
            });
            Route::post('/login', [AuthController::class, 'login'])->name('login');
            Route::post('/google', [AuthController::class, 'google'])->name('google');

            // ── Password reset ────────────────────────────────────────────────
            Route::post('/password/forgot', [AuthController::class, 'forgotPassword'])->name('password.forgot');
            Route::post('/password/reset',  [AuthController::class, 'resetPassword'])->name('password.reset');
        });

        // ── Email verification ────────────────────────────────────────────────
        Route::get(
            '/email/verify/{id}/{hash}',
            [AuthController::class, 'verifyEmail']
        )->middleware('signed')->name('verification.verify');

        Route::middleware(['auth:sanctum', 'user.active'])->group(function () {
            Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
            Route::get('/me',      [AuthController::class, 'me'])->name('me');

            Route::post('/email/resend', [AuthController::class, 'resendVerification'])->name('verification.resend');
        });
    });

    // ── Client marketplace (public) ───────────────────────────────────────────
    Route::prefix('')->name('client.')->group(function () {
        // Categories
        Route::get('categories', [Client\CategoryController::class, 'index'])->name('categories.index');

        // Stores
        Route::get('stores',      [Client\StoreController::class, 'index'])->name('stores.index');
        Route::get('stores/{id}', [Client\StoreController::class, 'show'])->name('stores.show');

        // Products browsing (public — no auth required)
        // Supports: search, category_id, store_id, price_min, price_max,
        //           sort (newest|oldest|price_asc|price_desc), per_page
        Route::get('products',      [Client\ProductController::class, 'index'])->name('products.index');
        Route::get('products/{id}', [Client\ProductController::class, 'show'])->name('products.show');

        // ── Reviews (public read) ─────────────────────────────────────────────
        // Anyone can browse reviews for an active product.
        Route::get('products/{productId}/reviews', [ClientReviewController::class, 'index'])
            ->name('products.reviews.index');
    });

    // ── Authenticated routes ──────────────────────────────────────────────────
    // 'user.active' runs AFTER auth:sanctum has resolved the user, ensuring
    // banned or inactive users are blocked on every authenticated request.
    Route::middleware(['auth:sanctum', 'user.active'])->group(function () {

        // ── Profile (all authenticated roles) ────────────────────────────────
        Route::prefix('profile')->name('profile.')->group(function () {
            Route::get('/',         [ProfileController::class, 'show'])->name('show');
            Route::put('/',         [ProfileController::class, 'update'])->name('update');
            Route::put('/password', [ProfileController::class, 'changePassword'])->name('password');
            Route::post('/avatar',  [ProfileController::class, 'updateAvatar'])->name('avatar');
        });

        // ── In-app notifications (all authenticated roles) ──────────────────
        Route::get('notifications', [NotificationController::class, 'index'])
            ->name('notifications.index');
        Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead'])
            ->name('notifications.read');
        Route::post('notifications/read-all', [NotificationController::class, 'markAllRead'])
            ->name('notifications.read-all');
        Route::post('device-tokens', [DeviceTokenController::class, 'store'])
            ->name('device-tokens.store');
        Route::delete('device-tokens', [DeviceTokenController::class, 'destroy'])
            ->name('device-tokens.destroy');

        // ── Client (cart + orders + favorites + reviews) ──────────────────────
        Route::middleware('role:client')
            ->name('client.')
            ->group(function () {
                Route::post('stores/{id}/follow', [Client\StoreController::class, 'follow'])
                    ->name('stores.follow');
                Route::delete('stores/{id}/follow', [Client\StoreController::class, 'unfollow'])
                    ->name('stores.unfollow');
                // Dashboard counters
                Route::get('client/dashboard', [ClientDashboardController::class, 'dashboard'])
                    ->name('dashboard');

                // Cart
                Route::get('cart',                [CartController::class, 'index'])->name('cart.index');
                Route::post('cart/items',         [CartController::class, 'addItem'])->name('cart.items.add');
                Route::put('cart/items/{id}',     [CartController::class, 'updateItem'])->name('cart.items.update');
                Route::delete('cart/items/{id}',  [CartController::class, 'removeItem'])->name('cart.items.remove');
                Route::delete('cart',              [CartController::class, 'clear'])->name('cart.clear');

                // Orders
                Route::post('orders',             [ClientOrderController::class, 'store'])->name('orders.store');
                Route::get('orders',              [ClientOrderController::class, 'index'])->name('orders.index');
                Route::get('orders/{id}',         [ClientOrderController::class, 'show'])->name('orders.show');
                Route::delete('orders/{id}',      [ClientOrderController::class, 'cancel'])->name('orders.cancel');

                // Favorites
                Route::get('favorites',               [FavoriteController::class, 'index'])->name('favorites.index');
                Route::post('favorites/{product}',    [FavoriteController::class, 'add'])->name('favorites.add');
                Route::delete('favorites/{product}',  [FavoriteController::class, 'remove'])->name('favorites.remove');

                // ── Reviews (authenticated write) ─────────────────────────────
                // POST /api/v1/products/{productId}/reviews — submit a review
                Route::post('products/{productId}/reviews', [ClientReviewController::class, 'store'])
                    ->name('products.reviews.store');

                // DELETE /api/v1/reviews/{id} — delete own review
                Route::delete('reviews/{id}', [ClientReviewController::class, 'destroy'])
                    ->name('reviews.destroy');
            });

        // ── AI SaaS ──────────────────────────────────────────────────────────
        //
        // All routes in this group require auth:sanctum (inherited from parent).
        // Merchant tools additionally require role:merchant.
        // Admin analytics requires role:admin.
        // Throttle: 20 AI requests/minute per user (OPENAI calls are expensive).
        Route::prefix('ai')
            ->name('ai.')
            ->middleware('throttle:ai')
            ->group(function () {
                // Usage summary — any authenticated role
                Route::get('usage', [AiController::class, 'usage'])->name('usage');

                // Merchant tools
                Route::middleware(['role:merchant', 'merchant.subscription'])->group(function () {
                    Route::post('product-description', [AiController::class, 'productDescription'])->name('product-description');
                    Route::post('marketing-content',   [AiController::class, 'marketingContent'])->name('marketing-content');
                    Route::post('customer-reply',      [AiController::class, 'customerReply'])->name('customer-reply');
                });

                // Admin analytics
                Route::middleware('role:admin')->group(function () {
                    Route::get('analytics', [AiController::class, 'analytics'])->name('analytics');
                });
            });

        // ── Merchant ─────────────────────────────────────────────────────────
        Route::middleware(['role:merchant'])
            ->prefix('merchant')
            ->name('merchant.')
            ->group(function () {
                Route::middleware('merchant.subscription')->group(function () {
                    // Product management
                    Route::apiResource('products', Merchant\ProductController::class);

                    // Order management
                    Route::get('orders',                    [MerchantOrderController::class, 'index'])->name('orders.index');
                    Route::get('orders/{id}',               [MerchantOrderController::class, 'show'])->name('orders.show');
                    Route::put('orders/{id}/status',        [MerchantOrderController::class, 'updateStatus'])->name('orders.status');

                    // ── Store management ──────────────────────────────────────
                    Route::get('stores',                    [MerchantStoreController::class, 'index'])->name('stores.index');
                    Route::get('stores/{id}',               [MerchantStoreController::class, 'show'])->name('stores.show');
                    Route::put('stores/{id}',               [MerchantStoreController::class, 'update'])->name('stores.update');
                    Route::post('stores/{id}/logo',         [MerchantStoreController::class, 'updateLogo'])->name('stores.logo');

                    // ── Dashboard & Analytics ─────────────────────────────────
                    Route::get('dashboard', [MerchantDashboardController::class, 'dashboard'])->name('dashboard');
                    Route::get('analytics', [MerchantDashboardController::class, 'analytics'])->name('analytics');
                });

                // ── Subscription ──────────────────────────────────────────────
                // GET  /merchant/subscription                    — current active subscription
                // GET  /merchant/plans                            — active plans
                // GET  /merchant/subscription-requests           — own requests
                // GET  /merchant/subscription-requests/{id}      — request detail
                // POST /merchant/subscription-requests           — submit new request
                Route::get('plans',                            [MerchantSubscriptionController::class, 'indexPlans'])->name('plans.index');
                Route::get('subscription',                        [MerchantSubscriptionController::class, 'show'])->name('subscription.show');
                Route::get('subscription-requests',               [MerchantSubscriptionController::class, 'indexRequests'])->name('subscription-requests.index');
                Route::get('subscription-requests/{id}',          [MerchantSubscriptionController::class, 'showRequest'])->name('subscription-requests.show');
                Route::post('subscription-requests',              [MerchantSubscriptionController::class, 'storeRequest'])->name('subscription-requests.store');
            });

        // ── Admin ─────────────────────────────────────────────────────────────
        Route::middleware('role:admin')
            ->prefix('admin')
            ->name('admin.')
            ->group(function () {
                // Product monitoring (read-only)
                Route::get('products',      [Admin\ProductController::class, 'index'])->name('products.index');
                Route::get('products/{id}', [Admin\ProductController::class, 'show'])->name('products.show');

                // ── Category management ───────────────────────────────────────
                Route::get('categories',           [Admin\CategoryController::class, 'index'])->name('categories.index');
                Route::post('categories',          [Admin\CategoryController::class, 'store'])->name('categories.store');
                Route::get('categories/{id}',      [Admin\CategoryController::class, 'show'])->name('categories.show');
                Route::put('categories/{id}',      [Admin\CategoryController::class, 'update'])->name('categories.update');
                Route::delete('categories/{id}',   [Admin\CategoryController::class, 'destroy'])->name('categories.destroy');

                // ── Plan management ───────────────────────────────────────────
                Route::get('plans',           [Admin\PlanController::class, 'index'])->name('plans.index');
                Route::post('plans',          [Admin\PlanController::class, 'store'])->name('plans.store');
                Route::get('plans/{id}',      [Admin\PlanController::class, 'show'])->name('plans.show');
                Route::put('plans/{id}',      [Admin\PlanController::class, 'update'])->name('plans.update');
                Route::delete('plans/{id}',   [Admin\PlanController::class, 'destroy'])->name('plans.destroy');

                // ── User management ───────────────────────────────────────────
                Route::get('users',                    [AdminUserController::class, 'index'])->name('users.index');
                Route::get('users/{id}',               [AdminUserController::class, 'show'])->name('users.show');
                Route::put('users/{id}/status',        [AdminUserController::class, 'updateStatus'])->name('users.status');
                Route::put('users/{id}/role',          [AdminUserController::class, 'updateRole'])->name('users.role');
                Route::delete('users/{id}',            [AdminUserController::class, 'destroy'])->name('users.destroy');

                // ── Store management ──────────────────────────────────────────
                Route::get('stores',                   [AdminStoreController::class, 'index'])->name('stores.index');
                Route::get('stores/{id}',              [AdminStoreController::class, 'show'])->name('stores.show');
                Route::put('stores/{id}/status',       [AdminStoreController::class, 'updateStatus'])->name('stores.status');

                // ── Dashboard & Analytics ─────────────────────────────────────
                Route::get('dashboard', [AdminDashboardController::class, 'dashboard'])->name('dashboard');
                Route::get('analytics', [AdminDashboardController::class, 'analytics'])->name('analytics');

                // ── Reviews moderation ────────────────────────────────────────
                Route::get('products/{productId}/reviews', [AdminReviewController::class, 'index'])->name('products.reviews.index');
                Route::delete('reviews/{id}',              [AdminReviewController::class, 'destroy'])->name('reviews.destroy');

                // ── Subscription requests ─────────────────────────────────────
                Route::get('subscription-requests',               [AdminSubscriptionRequestController::class, 'index'])->name('subscription-requests.index');
                Route::get('subscription-requests/{id}',          [AdminSubscriptionRequestController::class, 'show'])->name('subscription-requests.show');
                Route::put('subscription-requests/{id}/approve',  [AdminSubscriptionRequestController::class, 'approve'])->name('subscription-requests.approve');
                Route::put('subscription-requests/{id}/reject',   [AdminSubscriptionRequestController::class, 'reject'])->name('subscription-requests.reject');

                // ── Payment proof secure download (private disk — no public URL) ──
                // Streams the file server-side; never exposes a direct storage URL.
                Route::get('subscription-requests/{id}/proof', [SubscriptionProofController::class, 'download'])
                    ->name('subscription-requests.proof');
            });
    });
});
