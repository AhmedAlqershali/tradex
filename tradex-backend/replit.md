# TradexAPI

A Laravel 12 REST API backend for the Tradex mobile marketplace — powering Flutter client and merchant apps.

---

## Overview

TradexAPI is a production-ready JSON API built with:

- **Laravel 12** — PHP 8.2+
- **Laravel Sanctum** — token-based authentication (Bearer tokens, 90-day expiry)
- **SQLite** — database (file: `database/database.sqlite`)
- **Laravel Storage** (public disk) — file/image uploads
- **Google Gemini API** — AI content generation (optional; set `GEMINI_API_KEY`)

---

## Documentation

All developer documentation lives in `docs/`:

| File | Contents |
|---|---|
| `docs/setup.md` | Installation, environment variables, running locally |
| `docs/architecture.md` | System design, request lifecycle, RBAC, AI flow |
| `docs/backend-guide.md` | Module guide, conventions, how to add a feature |
| `docs/database.md` | All tables, columns, relationships, design decisions |
| `docs/api-reference.md` | Every endpoint — method, URL, body, responses |

---

## Architecture

```
app/
  Http/
    Controllers/Api/V1/      # Thin controllers — Auth, Client/, Merchant/, Admin/, AI
    Middleware/              # EnsureRole, EnsureUserIsActive
    Requests/                # Form validation (per feature)
    Resources/               # JSON response transformers
  Contracts/
    Repositories/            # Repository interfaces
    Services/                # Service interfaces (incl. AI/)
  Services/                  # All business logic (incl. AI/)
  Repositories/Eloquent/     # DB access layer
  Models/                    # Eloquent models
  Providers/
    AppServiceProvider.php        # Rate limiters, email verification URL
    RepositoryServiceProvider.php # IoC bindings (interfaces → implementations)
  Exceptions/                # Domain exception classes
  Policies/                  # Gate authorization rules
```

All endpoints return a standard envelope:
```json
{ "success": true, "message": "...", "data": { ... } }
```

---

## User Roles

| Role | Access |
|---|---|
| `client` | Browse marketplace, cart, orders, favorites, reviews, profile |
| `merchant` | Store & product management, incoming orders, AI tools, subscription |
| `admin` | Users, stores, categories, plans, subscription requests, analytics |

---

## Running on Replit

The `Start application` workflow runs:
```bash
php artisan serve --host=0.0.0.0 --port=5000
```

Health check: `GET /api/v1/health`

---

## Running Locally (non-Replit)

```bash
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate
php artisan storage:link
php artisan serve --port=5000
```

---

## Testing

```bash
# Full suite (514 tests, 1399 assertions)
php artisan test

# Single file
php artisan test tests/Feature/Security/RateLimitTest.php
```

Tests use an in-memory SQLite database (`phpunit.xml`) and `RefreshDatabase`. No extra setup needed.

---

## Key Conventions

- All controllers extend `BaseApiController` — use `success()`, `created()`, `error()`, `notFound()` helpers. Never return raw `response()->json()`.
- All services are injected via their **interface**, never the concrete class.
- All database access goes through a **repository**. Services never call Eloquent directly.
- Snapshot mutable data at transaction time (e.g. `order_items` copies `product_name` + `unit_price` at checkout).
- Image URLs are always absolute (generated via `Storage::disk('public')->url($path)` in Resources).
- Pagination metadata is always returned under a `pagination` key.
- Error envelope always includes `"success": false` and `"data": null`.

---

## User Preferences

- Keep existing project architecture (Service → Repository → Eloquent pattern).
- Do not rewrite or restructure existing features.
- All API responses must follow the `{ success, message, data }` envelope.
- Images must always return complete URLs (not relative paths).
- Flutter BLoC integration — keep JSON clean, flat, and consistent.
