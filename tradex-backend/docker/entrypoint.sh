#!/usr/bin/env sh

set -eu

mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/app/private \
    storage/app/public \
    bootstrap/cache

php artisan storage:link --force
php artisan migrate --force --no-interaction
php artisan optimize

exec "$@"