# TradexAPI — Database Documentation

**Driver:** SQLite (development) — migrations are also compatible with MySQL/PostgreSQL for production.  
**ORM:** Laravel Eloquent  
**Migrations:** `database/migrations/`

---

## Entity Relationship Overview

```
users ──────────────────── stores ──────── products ──────── product_images
  │                          │                │
  │                          │                ├──── category_id → categories
  ├── orders (client_id)     │                ├──── order_items
  │     └── order_items      │                ├──── cart_items
  │                          └── orders       ├──── favorites
  ├── carts                        └── order_items
  │     └── cart_items             
  │                          
  ├── favorites → products   
  ├── notifications          
  ├── device_tokens          
  ├── reviews → products     
  ├── subscriptions → plans  
  ├── subscription_requests → plans
  ├── ai_usages              
  ├── ai_settings            
  └── ai_requests            
```

---

## Tables

### `users`

Central identity table. A single `role` column drives the entire RBAC system.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string | Display name |
| `email` | string unique | Login credential |
| `phone` | string(20) nullable | |
| `password` | string | Bcrypt hash |
| `role` | enum | `client` \| `merchant` \| `admin` |
| `avatar` | string nullable | Relative path in `public` disk |
| `status` | enum | `active` \| `banned` \| `inactive` — added via migration |
| `email_verified_at` | timestamp nullable | Null = unverified |
| `remember_token` | string nullable | Laravel standard |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `role`

---

### `password_reset_tokens`

Standard Laravel table for the password-reset flow.

| Column | Type |
|---|---|
| `email` | string PK |
| `token` | string (hashed) |
| `created_at` | timestamp nullable |

---

### `stores`

One merchant may have one store (enforced at the application level during registration, though the schema supports multiple).

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `store_name` | string | |
| `description` | text nullable | |
| `logo` | string nullable | Relative path in `public` disk |
| `status` | enum | `active` \| `inactive` \| `suspended` |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `status`, `user_id`

---

### `categories`

Admin-managed product taxonomy.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string | |
| `image` | string nullable | Relative path in `public` disk |
| `status` | enum | `active` \| `inactive` |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `status`

---

### `products`

Core marketplace inventory item.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `store_id` | FK → stores | Cascade delete |
| `category_id` | FK → categories nullable | Null on category delete |
| `name` | string | |
| `description` | text nullable | |
| `price` | decimal(10,2) | |
| `quantity` | unsignedInt | Available stock |
| `image` | string nullable | Primary image path |
| `status` | enum | `active` \| `inactive` \| `out_of_stock` |
| `total_sold` | unsignedInt | Denormalised sales count — incremented at checkout |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `status`, `store_id`, `category_id`, `price`, `name` (via performance migration)

---

### `product_images`

Additional images for a product (gallery). The primary image is stored as a path on the `products` row itself.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `product_id` | FK → products | Cascade delete |
| `path` | string | Relative path in `public` disk |
| `sort_order` | int | Display order (ascending) |
| `created_at` / `updated_at` | timestamp | |

---

### `carts`

One cart per user. Created automatically on first `addItem` call.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `created_at` / `updated_at` | timestamp | |

---

### `cart_items`

Individual product lines inside a cart. `unit_price` is snapshot at the moment the item is added, so price changes don't silently affect a pending cart.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `cart_id` | FK → carts | Cascade delete |
| `product_id` | FK → products | Cascade delete |
| `quantity` | unsignedInt | |
| `unit_price` | decimal(10,2) | Price snapshot at time of add |
| `created_at` / `updated_at` | timestamp | |

---

### `orders`

One order is created per store during checkout. A cart with items from three stores produces three orders.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `client_id` | FK → users | Cascade delete |
| `store_id` | FK → stores | Cascade delete |
| `status` | enum | `pending` \| `confirmed` \| `processing` \| `completed` \| `cancelled` |
| `total_amount` | decimal(10,2) | Sum of all item subtotals |
| `customer_name` | string | Snapshot at checkout |
| `customer_phone` | string | Snapshot at checkout |
| `customer_address` | string | Snapshot at checkout |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `client_id`, `store_id`, `status`

**Status transitions:**

```
pending → confirmed → processing → completed
    └──────────────────────────────→ cancelled  (client can cancel while pending)
```

---

### `order_items`

Immutable snapshot of what was purchased. Product name and price are copied at checkout so historical orders are accurate even if the merchant later changes a product.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `order_id` | FK → orders | Cascade delete |
| `product_id` | FK → products nullable | Null on product delete (historical record kept) |
| `product_name` | string | Snapshot at checkout |
| `unit_price` | decimal(10,2) | Snapshot at checkout |
| `quantity` | unsignedInt | |
| `subtotal` | decimal(10,2) | `unit_price × quantity` |
| `created_at` / `updated_at` | timestamp | |

---

### `favorites`

User's saved/wishlist products.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `product_id` | FK → products | Cascade delete |
| `created_at` / `updated_at` | timestamp | |

**Unique constraint:** `(user_id, product_id)` — no duplicate favorites.

---

### `notifications`

