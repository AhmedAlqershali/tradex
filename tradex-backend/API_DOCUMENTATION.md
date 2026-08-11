# TradxAPI — API Documentation

**Base URL:** `https://<your-domain>/api/v1`  
**Auth:** Bearer token via Laravel Sanctum (`Authorization: Bearer <token>`)  
**Content-Type:** `application/json`  
**File Uploads:** `multipart/form-data`

---

## Response Envelope

All responses follow a consistent structure:

```json
{
  "success": true,
  "message": "Human-readable message.",
  "data": { ... }
}
```

Error responses:
```json
{
  "success": false,
  "message": "Validation failed.",
  "data": null,
  "errors": { "field": ["error message"] }
}
```

---

## HTTP Status Codes

| Code | Meaning                              |
|------|--------------------------------------|
| 200  | OK                                   |
| 201  | Created                              |
| 401  | Unauthenticated (missing/invalid token) |
| 403  | Forbidden (wrong role / policy denial) |
| 404  | Not found                            |
| 422  | Validation failed / Business rule    |
| 429  | Too Many Requests (rate-limited)     |
| 500  | Server error                         |

---

## Pagination

All list endpoints that support pagination return:

```json
{
  "data": {
    "data": [...],
    "pagination": {
      "total": 100,
      "per_page": 15,
      "current_page": 1,
      "last_page": 7,
      "from": 1,
      "to": 15
    }
  }
}
```

Query parameter: `?per_page=15` (max: 100)

---

## Health Check

### `GET /health`

Public. Returns API status.

**Sample Response:**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "status": "ok",
    "version": "v1",
    "app": "TradxAPI"
  }
}
```

---

## Authentication

### `POST /auth/register/client`

Register a new client account. Rate limited: 5 req/min/IP.

**Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "0501234567",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Client account created successfully.",
  "data": {
    "token": "1|abc...",
    "user": { "id": 1, "name": "John Doe", "role": "client" }
  }
}
```

---

### `POST /auth/register/merchant`

Register a new merchant account + store atomically. Rate limited: 5 req/min/IP.

**Body:**
```json
{
  "name": "Jane Merchant",
  "email": "jane@example.com",
  "phone": "0509876543",
  "password": "Password123!",
  "password_confirmation": "Password123!",
  "store_name": "Jane's Store",
  "store_description": "Optional description"
}
```

**Response (201):** Same structure as client registration.

---

### `POST /auth/login`

**Body:**
```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "device_name": "flutter_app"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "2|xyz...",
    "user": { "id": 1, "name": "Jane", "role": "merchant" }
  }
}
```

---

### `POST /auth/logout` 🔐

Revokes the current Sanctum token.

**Response (200):** `{ "success": true, "message": "Logged out successfully." }`

---

### `GET /auth/me` 🔐

Returns the authenticated user profile. Merchants also receive their stores
array and a `current_subscription` object containing the current trial/paid
type, status, entitlement flag, and server-calculated start/end timestamps.
Clients and admins do not receive merchant subscription state.

---

### `POST /auth/password/forgot`

Sends a password reset email. Always returns 200 (prevents email enumeration). Rate limited.

**Body:** `{ "email": "user@example.com" }`

---

### `POST /auth/password/reset`

Consumes the reset token and updates the password.

**Body:**
```json
{
  "email": "user@example.com",
  "token": "reset_token",
  "password": "NewPass123!",
  "password_confirmation": "NewPass123!"
}
```

---

### `GET /auth/email/verify/{id}/{hash}` (Signed URL)

Verifies a user's email address. URL is emailed to the user as a signed link.

---

### `POST /auth/email/resend` 🔐

Resends the verification email.

---

## Profile

All require `auth:sanctum`.

### `GET /profile` 🔐

Returns the authenticated user's profile.

### `PUT /profile` 🔐

Update name, email, phone.

**Body (all optional):**
```json
{
  "name": "New Name",
  "email": "new@example.com",
  "phone": "0501111111"
}
```

### `PUT /profile/password` 🔐

**Body:**
```json
{
  "current_password": "OldPass123!",
  "password": "NewPass123!",
  "password_confirmation": "NewPass123!"
}
```

### `POST /profile/avatar` 🔐

