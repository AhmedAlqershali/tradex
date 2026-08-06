# TradexAPI — Backend Developer Guide

## Project Overview

TradexAPI is the backend for **Tradex**, a multi-vendor mobile marketplace. Merchants create stores and list products; clients browse, cart, and order; admins govern users, categories, and subscription plans. An AI SaaS layer (powered by Google Gemini) gives merchants AI-generated product descriptions, marketing copy, and customer reply drafts.

**Stack:** Laravel 12 · PHP 8.2+ · SQLite · Sanctum (token auth) · Google Gemini

---

## Folder Structure

```
tradex-backend/
├── app/
│   ├── Contracts/                  Interface definitions
│   │   ├── Repositories/           Repository interfaces
│   │   └── Services/               Service interfaces (incl. AI/)
│   ├── Exceptions/                 Domain exception classes
│   ├── Http/
│   │   ├── Controllers/Api/V1/     Route handlers (thin controllers)
│   │   │   ├── Admin/              Admin-only controllers
│   │   │   ├── Client/             Client-only controllers
│   │   │   ├── Merchant/           Merchant-only controllers
│   │   │   ├── AuthController.php
│   │   │   ├── AiController.php
│   │   │   ├── ProfileController.php
│   │   │   ├── DeviceTokenController.php
│   │   │   └── BaseApiController.php  Response helper methods
│   │   ├── Middleware/
│   │   │   ├── EnsureRole.php      Checks user->role matches route group
│   │   │   └── EnsureUserIsActive.php  Rejects banned/inactive users
│   │   ├── Requests/               Form Request validation classes
│   │   └── Resources/              API Resource transformers
│   ├── Models/                     Eloquent models
│   ├── Policies/                   Authorization logic
│   ├── Providers/
│   │   ├── AppServiceProvider.php  Rate limiters, email verification URL
│   │   └── RepositoryServiceProvider.php  Interface → concrete bindings
│   ├── Repositories/Eloquent/      Concrete database access classes
│   └── Services/
│       ├── AI/                     AI service layer
│       └── *.php                   Domain services
├── bootstrap/
│   └── app.php                     Middleware config, exception handlers
├── config/                         Laravel config files
├── database/
│   ├── factories/                  Model factories for testing
│   ├── migrations/                 Schema migrations (chronological)
│   └── seeders/                    Sample data seeders
├── docs/                           ← You are here
├── routes/
│   └── api.php                     All API route definitions
└── tests/
    ├── Feature/                    HTTP integration tests
    │   ├── Admin/
    │   ├── AI/
    │   ├── Auth/
    │   ├── Client/
    │   ├── Merchant/
    │   └── Security/
    └── Unit/
```

---

## Laravel Architecture Explained

### Controllers

Controllers are **thin**. Each controller method:
1. Receives a validated `FormRequest` (or plain `Request`)
2. Calls exactly one service method
3. Returns a JSON response using `BaseApiController` helpers

Controllers never contain business logic, database queries, or `if/else` decision trees. If you find yourself doing that, move the logic to the service.

### Services

Services own **all business logic**: validation beyond field formats, transactions, cross-model orchestration, and exception throwing. Each service implements an interface from `app/Contracts/Services/`.

Example: `OrderService::checkout()` groups cart items by store, runs a database transaction, creates orders, clears the cart, and fires notifications — all in one cohesive method.

### Repositories

Repositories own **all database access**. Services never call Eloquent models directly; they call repository methods. Each repository implements an interface from `app/Contracts/Repositories/`.

This keeps the services testable — a test can inject a fake repository without hitting the database.

### Models

Models contain:
- `$fillable` list
- `casts()` method
- Eloquent relationships (`belongsTo`, `hasMany`, etc.)
- Named scopes (`scopeActive`, `scopeMerchants`)
- Simple helper methods (`isMerchant()`, `isActive()`)

Models do **not** contain business logic. No complex methods that span multiple tables or call services.

### Form Requests

Every controller action that accepts body data has a dedicated `FormRequest` class. The request class defines validation `rules()` and custom `messages()`. Laravel automatically resolves and validates these before the controller method runs, returning a 422 with the standard envelope on failure.

### API Resources

`JsonResource` and `ResourceCollection` subclasses transform Eloquent models into JSON shapes. They hide internal column names, resolve storage URLs, and conditionally include related data (e.g. `stores` only in merchant responses).

Never call `$model->toArray()` in a controller. Always go through a Resource.

### Policies

