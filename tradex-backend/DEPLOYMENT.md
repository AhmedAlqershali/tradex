# TradxAPI — Production Deployment Checklist

**Stack:** Laravel 12 · PHP 8.2+ · MySQL 8+ · Redis (optional) · Queue worker  
**Last updated:** 2026-07-25

---

## 1. Prerequisites

| Requirement | Minimum version | Notes |
|---|---|---|
| PHP | 8.2 | Extensions: `pdo_mysql`, `mbstring`, `openssl`, `tokenizer`, `xml`, `ctype`, `json`, `bcmath`, `gd` or `imagick` |
| MySQL | 8.0 | Or compatible (MariaDB 10.6+) |
| Composer | 2.x | |
| Redis | 7.x | Optional but recommended for cache and queues |
| Nginx / Apache | Latest stable | See §7 for Nginx config |

---

## 2. Environment Setup

### 2.1 Required `.env` variables

Copy `.env.example` and fill in every value. Critical production overrides:

```bash
# Application
APP_NAME="TradxAPI"
APP_ENV=production
APP_DEBUG=false                    # ← MUST be false in production
APP_KEY=                           # Generate: php artisan key:generate
APP_URL=https://api.yourdomain.com

# Database (MySQL in production)
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=tradx_production
DB_USERNAME=tradx_user
DB_PASSWORD=<strong-random-password>

# Cache (Redis recommended for production)
CACHE_STORE=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null

# Queue (database or redis — never sync in production)
QUEUE_CONNECTION=database           # or redis
DB_QUEUE_CONNECTION=mysql           # required when QUEUE_CONNECTION=database

# Logging
LOG_CHANNEL=daily
LOG_LEVEL=warning                   # never debug in production
LOG_DEPRECATIONS_CHANNEL=null

# Storage
FILESYSTEM_DISK=public              # change to s3 for cloud storage

# Mail
MAIL_MAILER=smtp                    # or ses, mailgun, etc.
MAIL_HOST=your-smtp-host
MAIL_PORT=587
MAIL_USERNAME=your-username
MAIL_PASSWORD=your-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="Tradx"

# Sanctum
SANCTUM_EXPIRATION_MINUTES=129600   # 90 days — adjust per security policy

# CORS — restrict to your actual origins
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# AI Provider (Google Gemini)
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.0-flash
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
```

### 2.2 Optional: Cloud Storage (S3)

To use Amazon S3 or S3-compatible storage for product images and avatars:

```bash
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
AWS_URL=https://your-cdn-url        # optional CDN prefix
```

Install the S3 driver: `composer require league/flysystem-aws-s3-v3`

---

## 3. Deployment Commands

Run these in order on every deployment:

```bash
# 1. Install production dependencies (no dev)
composer install --no-dev --optimize-autoloader

# 2. Generate application key (first deploy only — never regenerate on existing installs)
php artisan key:generate

# 3. Run database migrations
php artisan migrate --force

# 4. Create the storage symlink (first deploy only)
php artisan storage:link

# 5. Clear and rebuild caches
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# 6. Set correct file permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 755 storage bootstrap/cache
```

### Zero-downtime deploy (recommended)

```bash
# Put in maintenance mode first
php artisan down --render="errors/503" --retry=60

# ... deploy new code, run migrations, clear caches ...

# Bring back up
php artisan up
```

---

## 4. Queue Worker

The application uses database-backed queues for notifications and background jobs.

### Start the worker

```bash
php artisan queue:work --queue=default --sleep=3 --tries=3 --max-time=3600
```

### Supervisor configuration (recommended)

Create `/etc/supervisor/conf.d/tradx-worker.conf`:

```ini
[program:tradx-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/tradx/artisan queue:work --queue=default --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/tradx-worker.log
stopwaitsecs=3600
```

```bash
supervisorctl reread
supervisorctl update
supervisorctl start tradx-worker:*
```

### Failed jobs

Failed jobs are stored in the `failed_jobs` table. Monitor and retry:

