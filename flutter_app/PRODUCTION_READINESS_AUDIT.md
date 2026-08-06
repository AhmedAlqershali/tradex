# Production Readiness Audit
**Project:** Tradex AI SaaS — Flutter Web  
**Date:** 2026-07-20  
**Scope:** Backend integration architecture + pre-integration code audit

---

## Business Flow (Source of Truth)

```
Customer browses stores & products
         │
         ▼
Customer adds products to cart
         │
         ▼
Customer submits order (name, phone, city, notes)
         │
         ▼
Merchant receives order notification
         │
         ▼
Merchant contacts customer directly (WhatsApp / phone)
         │
         ▼
Merchant updates order status:
  pending → accepted → preparing → completed
                              └──→ cancelled
```

**There is no:** online payment, delivery tracking, shipping cost calculation, or driver app.

---

## Section 1 — Compilation Status ✅

`flutter analyze` passes with **0 errors**.  
Remaining: ~15 warnings (unused imports/fields) and deprecation hints (`withOpacity` → `withValues()`). None are blockers.

---

## Section 2 — Screen Line Counts

### Over 400 lines — refactoring candidates (proposed tasks #2)

| Screen | Lines | Primary cause of size |
|---|---|---|
| `ai_marketing_tools_screen.dart` | **966** | AI tool cards + bottom sheets all inline |
| `merchant_products_screen.dart` | **784** | Filter row + product grid + actions inline |
| `checkout_screen.dart` | **628** | Order form + product summary inline |
| `edit_product_screen.dart` | **558** | Full form; mirrors `add_product.dart` |
| `add_product.dart` | **510** | Image picker + form + AI stubs inline |
| `auth/complete_registration_merchant_screen.dart` | **473** | Multi-step form inline |
| `client/cart_screen.dart` | **471** | Item list + totals + empty state inline |
| `profile_screen.dart` | **451** | Edit form + photo picker inline |
| `search_screen.dart` | **446** | Filter row + results grid inline |
| `product_details_screen.dart` | **437** | Gallery + info + CTA inline |
| `store_details_screen.dart` | **406** | Store header + product grid inline |
| `widgets/ai_tools/ai_tool_sheet.dart` | **437** | Widget file itself exceeds limit |

### Within 300 lines — clean after refactoring ✅

`shopper_home` (139 lines), `client_order_details` (136), `merchant_order_details` (289), `merchant_home` (294), `notification` (190), `nearby_stores` (180).

---

## Section 3 — Architecture Assessment

### Folder structure
```
lib/
├── core/theme/          ✅ AppColors + AppTextStyles (design tokens)
├── models/              ⚠️  3 global enums — consolidate into lib/shared/models/ later
├── screens/
│   ├── auth/            ✅ 7 screens
│   ├── client/          ✅ 6 screens + extracted home widgets
│   ├── merchant/        ✅ 7 screens + extracted AI widgets
│   └── widgets/         ✅ 5 generic screen widgets
└── shared/
    ├── ai/              ✅ AiController + AiResultModel
    ├── cart/            ✅ CartController + CartItem
    ├── favorites/        ✅ FavoriteController
    ├── models/          ⚠️  mock_order.dart — legacy name, holds OrderStatus enum
    ├── navigation/      ✅ NavConfig + NavShell
    ├── notifications/   ✅ NotificationController
    ├── orders/          ✅ OrderController + AppOrder + AppOrderProduct
    ├── products/        ✅ ProductController (seeded mock data)
    ├── users/           ✅ UserController + AppUser
    └── widgets/         ✅ 9 shared UI widgets
```

**Notable gaps:**
- `AppOrder` / `AppOrderProduct` defined inside `order_controller.dart` — needs its own model file with `fromJson`/`toJson` before API work
- `CityModel` and `ItemCategory` contain hardcoded static lists — replace with API config endpoints
- `add_product.dart` hardcodes `storeName: 'متجري'` — must come from authenticated merchant profile
- `checkout_screen.dart` hardcodes default customer name "أحمد محمد أبو سالم" — must come from `UserController`