Gate authorization rules. Policies are used for resource-ownership checks (e.g. "can this merchant update this product?"). They are invoked via `$this->authorize()` in the controller or explicitly with `Gate::authorize()`.

Current policies: `CategoryPolicy`, `PlanPolicy`, `ProductPolicy`, `StorePolicy`, `SubscriptionRequestPolicy`, `UserPolicy`.

---

## User Roles

| Role | Registration | Capabilities |
|---|---|---|
| `client` | `POST /auth/register/client` | Browse marketplace, cart, order, review, favorites |
| `merchant` | `POST /auth/register/merchant` | Manage own store & products, receive orders, use AI tools, subscribe to plans |
| `admin` | Created manually / via admin panel | Full control: users, stores, categories, plans, subscription requests, AI analytics |

Roles are set at registration and can be changed by an admin via `PUT /admin/users/{id}/role`.

## User Statuses

| Status | Effect |
|---|---|
| `active` | Normal access |
| `banned` | `EnsureUserIsActive` returns 403 on every authenticated request and revokes all tokens |
| `inactive` | Same as banned — treated identically in middleware |

---

## Authentication Flow

### Registration

**Client:** `POST /auth/register/client` → creates `User` with `role = client`.

**Merchant:** `POST /auth/register/merchant` → creates `User` (role = merchant) **and** `Store` in a single database transaction. If the store insert fails, the user is rolled back too.

After registration, the server returns `{ token, user }` — the user is immediately logged in.

### Email Verification

An email with a signed URL is sent after registration. The Flutter app intercepts the URL via deep-link, calls `GET /auth/email/verify/{id}/{hash}`, and reads the JSON response. Unverified users can still access all endpoints (verification is not enforced at the route level — add `verified` middleware if you want to enforce it).

### Login

`POST /auth/login` validates credentials, checks user status, and creates a Sanctum Personal Access Token. Token expiry is controlled by `SANCTUM_EXPIRATION_MINUTES` (default: 90 days).

### Logout

`POST /auth/logout` deletes the current access token. The user must log in again to obtain a new token.

---

## Modules

### Authentication Module

**Files:** `AuthController`, `AuthService`, `AuthServiceInterface`  
**Requests:** `ClientRegisterRequest`, `MerchantRegisterRequest`, `LoginRequest`, `ForgotPasswordRequest`, `ResetPasswordRequest`  
**Routes:** `/auth/*`

Handles registration, login, logout, password reset, and email verification. The `AuthService` encapsulates all token creation and password reset logic. Password reset uses Laravel's built-in `Password` facade with an email notification.

---

### Marketplace (Public Browsing)

**Controllers:** `Client\ProductController`, `Client\StoreController`, `Client\CategoryController`  
**Services:** `ProductService`, `StoreService`, `CategoryService`  
**Routes:** `GET /products`, `GET /products/{id}`, `GET /stores`, `GET /stores/{id}`, `GET /categories`, `GET /categories/{id}`

All public — no authentication required. Supports:
- Keyword search (`?search=keyword`)
- Category filter (`?category_id=3`)
- Price range filter (`?min_price=10&max_price=100`)
- Pagination (`?per_page=15`, max 100)

---

### Cart Module

**Controller:** `Client\CartController`  
**Service:** `CartService` / `CartServiceInterface`  
**Repository:** `CartRepository` / `CartRepositoryInterface`  
**Model:** `Cart`, `CartItem`  
**Routes:** `GET|POST|PUT|DELETE /cart/*`  
**Role required:** `client`

The cart is created automatically on the first item add. `unit_price` is snapshot from the product at add-time — subsequent price changes do not affect the pending cart total. The cart is cleared atomically after a successful checkout.

---

### Order Module

**Controllers:** `Client\OrderController`, `Merchant\OrderController`  
**Service:** `OrderService` / `OrderServiceInterface`  
**Repository:** `OrderRepository` / `OrderRepositoryInterface`  
**Models:** `Order`, `OrderItem`  
**Routes (client):** `POST|GET /orders`, `GET|DELETE /orders/{id}`  
**Routes (merchant):** `GET /merchant/orders`, `GET /merchant/orders/{id}`, `PUT /merchant/orders/{id}/status`

**Checkout flow (`OrderService::checkout`):**
1. Load the client's cart (throw `CartException::cartEmpty()` if empty)
2. Group cart items by `store_id`
3. Open a database transaction
4. For each store group: deduct stock, create an `Order` + `OrderItems`, calculate total
5. If any item is out of stock, throw `OrderException::insufficientStock()` — the whole transaction rolls back
6. Clear the cart
7. **Outside the transaction:** send notifications to client and merchants (failure here does not roll back the orders)

