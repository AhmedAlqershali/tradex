# TradexAPI — Developer Setup Guide

## Requirements

| Dependency | Version |
|---|---|
| PHP | 8.2+ |
| Composer | 2.x |
| SQLite | 3.x (bundled with PHP) |

No Docker, no MySQL, no Redis required for local development. The project uses SQLite and the file cache driver out of the box.

---

## Installation

### 1. Clone the project

```bash
git clone <repo-url>
cd tradex-backend
```

### 2. Install PHP dependencies

```bash
composer install
```

### 3. Copy the environment file

```bash
cp .env.example .env
```

### 4. Generate the application key

```bash
php artisan key:generate
```

### 5. Create the SQLite database file

```bash
touch database/database.sqlite
```

### 6. Run migrations

```bash
php artisan migrate
```

### 7. (Optional) Seed the database with sample data

```bash
php artisan db:seed
```

This creates sample categories, stores, products, and users for testing.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `TradxAPI` | Application name returned in health check |
| `APP_ENV` | `local` | Environment (`local`, `production`) |
| `APP_KEY` | _(generated)_ | 32-byte encryption key — never share this |
| `APP_DEBUG` | `true` | Show detailed errors in development |
| `APP_URL` | `http://localhost:5000` | Base URL used for signed URLs and storage links |
| `DB_CONNECTION` | `sqlite` | Database driver |
| `DB_DATABASE` | `database/database.sqlite` | Absolute path to the SQLite file |
| `SANCTUM_EXPIRATION_MINUTES` | `129600` | Token lifetime (90 days) |
| `CORS_ALLOWED_ORIGINS` | `*` | Comma-separated allowed origins for CORS |
| `FILESYSTEM_DISK` | `public` | Storage disk for uploaded files |
| `QUEUE_CONNECTION` | `sync` | Queue driver (`sync` = synchronous, no worker needed) |
| `MAIL_MAILER` | `log` | Mail driver (`log` writes emails to the log file) |

### AI Provider (optional — only needed for AI endpoints)

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key — required for AI content generation |

If `GEMINI_API_KEY` is not set, AI generation endpoints return a 503 error. All other endpoints work normally.

---

## Storage

The `public` disk maps to `storage/app/public`. Images (product images, store logos, avatars, payment proofs) are stored here.

Create the symlink so the web server can serve files:

```bash
php artisan storage:link
```

---

## Running the Development Server

```bash
php artisan serve --host=0.0.0.0 --port=5000
```

The API is then available at `http://localhost:5000/api/v1/`.

### Health check

```bash
curl http://localhost:5000/api/v1/health
```

Expected response:

```json
{
  "success": true,
  "message": "OK",
  "data": { "status": "ok", "version": "v1", "app": "TradxAPI" }
}
```

---

## Running the Test Suite

```bash
php artisan test
```

Or for a specific file:

```bash
php artisan test tests/Feature/Security/RateLimitTest.php
```

Expected output: **514 tests, 1399 assertions, 0 failures**.

The test suite uses an in-memory SQLite database (configured in `phpunit.xml`) and refreshes it between tests. No extra setup is required.

---

## Database Commands Reference

```bash
# Run all pending migrations
php artisan migrate

# Roll back all migrations and re-run (destroys all data)
php artisan migrate:fresh

# Roll back and re-run with seeders
php artisan migrate:fresh --seed

# Check migration status
php artisan migrate:status

# Create a new migration
php artisan make:migration create_example_table
```

---

## Code Quality

```bash
# Format code with Laravel Pint (PSR-12)
./vendor/bin/pint

# Run static analysis (if PHPStan is added)
./vendor/bin/phpstan analyse
```

---

## Common Issues

### `sqlite3` extension not enabled

Ensure `extension=pdo_sqlite` is uncommented in your `php.ini`.

### Uploaded images return 404

Run `php artisan storage:link` to create the `public/storage` symlink.

### 419 CSRF error on API routes

API routes are stateless and use Bearer tokens, not CSRF. Ensure your HTTP client sends `Accept: application/json` and `Authorization: Bearer <token>`.

### Rate limit 429 in tests

The test suite clears rate limiters using `RateLimiter::clear(...)` in `setUp()`. If you hit 429 in manual testing, wait one minute or restart the dev server.