### Controller / screen separation ✅
All 6 controllers are singletons with `ValueNotifier`, contain zero widget imports, and screens use `ValueListenableBuilder`. This pattern is correct and makes API replacement straightforward.

### Loading / error states ⚠️
- ✅ `EmptyState` widget used in cart and order screens
- ❌ No loading indicators on any form submit (login, checkout, add product, order status update)
- ❌ No `ErrorState` widget — network failures are silently swallowed
- ❌ No skeleton/shimmer on product and store list loads

---

## Section 4 — Backend API Architecture

### Data model overview

```
User ──────────────┬── (role: client)   ──► Orders (as buyer)
                   └── (role: merchant) ──► Store ──► Products
                                                 └──► Orders (as seller)

Order ─────────────── OrderItems (product snapshot)
                   └── status: pending|accepted|preparing|completed|cancelled

Product ───────────── ProductImages[]
        └─────────── Category
        └─────────── Store (owner)

Favorite ──────────── User + Product

Notification ──────── User + (order_ref or system)

AiJob ─────────────── Merchant + tool_type + result_text
```

---

### API Endpoint Specification

#### Auth

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/auth/register` | Create customer or merchant account |
| `POST` | `/auth/login` | Returns JWT access + refresh tokens |
| `POST` | `/auth/refresh` | Exchange refresh token for new access token |
| `POST` | `/auth/logout` | Revoke refresh token |
| `POST` | `/auth/verify-otp` | Verify phone/email OTP |
| `POST` | `/auth/forgot-password` | Request reset OTP |
| `POST` | `/auth/reset-password` | Submit new password with OTP |

#### Users & Profiles

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/users/me` | Load authenticated user |
| `PUT` | `/users/me` | Update name, phone, city |
| `POST` | `/users/me/avatar` | Upload profile photo → returns URL |

#### Stores (merchant-owned)

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/stores` | Browse all stores (customer home) |
| `GET` | `/stores/:id` | Single store detail |
| `GET` | `/stores/me` | Authenticated merchant's own store |
| `PUT` | `/stores/me` | Update store name, description, logo |
| `POST` | `/stores/me/logo` | Upload store logo → returns URL |
| `GET` | `/stores/:id/products` | Products belonging to a store |

#### Products

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/products` | Paginated product list (supports `?category=`, `?store=`, `?featured=true`) |
| `GET` | `/products/:id` | Single product detail |
| `GET` | `/products/search?q=` | Full-text search |
| `POST` | `/products` | Create product (merchant only) |
| `PUT` | `/products/:id` | Update product (merchant only, own store) |
| `DELETE` | `/products/:id` | Delete product (merchant only, own store) |
| `POST` | `/products/:id/images` | Upload one product image → returns URL |
| `DELETE` | `/products/:id/images/:imgId` | Remove a product image |

#### Categories & Config

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/config/categories` | Item categories list (replaces hardcoded `ItemCategory`) |
| `GET` | `/config/cities` | Cities list (replaces hardcoded `CityModel`) |

#### Cart

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/cart` | Load persisted cart for authenticated customer |
| `POST` | `/cart/items` | Add item `{ product_id, quantity }` |
| `PUT` | `/cart/items/:itemId` | Update quantity |
| `DELETE` | `/cart/items/:itemId` | Remove item |
| `DELETE` | `/cart` | Clear entire cart |

> Cart persistence means a customer who logs in from another device sees their cart intact.

#### Orders

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/orders` | Customer submits order (cart snapshot + contact info) |
| `GET` | `/orders?role=client` | Customer's own order history |
| `GET` | `/orders?role=merchant` | Merchant's incoming orders |
| `GET` | `/orders/:ref` | Single order detail |
| `PATCH` | `/orders/:ref/status` | Merchant updates status `{ status: "accepted" }` |

**Order creation payload:**
```json
{
  "customer_name": "...",
  "customer_phone": "...",
  "customer_city": "...",
  "notes": "...",
  "items": [
    { "product_id": "...", "product_name": "...", "price": 0.0, "quantity": 1 }
  ]
}
```
Items are a **snapshot** (name + price at time of order), not live references — this avoids stale data if a product is later edited or deleted.

**Order status flow:**
```
pending ──► accepted ──► preparing ──► completed
                └───────────────────► cancelled
