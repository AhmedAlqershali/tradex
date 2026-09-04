FROM node:22-bookworm-slim AS assets

WORKDIR /var/www/html

COPY package.json package-lock.json ./
RUN npm ci --registry=https://registry.npmjs.org/

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

COPY --from=assets /var/www/html/public/build ./public/build
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint
COPY docker/start.sh /usr/local/bin/docker-start

RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/app/private \
    storage/app/public \
    bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chmod +x /usr/local/bin/docker-entrypoint /usr/local/bin/docker-start

EXPOSE 8000

ENTRYPOINT ["docker-entrypoint"]
CMD ["docker-start"]