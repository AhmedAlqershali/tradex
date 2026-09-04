#!/usr/bin/env sh

set -eu

APP_ROOT=/var/www/html
PUBLIC_STORAGE_PATH="$APP_ROOT/storage/app/public"
PUBLIC_STORAGE_LINK="$APP_ROOT/public/storage"
STORAGE_SEED_PATH="$APP_ROOT/storage_seed"

mkdir -p \
    "$APP_ROOT/storage/framework/cache" \
    "$APP_ROOT/storage/framework/sessions" \
    "$APP_ROOT/storage/framework/views" \
    "$APP_ROOT/storage/logs" \
    "$APP_ROOT/storage/app/private" \
    "$PUBLIC_STORAGE_PATH" \
    "$APP_ROOT/bootstrap/cache"

LINK_TARGET="$(readlink -f "$PUBLIC_STORAGE_LINK" 2>/dev/null || true)"
if [ -e "$PUBLIC_STORAGE_LINK" ] && [ ! -L "$PUBLIC_STORAGE_LINK" ]; then
    echo "[storage] ERROR: $PUBLIC_STORAGE_LINK exists but is not a symlink" >&2
    exit 1
fi
if [ "$LINK_TARGET" != "$PUBLIC_STORAGE_PATH" ]; then
    if [ -L "$PUBLIC_STORAGE_LINK" ]; then
        rm -f "$PUBLIC_STORAGE_LINK"
    fi
    ln -s "$PUBLIC_STORAGE_PATH" "$PUBLIC_STORAGE_LINK"
fi

# Fail startup rather than serving media URLs through a broken or stale link.
if [ ! -L "$PUBLIC_STORAGE_LINK" ] || [ "$(readlink -f "$PUBLIC_STORAGE_LINK" 2>/dev/null || true)" != "$PUBLIC_STORAGE_PATH" ]; then
    echo "[storage] ERROR: public storage link is invalid" >&2
    exit 1
fi

# Copy only missing committed public files. Existing uploaded files on the
# persistent disk are never overwritten or deleted.
if [ -d "$STORAGE_SEED_PATH" ]; then
    cp -an "$STORAGE_SEED_PATH/." "$PUBLIC_STORAGE_PATH/" || true
fi

chmod 775 "$PUBLIC_STORAGE_PATH" "$PUBLIC_STORAGE_LINK"
find "$PUBLIC_STORAGE_PATH" -type d -exec chmod 775 {} + 2>/dev/null || true
find "$PUBLIC_STORAGE_PATH" -type f -exec chmod 664 {} + 2>/dev/null || true

echo "[storage] path=$PUBLIC_STORAGE_PATH"
echo "[storage] public_link=$PUBLIC_STORAGE_LINK"
echo "[storage] link_target=$(readlink -f "$PUBLIC_STORAGE_LINK" 2>/dev/null || true)"
if [ -d "$PUBLIC_STORAGE_PATH" ]; then
    echo "[storage] target_exists=true file_count=$(find "$PUBLIC_STORAGE_PATH" -type f | wc -l)"
    find "$PUBLIC_STORAGE_PATH" -maxdepth 2 -type f -print | head -50
else
    echo "[storage] target_exists=false file_count=0"
fi

if [ ! -L "$PUBLIC_STORAGE_LINK" ] || [ "$(readlink -f "$PUBLIC_STORAGE_LINK" 2>/dev/null || true)" != "$PUBLIC_STORAGE_PATH" ]; then
    echo "[storage] ERROR: public storage link is invalid after initialization" >&2
    exit 1
fi
php artisan migrate --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\PlanSeeder --force --no-interaction
php artisan db:seed --class=Database\\Seeders\\CategorySeeder --force --no-interaction

if [ "${VERIFY_EXISTING_USERS:-}" = "true" ]; then
    php artisan users:verify-existing
fi

php artisan tradex:provision-admin
php artisan optimize

exec "$@"