```
Only the **merchant** may change status. The customer sees it read-only.

#### Favorites

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/favorites` | Authenticated customer's favorite products |
| `POST` | `/favorites` | Add `{ product_id }` |
| `DELETE` | `/favorites/:productId` | Remove |

#### Notifications

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/notifications` | All notifications for authenticated user |
| `PATCH` | `/notifications/:id/read` | Mark one as read |
| `PATCH` | `/notifications/read-all` | Mark all as read |

**When a notification is created server-side:**
- Customer submits order → merchant receives "new order" notification
- Merchant updates order status → customer receives "order status changed" notification

#### AI Features (merchant only)

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/ai/product-description` | Generate product description from name + category |
| `POST` | `/ai/marketing-post` | Generate social media post from product info |
| `POST` | `/ai/hashtags` | Generate hashtags from product/post content |
| `POST` | `/ai/customer-reply` | Suggest reply to a customer message |
| `GET` | `/ai/history` | Merchant's recent AI operations |

**Request shape (all AI endpoints):**
```json
{ "context": "product name, category, brief notes", "language": "ar" }
```
**Response shape** maps directly to existing `AiResultModel`.

---

## Section 5 — Flutter Integration Plan

### Package additions needed

```yaml
dependencies:
  dio: ^5.x              # HTTP client with interceptors
  flutter_secure_storage: ^9.x   # Encrypted token storage (replaces SharedPreferences for auth)
  url_launcher: ^6.x     # WhatsApp deep-link in product_details_screen.dart
```

### New files to create in `lib/core/`

```
lib/core/
├── api/
│   ├── api_client.dart          # Singleton Dio instance, auth interceptor, base URL
│   ├── api_constants.dart       # Base URL + all endpoint path constants
│   └── api_exception.dart       # Typed error (network, auth, server, timeout)
└── services/
    ├── auth_service.dart        # Raw API calls for auth endpoints
    ├── user_service.dart
    ├── store_service.dart
    ├── product_service.dart
    ├── cart_service.dart
    ├── order_service.dart
    ├── favorite_service.dart
    ├── notification_service.dart
    └── ai_service.dart
```

Controllers in `lib/shared/` call their corresponding service. Services only do HTTP; controllers handle state.

### Auth flow in Flutter

```
App cold start
  └─► UserController.init()
        └─► SecureStorage.read("access_token")
              ├─ found ──► GET /users/me ──► populate UserController
              └─ not found ──► show login/onboarding
```

Token refresh: Dio interceptor catches 401 → calls `POST /auth/refresh` → retries original request → if refresh fails, calls `UserController.logout()` and redirects to login.

### Controller swap plan (no screen changes needed)

Each controller method maps 1-to-1 to a service call:

| Controller method | Replaces | Service call |
|---|---|---|
| `UserController.login(email, pass)` | Local session creation | `AuthService.login()` |
| `ProductController.loadProducts()` | `_seedProducts()` | `ProductService.getProducts()` |
| `ProductController.searchProducts(q)` | Local `.where()` filter | `ProductService.search(q)` |
| `OrderController.placeOrder(...)` | In-memory append | `OrderService.createOrder()` |
| `OrderController.updateOrderStatus(...)` | Local field update | `OrderService.patchStatus()` |
| `CartController.addItem(...)` | In-memory list mutation | `CartService.addItem()` |
| `AiController.generateDescription(...)` | `Future.delayed` mock | `AiService.generateDescription()` |
| `NotificationController.load()` | Hardcoded list | `NotificationService.getAll()` |

---

## Section 6 — Integration Checklist

### Phase A — Infrastructure

- [ ] Add `dio`, `flutter_secure_storage`, `url_launcher` to `pubspec.yaml`
- [ ] Create `lib/core/api/api_client.dart` — Dio singleton, base URL from env, auth header interceptor, 401 refresh logic
- [ ] Create `lib/core/api/api_constants.dart` — all endpoint path strings
- [ ] Create `lib/core/api/api_exception.dart` — typed error class
- [ ] Add `ErrorState` widget to `lib/shared/widgets/` (parallel to existing `EmptyState`)
- [ ] Add loading indicator support to all async form submits