Multipart upload. Field: `avatar` (image, max 2MB).

---

## Notifications

All require `auth:sanctum`.

### `GET /notifications` 🔐

Paginated notifications for the authenticated user.

**Response:**
```json
{
  "data": {
    "data": [
      { "id": 1, "title": "Order Placed", "body": "...", "is_read": false, "created_at": "..." }
    ],
    "pagination": { ... }
  }
}
```

### `PUT /notifications/read-all` 🔐

Marks all notifications as read.

### `PUT /notifications/{id}/read` 🔐

Marks a single notification as read.

### `DELETE /notifications/{id}` 🔐

Deletes a notification.

---

## Device Tokens

All require `auth:sanctum`. Rate limited: 30 req/min.

### `GET /device-tokens` 🔐
### `POST /device-tokens` 🔐

**Body:** `{ "token": "fcm_token_string", "platform": "android" }`

### `DELETE /device-tokens` 🔐
Removes all tokens for the user.

### `DELETE /device-tokens/{token}` 🔐
Removes a specific token.

---

## Public Marketplace

No authentication required.

### `GET /categories`

List active categories.

**Response:**
```json
{
  "data": {
    "data": [
      { "id": 1, "name": "Electronics", "image": "https://...", "status": "active" }
    ],
    "pagination": { ... }
  }
}
```

---

### `GET /stores`

Paginated list of active stores.

**Query parameters:** `search`, `per_page`

---

### `GET /stores/{id}`

Single store detail including owner summary and recent products.

---

### `GET /products`

Browse active products with filtering, sorting, and pagination.

**Query parameters:**

| Parameter   | Type   | Description                                        |
|-------------|--------|----------------------------------------------------|
| `search`    | string | Keyword search (name + description)               |
| `category_id` | int  | Filter by category                                |
| `store_id`  | int    | Filter by store                                   |
| `price_min` | float  | Minimum price (inclusive)                         |
| `price_max` | float  | Maximum price (inclusive)                         |
| `sort`      | string | `newest` \| `oldest` \| `price_asc` \| `price_desc` |
| `per_page`  | int    | Items per page (1–100, default: 15)               |

**Response:**
```json
{
  "data": {
    "data": [
      {
        "id": 1,
        "name": "Product Name",
        "price": 49.99,
        "quantity": 20,
        "status": "active",
        "is_available": true,
        "image": "https://...",
        "images": [{ "id": 1, "url": "https://...", "sort_order": 0 }],
        "average_rating": 4.5,
        "review_count": 12,
        "category": { "id": 1, "name": "Electronics" },
        "store": { "id": 1, "store_name": "Jane's Store" }
      }
    ],
    "pagination": { ... }
  }
}
```

---

### `GET /products/{id}`

Single active product detail with full image gallery, category, store, rating stats.

---

### `GET /products/{productId}/reviews`

Paginated reviews for a product.

**Query parameters:** `per_page`

**Response:**
```json
{
  "data": {
    "data": [
      {
        "id": 1,
        "rating": 5,
        "comment": "Excellent product!",
        "reviewer": { "id": 2, "name": "John", "avatar": "https://..." },
        "created_at": "2026-07-23T10:00:00+00:00"
      }
    ],
    "pagination": { ... }
  }
}
```

---

## Client APIs

All require `auth:sanctum` + role `client`.

### Cart

#### `GET /cart` 🔐 (client)

Returns the client's cart with items and total.

**Response:**
```json
{
  "data": {
    "id": 1,
    "total": 149.97,
    "items": [
      {
        "id": 1,
        "product_id": 5,
        "product_name": "Widget",
        "unit_price": 49.99,
        "quantity": 3,
        "line_total": 149.97
      }
    ]
  }
}
```

#### `POST /cart/items` 🔐 (client)

Add a product to the cart.

**Body:** `{ "product_id": 5, "quantity": 2 }`

#### `PUT /cart/items/{id}` 🔐 (client)

Update quantity of a cart item.

**Body:** `{ "quantity": 4 }`

#### `DELETE /cart/items/{id}` 🔐 (client)

Remove an item from the cart.

---

### Orders

#### `POST /orders` 🔐 (client)

Checkout: converts cart into orders (one per store). Clears cart on success.

