<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\MerchantController as AdminMerchantController;
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
        Route::post('/merchants/{merchant}/subscription-requests/{subscriptionRequest}/approve', [AdminMerchantController::class, 'approveSubscription'])
            ->name('merchants.subscription-requests.approve');
        Route::post('/merchants/{merchant}/subscription-requests/{subscriptionRequest}/reject', [AdminMerchantController::class, 'rejectSubscription'])
            ->name('merchants.subscription-requests.reject');
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
    });
});

Route::redirect('/merchant', '/api/v1/merchant/dashboard')->withoutMiddleware('web');
