# TradexAPI — Architecture Overview

## System Context

TradexAPI is a **Laravel 12 REST API** backend for a mobile marketplace application. The primary consumer is a Flutter mobile app, though the API is platform-agnostic.

```
Flutter App
    │
    │  HTTPS  Bearer Token (Sanctum)
    ▼
TradexAPI (Laravel 12)
    │
    ├── SQLite Database
    └── Google Gemini API  (AI features only)
```

---

## Request Lifecycle

Every HTTP request follows this path through the application:

```
HTTP Request
    │
    ▼
bootstrap/app.php
  ├── CORS Middleware       (all API routes)
  ├── Throttle Middleware   (rate limiting)
  └── Route Matching
          │
          ▼
      Middleware Stack (per route group)
        ├── auth:sanctum     → resolves User from Bearer token
        ├── role:<name>      → EnsureRole checks user->role
        └── user.active      → EnsureUserIsActive checks user->status
          │
          ▼
      Form Request
        └── validates() → returns 422 on failure (automatic)
          │
          ▼
      Controller
        └── thin — delegates immediately to Service
          │
          ▼
      Service
        └── business logic, orchestration, transactions
          │
          ▼
      Repository
        └── database queries via Eloquent
          │
          ▼
      Model / Database
          │
          ▼
      API Resource
        └── shapes the JSON response
          │
          ▼
HTTP Response (standard envelope)
```

### Standard Response Envelope

Every API response — success or error — uses this envelope:

```json
{
  "success": true | false,
  "message": "Human-readable description",
  "data":    { ... } | [ ... ] | null,
  "errors":  { ... }   // only on 422 validation failures
}
```

---

## Application Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        HTTP Layer                               │
│   routes/api.php  →  Middleware  →  FormRequest validation      │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                     Controllers                                  │
│   app/Http/Controllers/Api/V1/                                  │
│   Thin. Receives validated data, calls one service method,      │
│   returns an API Resource wrapped in BaseApiController helpers.  │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Interface (Contract)
┌─────────────────────────▼───────────────────────────────────────┐
│                      Services                                    │
│   app/Services/                                                  │
│   All business logic lives here: validation, transactions,      │
│   cross-entity orchestration, exception throwing.               │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Interface (Contract)
┌─────────────────────────▼───────────────────────────────────────┐
│                     Repositories                                 │
│   app/Repositories/Eloquent/                                    │
│   All database access. Services never query Eloquent directly;  │
│   they always go through a repository.                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                       Models                                     │
│   app/Models/                                                    │
│   Eloquent models: relationships, casts, scopes, accessors.     │
│   No business logic in models.                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                    SQLite Database
```

---

## Dependency Injection & Interface Binding

All services and repositories are **bound via interfaces**. This means:

- Controllers depend on `OrderServiceInterface`, not `OrderService`.
- Tests can swap implementations without touching controller code.
- The concrete binding is declared in `app/Providers/RepositoryServiceProvider.php`.

```
Interface                         →  Concrete Implementation
────────────────────────────────────────────────────────────
OrderServiceInterface             →  OrderService
OrderRepositoryInterface          →  Eloquent\OrderRepository
AiProviderInterface               →  GeminiProviderService
AiUsageServiceInterface           →  AiUsageService
```

---

## AI SaaS Architecture

The AI layer sits alongside the main application and is consumed only by merchant and admin routes.

```
Flutter App (Merchant)
    │
    │  POST /api/v1/ai/product-description
    ▼
AiController
    │
    ▼
AiService dispatcher
    │  (selects the correct concrete service by route)
    ▼
Concrete AI Service (e.g. ProductDescriptionService)
    ├── AiUsageService.checkLimit()   → throws AiRateLimitException if over limit
    ├── AiProviderInterface.complete() → sends prompt to Gemini
    └── AiUsageService.record()        → increments daily/monthly usage counters
    │
    ▼
GeminiProviderService
    │
    │  HTTPS  (API key)
    ▼
Google Gemini API
    │
    ▼
Response → shaped by AiController → returned to Flutter
```

### AI Usage Tracking

Each AI generation call:
1. **Checks** `ai_settings` (is AI enabled for this merchant? daily/monthly limit?)
2. **Checks** `ai_usages` (how many calls today/this month?)
3. **Calls** Gemini if within limits
4. **Records** the call in `ai_usages` (increments count + credits_used)
5. **Logs** the full request/response in `ai_requests` for admin analytics

---

## Authentication Flow

```
POST /api/v1/auth/login
    │
    ▼
AuthController → AuthService
    ├── Validates credentials (email + password)
    ├── Checks user status (banned/inactive → 403)
    └── Creates a Sanctum Personal Access Token
    │
    ▼
Response: { token, user }

────────────────────────────────────────────────────────
Subsequent requests:
    Authorization: Bearer <token>
    │
    ▼
auth:sanctum middleware
    └── Resolves $request->user()
    │
    ▼
EnsureUserIsActive middleware
    └── If user is banned/inactive → 403
    │
    ▼
EnsureRole middleware (on protected groups)
    └── If role does not match → 403
```

---

## Role-Based Access Control

Three roles exist. Each has a separate route group with its own `role:` middleware:

| Role | Can access |
|---|---|
| `client` | Public marketplace, cart, orders (own), favorites, reviews |
| `merchant` | Own store & products, incoming orders, AI generation, subscription |
| `admin` | All users, all stores, all products, categories, plans, subscription requests, AI analytics |

Roles are mutually exclusive — a merchant cannot access client-only routes, and vice versa.

---

## Error Handling

All exceptions are caught and formatted in `bootstrap/app.php` using Laravel's `withExceptions()` callback. The following exceptions map to specific HTTP responses:

| Exception | HTTP Status |
|---|---|
| `AuthenticationException` | 401 |
| `AuthorizationException` | 403 |
| `EnsureUserIsActive` (banned) | 403 |
| `NotFoundHttpException` | 404 |
| `MethodNotAllowedHttpException` | 405 |
| `ValidationException` | 422 |
| `CartException`, `OrderException` | 422 |
| `ThrottleRequestsException` | 429 |
| `AiRateLimitException` | 429 |
| `AiProviderException` | 503 |
| Unhandled `Throwable` (non-HTTP) | 500 |

---

## Rate Limiting

Two rate limiters are defined in `AppServiceProvider`:

| Limiter | Limit | Key | Applied to |
|---|---|---|---|
| `auth` | 5 req/min | IP address | Login, register, password reset |
| `api` | 60 req/min | User ID (or IP for guests) | All API routes |

The `Retry-After` header is included in all 429 responses so clients can implement back-off.

---

## File Storage

Uploaded files use Laravel's `public` disk, which maps to `storage/app/public/`. A symlink at `public/storage` makes files web-accessible.

| Upload type | Stored in |
|---|---|
| Product images | `products/` |
| Store logos | `stores/` |
| User avatars | `avatars/` |
| Payment proof images | `subscription-requests/` |

All file URLs are generated at read time using `Storage::disk('public')->url($path)` inside API Resources — the database stores only relative paths.

---

## Queue & Mail

- **Queue:** `sync` driver — jobs run synchronously in the same request, no separate worker needed. To switch to a background queue in production, change `QUEUE_CONNECTION` to `database` or `redis`.
- **Mail:** `log` driver in development — emails are written to `storage/logs/laravel.log` rather than actually sent. Switch to `smtp` or an external provider in production.