**Body:**
```json
{
  "customer_name": "John Doe",
  "customer_phone": "0501234567",
  "customer_city": "Riyadh",
  "notes": "Please ring doorbell."
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Order placed successfully.",
  "data": [
    {
      "id": 1,
      "status": "pending",
      "total_amount": 149.97,
      "customer_name": "John Doe",
      "store": { "id": 1, "store_name": "Jane's Store" },
      "items": [...],
      "created_at": "..."
    }
  ]
}
```

#### `GET /orders` 🔐 (client)

Order history with optional filters.

**Query parameters:** `status`, `date_from` (Y-m-d), `date_to` (Y-m-d), `per_page`

#### `GET /orders/{id}` 🔐 (client)

Order detail.

#### `DELETE /orders/{id}` 🔐 (client)

Cancel a **pending** order. Returns `422` if order is not in `pending` status.

---

### Order Statuses

| Status       | Description                              |
|--------------|------------------------------------------|
| `pending`    | Just placed, awaiting merchant action    |
| `confirmed`  | Merchant accepted the order              |
| `processing` | Order is being prepared/shipped          |
| `completed`  | Order delivered successfully             |
| `cancelled`  | Cancelled by client or merchant          |

---

### Favorites

#### `GET /favorites` 🔐 (client)

List the client's favorite products.

#### `POST /favorites/{product}` 🔐 (client)

Add product to favorites. Returns `201` (added) or `200` (already favorited).

#### `DELETE /favorites/{product}` 🔐 (client)

Remove product from favorites.

---

### Reviews

#### `POST /products/{productId}/reviews` 🔐 (client)

Submit a review for a product. One review per client per product.

**Body:**
```json
{
  "rating": 5,
  "comment": "Excellent quality!"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "rating": 5,
    "comment": "Excellent quality!",
    "reviewer": { "id": 2, "name": "John", "avatar": null },
    "created_at": "..."
  }
}
```

**Errors:**
- `422` — Already reviewed this product
- `404` — Product not found

#### `DELETE /reviews/{id}` 🔐 (client)

Delete own review. Returns `403` if not the owner.

---

## Merchant APIs

All require `auth:sanctum` + role `merchant`.

### Products

#### `GET /merchant/products` 🔐 (merchant)

List merchant's own products.

**Query parameters:** `search`, `category_id`, `status`, `sort_by`, `sort_dir`, `per_page`

#### `POST /merchant/products` 🔐 (merchant)

Create a product. Multipart upload for images.

**Body (multipart/form-data):**

| Field         | Type     | Required | Notes                              |
|---------------|----------|----------|------------------------------------|
| `store_id`    | int      | Yes      | Must belong to the merchant        |
| `category_id` | int      | No       |                                    |
| `name`        | string   | Yes      | max:255                            |
| `description` | string   | No       |                                    |
| `price`       | decimal  | Yes      | min:0                              |
| `quantity`    | int      | Yes      | min:0                              |
| `status`      | string   | No       | active \| inactive (default: active) |
| `images[]`    | file[]   | No       | Up to 10 images, max 2MB each      |

#### `GET /merchant/products/{id}` 🔐 (merchant)
#### `PUT /merchant/products/{id}` 🔐 (merchant)
#### `DELETE /merchant/products/{id}` 🔐 (merchant)

---

### Orders (Merchant)

#### `GET /merchant/orders` 🔐 (merchant)

Incoming orders for merchant's stores.

**Query parameters:** `status`, `date_from`, `date_to`, `per_page`

#### `GET /merchant/orders/{id}` 🔐 (merchant)

Order detail with items and client info.

#### `PUT /merchant/orders/{id}/status` 🔐 (merchant)

Update order status.

**Body:** `{ "status": "confirmed" }`

Allowed transitions: `confirmed`, `processing`, `completed`, `cancelled`

---

### Stores (Merchant)

#### `GET /merchant/stores` 🔐 (merchant)
#### `GET /merchant/stores/{id}` 🔐 (merchant)
#### `PUT /merchant/stores/{id}` 🔐 (merchant)

**Body (optional fields):**
```json
{
  "store_name": "New Name",
  "description": "Updated description"
}
```

#### `POST /merchant/stores/{id}/logo` 🔐 (merchant)

