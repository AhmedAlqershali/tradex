<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\MerchantController as AdminMerchantController;
use App\Http\Controllers\Admin\OrderController as AdminOrderController;
use App\Http\Controllers\Admin\ProductController as AdminProductController;
use App\Http\Controllers\Admin\CategoryController as AdminCategoryController;
use App\Http\Controllers\Admin\StoreController as AdminStoreController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:auth')
        ->name('login.store');

    Route::middleware('admin.web')->group(function () {
        Route::get('/', fn () => redirect()->route('admin.dashboard'))->name('home');
        Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
        Route::get('/merchants', [AdminMerchantController::class, 'index'])->name('merchants.index');
        Route::get('/merchants/{merchant}', [AdminMerchantController::class, 'show'])->name('merchants.show');
        Route::get('/subscriptions', fn () => redirect()->to(
            route('admin.merchants.index', ['section' => 'subscriptions']).'#subscriptions'
        ))
            ->name('subscriptions.index');
        Route::post('/merchants/{merchant}/subscription-requests/{subscriptionRequest}/approve', [AdminMerchantController::class, 'approveSubscription'])
            ->name('merchants.subscription-requests.approve');
        Route::post('/merchants/{merchant}/subscription-requests/{subscriptionRequest}/reject', [AdminMerchantController::class, 'rejectSubscription'])
            ->name('merchants.subscription-requests.reject');
        Route::get('/stores', [AdminStoreController::class, 'index'])->name('stores.index');
        Route::get('/stores/{store}', [AdminStoreController::class, 'show'])->name('stores.show');
        Route::put('/stores/{store}/status', [AdminStoreController::class, 'updateStatus'])->name('stores.status');
        Route::get('/users', [AdminUserController::class, 'index'])->name('users.index');
        Route::delete('/users/{user}', [AdminUserController::class, 'destroy'])->name('users.destroy');
        Route::get('/orders', [AdminOrderController::class, 'index'])->name('orders.index');
        Route::get('/orders/{order}', [AdminOrderController::class, 'show'])->name('orders.show');
        Route::put('/orders/{order}/status', [AdminOrderController::class, 'updateStatus'])->name('orders.status');
        Route::get('/products', [AdminProductController::class, 'index'])->name('products.index');
        Route::get('/products/{product}', [AdminProductController::class, 'show'])->name('products.show');
        Route::get('/categories', [AdminCategoryController::class, 'index'])->name('categories.index');
        Route::get('/categories/create', [AdminCategoryController::class, 'create'])->name('categories.create');
        Route::post('/categories', [AdminCategoryController::class, 'store'])->name('categories.store');
        Route::get('/categories/{category}/edit', [AdminCategoryController::class, 'edit'])->name('categories.edit');
        Route::put('/categories/{category}', [AdminCategoryController::class, 'update'])->name('categories.update');
        Route::delete('/categories/{category}', [AdminCategoryController::class, 'destroy'])->name('categories.destroy');
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
    });
});

Route::redirect('/merchant', '/api/v1/merchant/dashboard')->withoutMiddleware('web');