### Phase B — Authentication

- [ ] Implement `AuthService` + wire `login_screen.dart`
- [ ] Implement registration flow (`register_screen.dart` + OTP screen)
- [ ] Implement forgot/reset password screens
- [ ] Replace `SharedPreferences` session with `SecureStorage` for JWT
- [ ] `UserController.init()` — cold-start token rehydration

### Phase C — Profile & Store

- [ ] `UserService.getMe()` + `updateMe()` — wire `profile_screen.dart`
- [ ] Avatar upload — wire photo picker in `profile_screen.dart` and `complete_profile_photo_screen.dart`
- [ ] `StoreService.getMyStore()` — replace hardcoded `storeName: 'متجري'` in `add_product.dart`
- [ ] Store logo upload — wire `complete_registration_merchant_screen.dart`

### Phase D — Products & Stores

- [ ] `ProductService.getProducts()` — replace `_seedProducts()` + `_seedStores()`
- [ ] `ProductService.search()` — replace local filter in `search_screen.dart`
- [ ] `ProductService.create()` + image upload — wire `add_product.dart` submit
- [ ] `ProductService.update()` + image upload — wire `edit_product_screen.dart` submit
- [ ] `ProductService.delete()` — wire delete action in `merchant_products_screen.dart`
- [ ] Product image multi-upload — update `add_product.dart` / `edit_product_screen.dart`
- [ ] Replace `ItemCategory` hardcoded list with `GET /config/categories`
- [ ] Replace `CityModel` hardcoded list with `GET /config/cities`
- [ ] Add pagination to product list screens (home + merchant products)
- [ ] `FavoriteService` — replace `FavoriteController` in-memory toggle with real API

### Phase E — Cart

- [ ] `CartService` — replace `CartController` in-memory operations with server-synced calls
- [ ] Pre-fill checkout form from `UserController` (name, phone, city) — remove hardcoded defaults

### Phase F — Orders

- [ ] Add `fromJson`/`toJson` to `AppOrder` + `AppOrderProduct`
- [ ] `OrderService.createOrder()` — wire `checkout_screen.dart` submit button
- [ ] `OrderService.getOrders(role: client)` — wire `client_orders_screen.dart`
- [ ] `OrderService.getOrders(role: merchant)` — wire `merchant_orders_screen.dart`
- [ ] `OrderService.getOrder(ref)` — wire both order detail screens
- [ ] `OrderService.patchStatus()` — wire status buttons in `merchant_order_details_screen.dart`
- [ ] WhatsApp deep-link — `product_details_screen.dart` TODO at line 296 → use `url_launcher`

### Phase G — AI Features

- [ ] `AiService` — implement all 4 AI endpoint calls
- [ ] Add `OPENAI_API_KEY` (or equivalent) to Replit Secrets
- [ ] Replace `AiController._mockGenerate()` with `AiService` calls
- [ ] Persist AI history via `GET /ai/history` — replace in-memory list
- [ ] Add `fromJson` to `AiResultModel` for API response mapping

### Phase H — Notifications

- [ ] `NotificationService.getAll()` — replace hardcoded mock list
- [ ] `NotificationService.markRead()` — wire notification tap
- [ ] Push notifications — add `firebase_messaging` package + FCM setup for order alerts

### Phase I — UX Polish

- [ ] Loading state on: login, register, checkout, add/edit product, order status update, AI generate
- [ ] Use `ErrorState` widget on: product list, order list, profile load, store load
- [ ] Retry button on any fetch-failure screen
- [ ] Replace all hardcoded `Color(0xff4D41DF)` / `Color(0xffF8F9FD)` in ~12 screens with `AppColors` references

---

## Section 7 — What Does NOT Change

The following are **not part of Tradex** and must not be added:

- ❌ Online payment / payment gateway
- ❌ Shipping cost calculation
- ❌ Delivery tracking
- ❌ Driver / courier app or flow
- ❌ Invoice generation
- ❌ Returns / refunds system

All financial and fulfillment steps happen **outside the app**, directly between merchant and customer.

---

*End of audit — architecture is ready for backend integration.*
