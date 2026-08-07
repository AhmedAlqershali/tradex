<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Dashboard entry points use the existing authenticated API surfaces.
Route::redirect('/admin', '/api/v1/admin/dashboard')->withoutMiddleware('web');
Route::redirect('/merchant', '/api/v1/merchant/dashboard')->withoutMiddleware('web');
