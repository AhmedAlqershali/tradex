<?php

use App\Providers\AppServiceProvider;
use App\Providers\RepositoryServiceProvider;
use CloudinaryLabs\CloudinaryLaravel\CloudinaryServiceProvider;

return [
    AppServiceProvider::class,
    RepositoryServiceProvider::class,
    CloudinaryServiceProvider::class,
];