Multipart upload. Field: `logo` (image, max 2MB).

---

### Dashboard & Analytics (Merchant)

#### `GET /merchant/dashboard` 🔐 (merchant)

Returns:
- `products`: total, active, inactive, out_of_stock counts
- `orders`: counts by status
- `total_sales`: total revenue from completed orders
- `recent_orders`: last 10 orders
- `top_products`: best-selling products
- `low_inventory`: products with ≤5 units

#### `GET /merchant/analytics` 🔐 (merchant)

Returns monthly sales, top products, order trends for the merchant's stores.

---

### Dashboard (Client)

#### `GET /client/dashboard` 🔐 (client)

Returns lightweight counters for the authenticated client only.

**Response (200):**
```json
{
  "success": true,
  "message": "Client dashboard retrieved successfully.",
  "data": {
    "orders_count": 12,
    "favorites_count": 8
  }
}
```

---

### Subscription (Merchant)

#### `GET /merchant/subscription` 🔐 (merchant)

Current active subscription.

**Response:**
```json
{
  "data": {
    "id": 1,
    "plan": { "id": 2, "name": "pro", "display_name": "Pro Plan" },
    "billing_cycle": "monthly",
    "status": "active",
    "starts_at": "2026-07-01T00:00:00+00:00",
    "ends_at": "2026-08-01T00:00:00+00:00"
  }
}
```

#### `GET /merchant/subscription-requests` 🔐 (merchant)

All subscription requests submitted by this merchant.

#### `GET /merchant/subscription-requests/{id}` 🔐 (merchant)

Single request detail.

#### `POST /merchant/subscription-requests` 🔐 (merchant)

Submit a new subscription request with manual payment proof.

**Body (multipart/form-data):**

| Field                  | Type   | Required | Notes               |
|------------------------|--------|----------|---------------------|
| `plan_id`              | int    | Yes      |                     |
| `billing_cycle`        | string | Yes      | `monthly` \| `yearly` |
| `full_name`            | string | Yes      | max:150             |
| `phone`                | string | Yes      | max:20              |
| `payment_method`       | string | Yes      | e.g. "bank_transfer" |
| `payment_proof_image`  | file   | Yes      | JPEG/PNG/WebP max 4MB |
| `notes`                | string | No       | max:1000            |

**Response (201):** `SubscriptionRequestResource`

---

## Admin APIs

All require `auth:sanctum` + role `admin`.

### Dashboard & Analytics (Admin)

#### `GET /admin/dashboard` 🔐 (admin)

System-wide overview:
- Total users / clients / merchants / admins
- Store counts by status
- Product counts by status
- Order counts by status + total sales
- Newest users, stores, products; recent orders

#### `GET /admin/analytics` 🔐 (admin)

- Monthly sales (last 12 months)
- Order breakdown by status
- User & merchant growth (last 12 months)
- Product stats by category and status

---

### Categories (Admin)

#### `GET /admin/categories` 🔐 (admin)

**Query parameters:** `search`, `status`, `per_page`

#### `POST /admin/categories` 🔐 (admin)

**Body (multipart/form-data):**
```
name=Electronics   (required, max:100, unique)
image=<file>       (optional, image, max 2MB)
status=active      (optional: active | inactive)
```

#### `GET /admin/categories/{id}` 🔐 (admin)
#### `PUT /admin/categories/{id}` 🔐 (admin)
#### `DELETE /admin/categories/{id}` 🔐 (admin)

Returns `409 Conflict` if category has assigned products.

---

### Plans (Admin)

#### `GET /admin/plans` 🔐 (admin)

**Query parameters:** `search`, `status`, `per_page`

#### `POST /admin/plans` 🔐 (admin)

**Body:**
```json
{
  "name": "pro",
  "display_name": "Pro Plan",
  "monthly_price": 49.99,
  "yearly_price": 499.99,
  "product_limit": 100,
  "store_limit": 3,
  "ai_usage_limit": 500,
  "features": { "priority_support": true },
  "status": "active"
}
```

#### `GET /admin/plans/{id}` 🔐 (admin)
#### `PUT /admin/plans/{id}` 🔐 (admin)
#### `DELETE /admin/plans/{id}` 🔐 (admin)

---

### Users (Admin)

#### `GET /admin/users` 🔐 (admin)

