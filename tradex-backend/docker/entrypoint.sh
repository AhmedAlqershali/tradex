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

if [ -L public/storage ] || [ -e public/storage ]; then
    rm -rf public/storage
fi
ln -sfn ../storage/app/public public/storage

php artisan storage:link --force
php artisan migrate --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\PlanSeeder --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\CategorySeeder --force --no-interaction
php artisan tradex:provision-admin
php artisan optimize

exec "$@"