**Order status transitions:**

```
pending → confirmed → processing → completed
    └─────────────────────────────→ cancelled (client, pending only)
```

Merchants advance the status. Clients can cancel only while `pending`.

---

### Merchant Store & Product Management

**Controllers:** `Merchant\StoreController`, `Merchant\ProductController`  
**Services:** `StoreService`, `ProductService`  
**Models:** `Store`, `Product`, `ProductImage`  
**Routes:** `/merchant/store`, `/merchant/products/*`  
**Role required:** `merchant`

Merchants manage one store and its products. Product images are stored via the `public` disk. The `ProductPolicy` ensures merchants can only modify their own products.

---

### Merchant Dashboard & Analytics

**Controller:** `Merchant\DashboardController`  
**Service:** `MerchantDashboardService` / `MerchantDashboardServiceInterface`  
**Routes:** `GET /merchant/dashboard`, `GET /merchant/analytics`  
**Role required:** `merchant`

Returns sales summary, recent orders, and order status breakdown for the merchant's stores.

---

### Reviews

**Controllers:** `Client\ReviewController`, `Admin\ReviewController`  
**Service:** `ReviewService` / `ReviewServiceInterface`  
**Repository:** `ReviewRepository` / `ReviewRepositoryInterface`  
**Model:** `Review`  
**Routes (client):** `GET|POST /products/{productId}/reviews`, `DELETE /reviews/{id}`  
**Routes (admin):** `GET /admin/products/{productId}/reviews`, `DELETE /admin/reviews/{id}`

One review per client per product (enforced by unique constraint). Clients can delete their own reviews. Admins can delete any review.

---

### Favorites

**Controller:** `Client\FavoriteController`  
**Service:** `FavoriteService` / `FavoriteServiceInterface`  
**Model:** `Favorite`  
**Routes:** `GET|POST /favorites`, `DELETE /favorites/{id}`  
**Role required:** `client`

---

### Notifications

**Controller:** `Client\NotificationController`  
**Service:** `NotificationService` / `NotificationServiceInterface`  
**Model:** `Notification`  
**Routes:** `GET /notifications`, `PATCH /notifications/{id}/read`, `POST /notifications/read-all`  
**Role required:** all authenticated users

Notifications are created in the database by `NotificationService`. Device token management (`DeviceTokenController`) stores FCM/APNS tokens for push delivery.

---

### Admin Module

**Controllers:** All files under `Admin/`  
**Services:** `UserManagementService`, `AdminDashboardService`, `AdminStoreManagementService`, `CategoryService`, `PlanService`  
**Routes:** All under `/admin/*`  
**Role required:** `admin`

Covers: user CRUD + status/role management, store status management, category CRUD, plan CRUD, subscription request approval/rejection, product viewing, review moderation, platform analytics.

---

### Subscription System

**Controllers:** `Merchant\SubscriptionController`, `Admin\SubscriptionRequestController`  
**Services:** `SubscriptionService`, `SubscriptionRequestService`  
**Models:** `Plan`, `Subscription`, `SubscriptionRequest`  
**Routes (merchant):** `GET /merchant/subscription-requests`, `POST /merchant/subscription-requests`  
**Routes (admin):** `GET|PUT /admin/subscription-requests/*`

Manual subscription flow (no payment gateway):
1. Merchant submits a request with payment proof image
2. Admin reviews and approves/rejects
3. On approval, a `Subscription` is created and the merchant's `ai_settings` are updated with the plan's credit limits

---

### AI SaaS Module

**Controller:** `AiController`  
**Services:** `AI/ProductDescriptionService`, `AI/MarketingContentService`, `AI/CustomerReplyService`, `AI/AiAnalyticsService`, `AI/AiUsageService`  
**Provider:** `AI/GeminiProviderService` (implements `AiProviderInterface`)  
**Models:** `AiUsage`, `AiSetting`, `AiRequest`  
**Routes:** `POST /ai/product-description`, `POST /ai/marketing-content`, `POST /ai/customer-reply` (merchant), `POST /ai/analytics` (admin), `GET /ai/usage` (all auth)

Each AI service follows the same pattern:
1. `AiUsageService::checkLimit()` — checks `ai_settings` and counts `ai_usages` rows
2. `GeminiProviderService::complete()` — sends system prompt + user prompt to Gemini API
3. `AiUsageService::record()` — increments the daily usage counter
4. `AiUsageService::recordRequest()` — writes full audit log to `ai_requests`

