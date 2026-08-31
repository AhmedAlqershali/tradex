FROM node:22-bookworm-slim AS assets

WORKDIR /var/www/html

COPY package.json package-lock.json ./
RUN sed -i 's#http://package-firewall\.replit\.local/npm/#https://registry.npmjs.org/#g' package-lock.json \
    && npm ci --registry=https://registry.npmjs.org/

COPY resources ./resources
COPY vite.config.js ./
RUN npm run build

FROM php:8.4-cli

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        libsqlite3-dev \
        libzip-dev \
        libicu-dev \
        libpq-dev \
    && docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite zip intl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . .
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader

# Preserve a baked-in copy of the repository's public disk contents so the
# startup script can seed an attached persistent Render disk when it's empty.
RUN if [ -d storage/app/public ]; then mkdir -p /var/www/html/storage_seed && cp -a storage/app/public/. /var/www/html/storage_seed/ || true; fi

COPY --from=assets /var/www/html/public/build ./public/build
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint

RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/app/private \
    storage/app/public \
    bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chmod +x /usr/local/bin/docker-entrypoint

EXPOSE 8000

ENTRYPOINT ["docker-entrypoint"]
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT:-8000} -t public docker/router.php"]