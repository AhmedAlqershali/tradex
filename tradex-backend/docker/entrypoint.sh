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

# If the mounted persistent storage is empty, copy any baked-in public files
# included in the image into the mount so committed fixtures (avatars, logos,
# product images) remain available after the volume is attached by Render.
if [ -d "/var/www/html/storage_seed" ] && [ -d "storage/app/public" ]; then
    if [ -z "$(ls -A storage/app/public)" ]; then
        echo "Seeding mounted storage/app/public from baked-in storage_seed"
        cp -a /var/www/html/storage_seed/. storage/app/public/ || true
        chmod -R 755 storage/app/public || true
    fi
fi

php artisan storage:link --force
php artisan migrate --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\PlanSeeder --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\CategorySeeder --force --no-interaction
php artisan tradex:provision-admin
php artisan optimize

exec "$@"