```bash
# List failed jobs
php artisan queue:failed

# Retry a single failed job
php artisan queue:retry <job-id>

# Retry all failed jobs
php artisan queue:retry all

# Flush (delete) all failed jobs
php artisan queue:flush
```

---

## 5. Cron / Scheduler

Add to the server's crontab (`crontab -e`):

```cron
* * * * * cd /var/www/tradx && php artisan schedule:run >> /dev/null 2>&1
```

---

## 6. Storage & Media

- All product images and store logos are stored under `storage/app/public/`.
- Avatars are stored under `storage/app/public/avatars/`.
- The `php artisan storage:link` command creates `public/storage → storage/app/public`.
- **Maximum upload sizes:** Product images — 2 MB each, up to 10 per product; Store logo — 2 MB; Avatar — 2 MB.
- **Accepted formats:** JPEG, JPG, PNG, WebP.
- For S3, update `FILESYSTEM_DISK=s3` — no code changes required.

---

## 7. Web Server (Nginx)

Minimal Nginx config for Laravel:

```nginx
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    root /var/www/tradx/public;
    index index.php;

    ssl_certificate     /etc/ssl/certs/yourdomain.crt;
    ssl_certificate_key /etc/ssl/private/yourdomain.key;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Increase upload limit for product images
    client_max_body_size 25M;
}
```

---

## 8. Security Checklist

- [ ] `APP_DEBUG=false` confirmed
- [ ] `APP_ENV=production` confirmed
- [ ] `APP_KEY` is set (never share this)
- [ ] `CORS_ALLOWED_ORIGINS` set to specific origins (not `*`)
- [ ] `DB_PASSWORD` is a strong random string
- [ ] `GEMINI_API_KEY` is set and kept secret
- [ ] HTTPS only — no plain HTTP in production
- [ ] File permissions: `storage/` and `bootstrap/cache/` owned by `www-data`
- [ ] Firewall: only ports 80 and 443 open to public; MySQL port not exposed
- [ ] Regular database backups configured
- [ ] `LOG_LEVEL=warning` (not debug)
- [ ] `php artisan config:cache` run after any `.env` change

---

## 9. Rate Limiting Summary

| Endpoint group | Limit | Key |
|---|---|---|
| Auth (login/register/forgot-password) | 5 req/min | IP address |
| General API | 60 req/min | User ID (or IP for guests) |
| AI generation endpoints | 20 req/min | User ID |
| Device tokens | 30 req/min | User ID or IP |

---

## 10. Database Migrations Reference

All 26 migrations must be applied:

```bash
php artisan migrate:status
```

Key migrations for production:
- `0001_01_01_000000` — users, password_reset_tokens
- `0001_01_01_000002` — jobs, job_batches, failed_jobs
- `2026_07_24_000001` — performance indexes
- `2026_07_24_100001` → `100004` — AI tables (ai_usages, ai_settings, ai_requests + credits)

---

## 11. Health Check

The health endpoint is unauthenticated and suitable for load balancer probes:

```
GET /api/v1/health
→ 200 { "success": true, "data": { "status": "ok", "version": "v1" } }
```

---

## 12. Post-deployment Smoke Test

Run these after every production deployment:

```bash
# Health check
curl -fsS https://api.yourdomain.com/api/v1/health

# Verify migrations are up to date
php artisan migrate:status | grep -v "Ran"

# Verify queue worker is running
php artisan queue:monitor

# Tail logs for 60 seconds looking for errors
tail -f storage/logs/laravel-$(date +%Y-%m-%d).log | grep -E "ERROR|CRITICAL"
```

---

## 13. Flutter Integration Notes

Before connecting the Flutter app:

1. Set `APP_URL` to the production HTTPS domain — this is used in email verification links.
2. Update `CORS_ALLOWED_ORIGINS` to include any web origins (not needed for mobile apps using HTTPS directly).
3. The Flutter app must send `Accept: application/json` on every request to receive JSON error responses instead of HTML.
4. Token storage: use `flutter_secure_storage` for the Sanctum bearer token.
5. Intercept 401 responses globally in the Dio/HTTP client and redirect to the login screen.