**Query parameters:** `search` (name/email/phone), `role`, `status`, `per_page`

#### `GET /admin/users/{id}` 🔐 (admin)

#### `PUT /admin/users/{id}/status` 🔐 (admin)

**Body:** `{ "status": "active" }` — values: `active` | `inactive` | `banned`

#### `PUT /admin/users/{id}/role` 🔐 (admin)

**Body:** `{ "role": "merchant" }` — values: `client` | `merchant` | `admin`

---

### Stores (Admin)

#### `GET /admin/stores` 🔐 (admin)

**Query parameters:** `search`, `status`, `per_page`

#### `GET /admin/stores/{id}` 🔐 (admin)

Full store detail including owner and product count.

#### `PUT /admin/stores/{id}/status` 🔐 (admin)

**Body:** `{ "status": "suspended" }` — values: `active` | `inactive` | `suspended`

---

### Products (Admin — Read-Only)

#### `GET /admin/products` 🔐 (admin)

**Query parameters:** `search`, `category_id`, `status`, `per_page`

#### `GET /admin/products/{id}` 🔐 (admin)

---

### Reviews (Admin — Moderation)

#### `GET /admin/products/{productId}/reviews` 🔐 (admin)

List all reviews for any product (including inactive products).

**Query parameters:** `per_page`

#### `DELETE /admin/reviews/{id}` 🔐 (admin)

Delete any review (content moderation).

---

### Subscription Requests (Admin)

#### `GET /admin/subscription-requests` 🔐 (admin)

Paginated list of all subscription requests.

**Query parameters:** `status` (`pending` | `approved` | `rejected`), `per_page`

**Response:**
```json
{
  "data": {
    "data": [
      {
        "id": 1,
        "merchant": { "id": 5, "name": "Jane Merchant" },
        "plan": { "id": 2, "name": "pro", "display_name": "Pro Plan" },
        "billing_cycle": "monthly",
        "full_name": "Jane Merchant",
        "phone": "0509876543",
        "payment_method": "bank_transfer",
        "payment_proof_image": "https://...",
        "notes": null,
        "status": "pending",
        "rejection_reason": null,
        "reviewed_by": null,
        "reviewed_at": null,
        "created_at": "..."
      }
    ],
    "pagination": { ... }
  }
}
```

#### `GET /admin/subscription-requests/{id}` 🔐 (admin)

Single request detail.

#### `PUT /admin/subscription-requests/{id}/approve` 🔐 (admin)

Approve a pending request. Activates the merchant's subscription atomically.

**Response (200):** Updated `SubscriptionRequestResource`

**Errors:**
- `404` — Request not found
- `422` — Request was already reviewed

#### `PUT /admin/subscription-requests/{id}/reject` 🔐 (admin)

Reject a pending request.

**Body:** `{ "rejection_reason": "Payment proof unclear." }`

**Response (200):** Updated `SubscriptionRequestResource`

**Errors:**
- `404` — Request not found
- `422` — Request was already reviewed

---

## Storage & Images

All image URLs in responses are **absolute URLs** (e.g. `https://your-domain.com/storage/products/1/image.jpg`).

Upload endpoints accept: `jpeg`, `jpg`, `png`, `webp`.

Maximum sizes:
- Product images: 2MB each, up to 10 per product
- Store logos: 2MB
- Category images: 2MB
- Payment proof: 4MB
- Avatars: 2MB

Stored on the `public` disk, served via `storage/` symlink (`php artisan storage:link`).

---

## AI SaaS

All AI endpoints require authentication (`Authorization: Bearer <token>`).
Merchant tools require `role: merchant`. Admin analytics requires `role: admin`.
Rate limit: **20 requests / minute / user** (separate `throttle:ai` bucket).

### Error codes specific to AI endpoints

| Code | Meaning |
|---|---|
| 429 | Daily or monthly AI request limit exceeded — or AI disabled for account |
| 503 | External AI provider unavailable or `GEMINI_API_KEY` not configured |

---

### `POST /ai/product-description` 🔐 (merchant)

Generate a professional product description.