---

## Error Handling System

All exceptions are caught in `bootstrap/app.php` and formatted to the standard envelope. Custom domain exceptions live in `app/Exceptions/`:

| Class | HTTP Code | When thrown |
|---|---|---|
| `CartException` | 422 | Cart is empty, item not found |
| `OrderException` | 422 | Insufficient stock, invalid status transition |
| `AiRateLimitException` | 429 | Usage limit reached |
| `AiProviderException` | 503 | Gemini API failure |
| `ReviewException` | 422 | Duplicate review, not owner |
| `SubscriptionException` | 422 | Plan already active |
| `CategoryException` | 422 | Category in use |

---

## How to Add a New Feature

This walkthrough adds a new `GET /api/v1/products/{id}/questions` endpoint.

### Step 1: Migration

```bash
php artisan make:migration create_product_questions_table
```

Define the schema, then run:

```bash
php artisan migrate
```

### Step 2: Model

```bash
php artisan make:model ProductQuestion
```

Add `$fillable`, relationships (`belongsTo Product`, `belongsTo User`).

### Step 3: Repository Interface

Create `app/Contracts/Repositories/ProductQuestionRepositoryInterface.php` with the methods you need (`listForProduct`, `create`, etc.).

### Step 4: Repository Implementation

Create `app/Repositories/Eloquent/ProductQuestionRepository.php` implementing the interface.

### Step 5: Service Interface

Create `app/Contracts/Services/ProductQuestionServiceInterface.php`.

### Step 6: Service Implementation

Create `app/Services/ProductQuestionService.php`. Place all business logic here.

### Step 7: Bind in RepositoryServiceProvider

In `app/Providers/RepositoryServiceProvider.php` add:

```php
$this->app->bind(ProductQuestionRepositoryInterface::class, ProductQuestionRepository::class);
$this->app->bind(ProductQuestionServiceInterface::class, ProductQuestionService::class);
```

### Step 8: Form Request

```bash
php artisan make:request ProductQuestion/StoreQuestionRequest
```

Define validation rules.

### Step 9: API Resource

```bash
php artisan make:resource ProductQuestion/QuestionResource
```

Define the JSON shape.

### Step 10: Controller

```bash
php artisan make:controller Api/V1/Client/ProductQuestionController
```

Extend `BaseApiController`. Inject the service interface. Keep methods thin.

### Step 11: Route

Add to `routes/api.php` inside the appropriate middleware group.

### Step 12: Tests

Create `tests/Feature/Client/ProductQuestionTest.php`. Test authentication requirements, happy paths, and edge cases (not found, unauthorized, validation failures).

```bash
php artisan test tests/Feature/Client/ProductQuestionTest.php
```

---

## Testing Strategy

The test suite is in `tests/Feature/` organized by domain. All feature tests use `RefreshDatabase` (SQLite is reset between tests).

**Running all tests:**
```bash
php artisan test
```

**Running one file:**
```bash
php artisan test tests/Feature/AI/AiGenerationTest.php
```

**What is tested:**
- Authentication requirements (unauthenticated = 401)
- Role enforcement (wrong role = 403)
- Happy paths (correct data = 200/201)
- Validation errors (missing/invalid fields = 422)
- Business rule enforcement (e.g. can't cancel a confirmed order = 422)
- Rate limiting (6th request in 1 minute = 429)
- Error response envelope structure

**What is mocked:**
- `GeminiProviderService` is replaced with a fake in AI tests so no actual API calls are made
- `RateLimiter` state is cleared in `setUp()` in rate limit tests

---

## Maintaining This Project

1. **Keep controllers thin** — if a controller method is more than 20 lines, the logic belongs in the service.
2. **Always use interfaces** — never inject a concrete class where an interface exists. This preserves testability.
3. **Write a test first** — every new endpoint should have at least a 401 test, a role test, and a happy-path test.
4. **Never query in models** — models define relationships and scopes, not business queries. Put those in repositories.
5. **Snapshot data at transaction time** — follow the pattern of `order_items`: copy `product_name` and `unit_price` at the moment of checkout, not from the live product.
6. **Use the standard envelope** — all responses go through `BaseApiController::success()`, `created()`, `error()`, `notFound()`, etc. Never return raw `response()->json()` from a controller.
7. **Document exceptions** — if a service method can throw, annotate it with `@throws` so controllers know what to catch.