In-app notification feed. Stored in the database; push delivery via FCM device tokens is handled separately.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `title` | string | |
| `body` | text | |
| `data` | json nullable | Contextual payload (e.g. `{ order_id: 42 }`) |
| `read_at` | timestamp nullable | Null = unread |
| `created_at` / `updated_at` | timestamp | |

---

### `device_tokens`

FCM / APNS push notification tokens. One user may have tokens for multiple devices.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `token` | string unique | FCM/APNS registration token |
| `platform` | string | `android` \| `ios` |
| `created_at` / `updated_at` | timestamp | |

---

### `reviews`

Product ratings left by clients. One review per client per product (unique constraint).

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `product_id` | FK → products | Cascade delete |
| `rating` | unsignedTinyInt | 1–5 |
| `comment` | text nullable | |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `product_id`, `user_id`

---

### `plans`

AI SaaS subscription tiers defined by the admin.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string | e.g. "Starter", "Pro" |
| `price` | decimal(10,2) | |
| `duration_months` | unsignedInt | Billing period |
| `ai_credits_per_month` | unsignedInt | AI generation quota |
| `description` | text nullable | |
| `is_active` | boolean | Hidden from merchants when false |
| `created_at` / `updated_at` | timestamp | |

---

### `subscriptions`

Active merchant subscriptions. Created by admin when they approve a subscription request.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `plan_id` | FK → plans | Restrict delete |
| `status` | enum | `active` \| `expired` \| `cancelled` |
| `started_at` | timestamp | |
| `expires_at` | timestamp | |
| `created_at` / `updated_at` | timestamp | |

---

### `subscription_requests`

Merchants submit a request with payment proof; admin approves or rejects manually.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `plan_id` | FK → plans | Restrict delete |
| `status` | enum | `pending` \| `approved` \| `rejected` |
| `billing_cycle` | string | `monthly` \| `yearly` |
| `full_name` | string | Name on payment |
| `phone` | string | Contact for payment confirmation |
| `payment_method` | string | e.g. "bank transfer", "cash" |
| `payment_proof_image` | string | Path to uploaded proof image |
| `notes` | text nullable | Merchant or admin notes |
| `created_at` / `updated_at` | timestamp | |

---

### `ai_usages`

**One row per user per service type per calendar day.** Tracks how many AI requests a merchant has made today and this month to enforce limits.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `service_type` | string(50) | `product_description`, `marketing_content`, `customer_reply` |
| `request_count` | unsignedInt | Incremented each call |
| `credits_used` | unsignedInt | Incremented by credits per call (default: 1) |
| `date` | date | Calendar date of the usage bucket |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `(user_id, date)`, `(user_id, service_type, date)` (unique)

---

### `ai_settings`

Per-merchant AI configuration set by the admin. Controls whether AI is enabled and the usage limits.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `is_enabled` | boolean | Kill-switch for AI for this merchant |
| `daily_limit` | unsignedInt nullable | Max AI calls per day (null = unlimited) |
| `monthly_limit` | unsignedInt nullable | Max AI calls per month (null = unlimited) |
| `created_at` / `updated_at` | timestamp | |

---

### `ai_requests`

Full audit log of every AI call — input payload, output, tokens used. Used for admin analytics.

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | FK → users | Cascade delete |
| `service_type` | string(50) | |
| `request_payload` | json nullable | The prompt context sent to Gemini |
| `response_content` | longText nullable | The generated text returned |
| `tokens_used` | unsignedInt | Gemini token count |
| `credits_used` | unsignedInt | Credits deducted (default: 1) |
| `status` | string(20) | `completed` \| `failed` |
| `created_at` / `updated_at` | timestamp | |

**Indexes:** `(user_id, created_at)`, `(user_id, service_type)`

---

### `personal_access_tokens`

Managed by Laravel Sanctum. Stores all issued API tokens.

| Column | Type |
|---|---|
| `id` | bigint PK |
| `tokenable_type` | string |
| `tokenable_id` | bigint |
| `name` | string (device name) |
| `token` | string(64) unique (SHA-256 hash) |
| `abilities` | text nullable |
| `last_used_at` | timestamp nullable |
| `expires_at` | timestamp nullable |

---

### `cache` and `jobs`

Standard Laravel tables for the file/database cache and queue (not used in the default `sync` queue configuration).

---

## Performance Indexes

A dedicated migration (`2026_07_24_000001_add_performance_indexes.php`) adds composite indexes for common query patterns:

- `orders (client_id, status)`
- `orders (store_id, status)`
- `products (store_id, status)`
- `products (category_id, status)`
- `cart_items (cart_id, product_id)`
- `favorites (user_id, product_id)`

These indexes are critical for paginated list endpoints as data volume grows.

---

## Key Design Decisions

**Denormalised snapshots in `order_items`:** `product_name` and `unit_price` are copied at checkout. This ensures historical orders remain accurate even if the merchant edits or deletes the product later.

**One cart per user:** The `carts` table has a unique constraint on `user_id`. `CartService` uses `firstOrCreate` so the cart is lazily created on first item add.

**One order per store per checkout:** A single client checkout creates N orders (one per store) so each merchant sees only their own orders and can manage status independently.

**AI usage bucketed by day:** The `ai_usages` table stores one row per `(user_id, service_type, date)` and increments counters. Monthly totals are computed by summing daily rows where `date >= start of month`.