**Body:**
```json
{
  "context":  "Sony WH-1000XM5, noise-cancelling headphones, electronics",
  "language": "English"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✅ | Product name, category, key features. 5–500 chars. |
| `language` | string | — | Target language. Default: `English`. |

**Response (200):**
```json
{
  "success": true,
  "message": "Product description generated successfully.",
  "data": {
    "result":       "Experience sound like never before with the Sony WH-1000XM5...",
    "tokens_used":  210,
    "service_type": "product_description",
    "language":     "English"
  }
}
```

---

### `POST /ai/marketing-content` 🔐 (merchant)

Generate a marketing caption, hashtags, and promotional tagline.

**Body:**
```json
{
  "context":  "Summer sale, 50% off all clothing items this weekend",
  "language": "English"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✅ | Product/campaign details. 5–500 chars. |
| `language` | string | — | Target language. Default: `English`. |

**Response (200):**
```json
{
  "success": true,
  "message": "Marketing content generated successfully.",
  "data": {
    "result":       "Caption: Summer vibes are here! ☀️\nHashtags: #SummerSale #Fashion #50Off\nTagline: Shop the season — before it's gone.",
    "tokens_used":  180,
    "service_type": "marketing_content",
    "language":     "English"
  }
}
```

---

### `POST /ai/customer-reply` 🔐 (merchant)

Suggest a professional reply to a customer message.

**Body:**
```json
{
  "context":    "My order has not arrived after 7 days. Very disappointed.",
  "language":   "English",
  "store_name": "Tech Store"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✅ | The customer's message. 5–1000 chars. |
| `language` | string | — | Reply language. Default: `English`. |
| `store_name` | string | — | Store name for sign-off. Optional. |

**Response (200):**
```json
{
  "success": true,
  "message": "Customer reply generated successfully.",
  "data": {
    "result":       "Dear valued customer, we sincerely apologise for the delay...",
    "tokens_used":  140,
    "service_type": "customer_reply",
    "language":     "English"
  }
}
```

---

### `GET /ai/analytics` 🔐 (admin)

Generate AI-powered platform analytics insights from live data.

**Query parameters:**

| Param | Type | Default | Notes |
|---|---|---|---|
| `type` | string | `overview` | `overview` \| `products` \| `orders` \| `users` |
| `period_days` | int | `30` | Lookback window. 1–365. |
| `language` | string | `English` | Report language. |

**Example:** `GET /api/v1/ai/analytics?type=orders&period_days=7`

**Response (200):**
```json
{
  "success": true,
  "message": "Analytics insights generated successfully.",
  "data": {
    "result":       "Key Highlights:\n- Orders increased 18% vs prior week...\nRecommendations:\n- Focus on cart abandonment recovery...",
    "tokens_used":  420,
    "service_type": "analytics",
    "period_days":  7,
    "type":         "orders",
    "language":     "English"
  }
}
```

---

### `GET /ai/usage` 🔐 (any authenticated role)

Return the current user's AI request usage for today and this month.

**Response (200):**
```json
{
  "success": true,
  "message": "AI usage retrieved successfully.",
  "data": {
    "today":                    3,
    "this_month":               47,
    "credits_used_today":       3,
    "credits_used_this_month":  47,
    "daily_limit":              null,
    "monthly_limit":             100,
    "is_active":                 true
  }
}
```

Each successful AI generation consumes one credit by default. `null` limits mean unlimited;
`monthly_limit` falls back to the active subscription plan's `ai_usage_limit` when no
per-user override exists. `is_active: false` means AI is disabled for this account.
Completed requests are retained in the internal `ai_requests` history table with the
request context, response, token count, credit count, and status.

---

## Flutter Integration Notes

1. **Authentication:** Store the `token` from login/register response. Send as `Authorization: Bearer <token>` header on every protected request.
2. **Pagination:** Use `data.pagination.current_page`, `data.pagination.last_page`, and `data.pagination.per_page` to implement infinite scroll / pagination.
3. **Image URLs:** All image fields are already absolute URLs — use directly in `Image.network()`.
4. **Role checking:** The `data.user.role` field in login response tells you which navigation flow to show (`client`, `merchant`, `admin`).
5. **Error handling:** Check `success` field first. If `false`, show `message`. If `errors` key exists, map field-level errors to form fields.
6. **Order tracking:** Poll `GET /orders/{id}` or use the notification system to detect status changes.
