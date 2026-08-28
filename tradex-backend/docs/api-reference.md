# TradexAPI — API Reference

**Base URL:** `https://<your-domain>/api/v1`  
**Auth:** Bearer token via Laravel Sanctum — `Authorization: Bearer <token>`  
**Content-Type:** `application/json` (use `multipart/form-data` for file uploads)  
**API Version:** v1

---

## Standard Response Envelope

Every response — success or error — uses this structure:

```json
{
  "success": true,
  "message": "Human-readable description",
  "data":    { ... }
}
```

Error responses:

```json
{
  "success": false,
  "message": "What went wrong",
  "data":    null
}
```

Validation errors (422) also include:

```json
{
  "success": false,
  "message": "Validation failed.",
  "data":    null,
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

## Paginated Responses

List endpoints return data inside a pagination wrapper:

```json
{
  "success": true,
  "message": "...",
  "data": {
    "data": [ ... ],
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

## HTTP Status Codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 201 | Resource created |
| 400 | Bad request |
| 401 | Unauthenticated — token missing or invalid |
| 403 | Forbidden — wrong role, banned user, or ownership violation |
| 404 | Resource not found |
| 405 | Method not allowed |
| 422 | Validation failed or business rule violation |
| 429 | Rate limit exceeded |
| 500 | Internal server error |
| 503 | External service unavailable (AI provider) |

---

## Rate Limiting

| Limiter | Limit | Applies to |
|---|---|---|
| `auth` | 5 req/min per IP | Login, register, forgot password |
| `api` | 60 req/min per user (or IP) | All other API routes |

On 429, the response includes a `Retry-After` header with the seconds until the limit resets.

---

## Health Check

### `GET /health`

Public. Returns API status.

**Response 200:**
```json
{
  "success": true,
  "message": "OK",
  "data": { "status": "ok", "version": "v1", "app": "TradxAPI" }
}
```

---

## Authentication

### `POST /auth/register/client`

Register a client account. Rate limited: 5 req/min/IP.

**Body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | ✓ | Max 100 chars |
| `email` | string | ✓ | Must be unique |
| `phone` | string | ✓ | Max 20 chars |
| `password` | string | ✓ | Min 8 chars |
| `password_confirmation` | string | ✓ | Must match `password` |

**Response 201:**
```json
{
  "success": true,
  "message": "Client account created successfully.",
  "data": {
    "token": "1|abcdef...",
    "user": {
      "id": 1, "name": "Jane", "email": "jane@example.com",
      "phone": "+1234567890", "role": "client", "status": "active",
      "avatar": null, "email_verified_at": null,
      "created_at": "2026-07-27T10:00:00+00:00"
    }
  }
}
```

---

### `POST /auth/register/merchant`

Register a merchant account and store atomically. Rate limited: 5 req/min/IP.

**Body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | ✓ | User display name |
| `email` | string | ✓ | Must be unique |
| `phone` | string | ✓ | |
| `password` | string | ✓ | Min 8 chars |
| `password_confirmation` | string | ✓ | |
| `store_name` | string | ✓ | Max 255 chars |
| `store_description` | string | — | Optional |

**Response 201:** Same structure as client registration; `user.role` is `"merchant"` and `user.stores` array is included.

---

### `POST /auth/login`

Rate limited: 5 req/min/IP.

**Body:**
| Field | Type | Required |
|---|---|---|
| `email` | string | ✓ |
| `password` | string | ✓ |
| `device_name` | string | — |

**Response 200:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": { "token": "2|xyz...", "user": { ... } }
}
```

**Response 422:** Invalid credentials.

---

### `POST /auth/logout`

**Auth required.** Revokes the current token.

**Response 200:** `"data": null`

---

### `GET /auth/me`

**Auth required.** Returns the authenticated user. Merchant responses include `stores` array.

**Response 200:** `"data": { user object }`

---

### `POST /auth/password/forgot`

Rate limited: 5 req/min/IP. Sends a password reset email. Always returns 200 regardless of whether the email exists (to prevent email enumeration).

**Body:** `{ "email": "user@example.com" }`

**Response 200:** `"message": "If that email is registered, a reset link has been sent."`

---

### `POST /auth/password/reset`

Rate limited: 5 req/min/IP.

**Body:**
| Field | Type | Required |
|---|---|---|
| `email` | string | ✓ |
| `token` | string | ✓ | From the reset email |
| `password` | string | ✓ | Min 8 chars |
| `password_confirmation` | string | ✓ | |

**Response 200:** `"message": "Password has been reset successfully."`

---

### `POST /auth/email/resend`

**Auth required.** Resend the verification email.

**Response 200:** `"message": "Verification email sent."`  
**Response 422:** Already verified.

---

### `GET /auth/email/verify/{id}/{hash}`

Signed URL from the verification email. Verifies the user's email address.

**Response 200:** `"data": { "email_verified": true }`  
**Response 403:** Invalid or tampered link.

---

## Profile

### `GET /profile`

**Auth required.** Returns the current user's profile.

**Response 200:** `"data": { user object }`

---

### `PUT /profile`

**Auth required.** Update profile fields.

**Body:** `name`, `phone`, `email` (all optional)

**Response 200:** `"data": { updated user object }`

---

### `POST /profile/avatar`

**Auth required.** Upload a profile avatar. `multipart/form-data`.

**Body:** `avatar` — image file (jpeg, jpg, png, webp, max 2 MB)

**Response 200:** `"data": { user object with new avatar URL }`

---

## Notifications

### `GET /notifications`

**Auth required.** Paginated notification list (newest first).

**Query:** `?per_page=15&unread_only=1`

**Response 200:** Paginated list of notification objects.

---

### `PATCH /notifications/{id}/read`

**Auth required.** Mark one notification as read.

**Response 200:** `"data": { notification object }`

---

### `POST /notifications/read-all`

**Auth required.** Mark all notifications as read.

**Response 200:** `"data": null`

---

## Device Tokens

### `POST /device-tokens`

**Auth required.** Register a push notification token.

**Body:**
| Field | Type | Required |
|---|---|---|
| `token` | string | ✓ | FCM/APNS token |
| `platform` | string | ✓ | `android` or `ios` |

**Response 201:** `"data": { token object }`

---

### `DELETE /device-tokens/{token}`

**Auth required.** Unregister a push notification token.

**Response 200:** `"data": null`

---

## Public Marketplace

### `GET /products`

Public. Browse active products.

**Query parameters:**
| Param | Type | Description |
|---|---|---|
| `search` | string | Keyword search on name/description |
| `category_id` | int | Filter by category |
| `min_price` | number | Minimum price filter |
| `max_price` | number | Maximum price filter |
| `per_page` | int | Results per page (default 15, max 100) |

**Response 200:** Paginated list of product objects.

---

### `GET /products/{id}`

Public. Single product detail.

**Response 200:**
```json
{
  "data": {
    "id": 1, "name": "Product Name", "description": "...",
    "price": 29.99, "quantity": 10, "status": "active",
    "image": "https://...", "total_sold": 42,
    "average_rating": 4.5, "review_count": 12,
    "category": { "id": 2, "name": "Electronics" },
    "store": { "id": 1, "store_name": "Tech Shop" },
    "images": [ { "id": 1, "url": "https://...", "sort_order": 1 } ]
  }
}
```

**Response 404:** Product not found or inactive.

---

### `GET /stores`

Public. Browse active stores.

**Query:** `?per_page=15`

**Response 200:** Paginated list of store objects.

---

### `GET /stores/{id}`

Public. Single store detail with its active products.

**Response 200:** Store object with nested `products` array.

---

### `GET /categories`

Public. List active categories.

**Response 200:** Paginated list of category objects.

---

### `GET /categories/{id}`

Public. Single category.

**Response 200:** Category object.

---

### `GET /products/{productId}/reviews`

Public. Product reviews.

**Query:** `?per_page=15`

**Response 200:** Paginated list of review objects.

---

## Cart (Client only)

### `GET /cart`

**Auth required. Role: `client`.** Returns the client's cart.

**Response 200:**
```json
{
  "data": {
    "id": 1, "item_count": 3, "subtotal": 89.97,
    "items": [
      {
        "id": 1, "quantity": 2, "unit_price": 29.99, "line_total": 59.98,
        "product": { "id": 5, "name": "...", "status": "active", "image": "https://...",
                     "store": { "id": 1, "store_name": "Tech Shop" } }
      }
    ]
  }
}
```

---

### `POST /cart/items`

**Auth required. Role: `client`.** Add a product to the cart.

**Body:**
| Field | Type | Required |
|---|---|---|
| `product_id` | int | ✓ |
| `quantity` | int | ✓ | Min 1 |

**Response 201:** Updated cart object.  
**Response 422:** Product not found, out of stock, or insufficient quantity.

---

### `PUT /cart/items/{id}`

**Auth required. Role: `client`.** Update item quantity.

**Body:** `{ "quantity": 3 }`

**Response 200:** Updated cart object.

---

### `DELETE /cart/items/{id}`

**Auth required. Role: `client`.** Remove an item from the cart.

**Response 200:** Updated cart object.

---

## Orders (Client)

### `POST /orders`

**Auth required. Role: `client`.** Checkout — converts cart to orders (one per store).

**Body:**
| Field | Type | Required |
|---|---|---|
| `customer_name` | string | ✓ | |
| `customer_phone` | string | ✓ | |
| `customer_address` | string | ✓ | |

**Response 201:** Array of created order objects.  
**Response 422:** Cart is empty, or a product is out of stock.

---

### `GET /orders`

**Auth required. Role: `client`.** Paginated order history.

**Query:** `?status=pending&date_from=2026-01-01&date_to=2026-12-31&per_page=15`

**Response 200:** Paginated list of order objects.

---

### `GET /orders/{id}`

**Auth required. Role: `client`.** Order detail.

**Response 200:** Order object with items.  
**Response 404:** Not found or does not belong to this client.

---

### `DELETE /orders/{id}`

**Auth required. Role: `client`.** Cancel a pending order.

**Response 200:** Cancelled order object.  
**Response 422:** Order is not in `pending` status.  
**Response 404:** Not found.

---

## Favorites (Client)

### `GET /favorites`

**Auth required. Role: `client`.** Paginated favorites list.

**Response 200:** Paginated list of product objects.

---

### `POST /favorites`

**Auth required. Role: `client`.** Add a product to favorites.

**Body:** `{ "product_id": 5 }`

**Response 201:** Favorite object.  
**Response 422:** Already favorited.

---

### `DELETE /favorites/{id}`

**Auth required. Role: `client`.** Remove from favorites.

**Response 200:** `"data": null`

---

## Reviews (Client)

### `POST /products/{productId}/reviews`

**Auth required. Role: `client`.** Submit a review.

**Body:**
| Field | Type | Required |
|---|---|---|
| `rating` | int | ✓ | 1–5 |
| `comment` | string | — | |

**Response 201:** Review object.  
**Response 422:** Already reviewed this product.

---

### `DELETE /reviews/{id}`

**Auth required. Role: `client`.** Delete own review.

**Response 200:** `"data": null`  
**Response 403:** Not the review owner.

---

## Merchant — Store

### `GET /merchant/store`

**Auth required. Role: `merchant`.** Get the merchant's store.

**Response 200:** Store object.

---

### `PUT /merchant/store`

**Auth required. Role: `merchant`.** Update store details.

**Body:** `store_name`, `description` (all optional)

**Response 200:** Updated store object.

---

### `POST /merchant/store/logo`

**Auth required. Role: `merchant`.** Upload store logo. `multipart/form-data`.

**Body:** `logo` — image file (jpeg, jpg, png, webp, max 2 MB)

**Response 200:** Updated store object.

---

## Merchant — Products

### `GET /merchant/products`

**Auth required. Role: `merchant`.** Paginated list of own products.

**Query:** `?status=active&per_page=15`

**Response 200:** Paginated product list.

---

### `POST /merchant/products`

**Auth required. Role: `merchant`.** Create a product. `multipart/form-data` (if uploading an image).

**Body:**
| Field | Type | Required |
|---|---|---|
| `name` | string | ✓ | |
| `description` | string | — | |
| `price` | number | ✓ | |
| `quantity` | int | ✓ | |
| `category_id` | int | — | |
| `image` | file | — | jpeg/png/webp, max 2 MB |
| `status` | string | — | `active`, `inactive` |

**Response 201:** Product object.

---

### `GET /merchant/products/{id}`

**Auth required. Role: `merchant`.** Own product detail.

**Response 200:** Product object.  
**Response 403:** Product belongs to another merchant.

---

### `PUT /merchant/products/{id}`

**Auth required. Role: `merchant`.** Update a product.

**Body:** Same fields as create (all optional).

**Response 200:** Updated product object.

---

### `DELETE /merchant/products/{id}`

**Auth required. Role: `merchant`.** Delete a product.

**Response 200:** `"data": null`

---

## Merchant — Orders

### `GET /merchant/orders`

**Auth required. Role: `merchant`.** Paginated incoming orders.

**Query:** `?status=pending&date_from=2026-01-01&per_page=15`

**Response 200:** Paginated order list.

---

### `GET /merchant/orders/{id}`

**Auth required. Role: `merchant`.** Order detail.

**Response 200:** Order object with items.

---

### `PUT /merchant/orders/{id}/status`

**Auth required. Role: `merchant`.** Advance order status.

**Body:** `{ "status": "confirmed" }`  
Valid transitions: `pending → confirmed → processing → completed`

**Response 200:** Updated order object.  
**Response 422:** Invalid status transition.

---

## Merchant — Dashboard

### `GET /merchant/dashboard`

**Auth required. Role: `merchant`.** Summary stats for the merchant's store.

**Response 200:** Sales totals, order counts by status, recent orders.

---

### `GET /merchant/analytics`

**Auth required. Role: `merchant`.** Extended analytics (monthly sales chart, etc.).

**Response 200:** Analytics data object.

---

## Merchant — Subscriptions

### `POST /merchant/subscription-requests`

**Auth required. Role: `merchant`.** Submit a subscription plan request with payment proof. `multipart/form-data`.

**Body:**
| Field | Type | Required |
|---|---|---|
| `plan_id` | int | ✓ | |
| `billing_cycle` | string | ✓ | `monthly` or `yearly` |
| `full_name` | string | ✓ | |
| `phone` | string | ✓ | |
| `payment_method` | string | ✓ | e.g. "bank transfer" |
| `payment_proof_image` | file | ✓ | jpeg/png/webp, max 4 MB |
| `notes` | string | — | |

**Response 201:** Subscription request object.

---

### `GET /merchant/subscription-requests`

**Auth required. Role: `merchant`.** Own subscription requests.

**Response 200:** List of subscription request objects.

---

## AI Endpoints (Merchant)

All AI endpoints require `role: merchant`. Usage is tracked per user per day/month. Returns 429 if the limit is exceeded and 503 if the Gemini provider is unavailable.

### `POST /ai/product-description`

Generate a product description.

**Body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✓ | 5–500 chars — product name, category, features |
| `language` | string | — | Target language (default: English) |

**Response 200:**
```json
{
  "data": {
    "result": "Premium wireless headphones...",
    "tokens_used": 120,
    "service_type": "product_description",
    "language": "English"
  }
}
```

---

### `POST /ai/marketing-content`

Generate a marketing campaign post.

**Body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✓ | 5–500 chars — product/campaign details |
| `language` | string | — | |
| `purpose` | string | — | `instagram` or `hashtags` (default: `instagram`) |

**Response 200:** Same structure as product-description; `service_type` is `"marketing_content"`.

---

### `POST /ai/customer-reply`

Generate a suggested reply to a customer message.

**Body:**
| Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | ✓ | 5–1000 chars — the customer's message |
| `store_name` | string | — | Personalises the reply |
| `language` | string | — | |

**Response 200:** Same structure; `service_type` is `"customer_reply"`.

---

## AI Usage (All authenticated users)

### `GET /ai/usage`

**Auth required.** Returns the user's AI usage stats.

**Response 200:**
```json
{
  "data": {
    "today": {
      "product_description": { "requests": 3, "credits": 3 },
      "marketing_content":   { "requests": 1, "credits": 1 },
      "customer_reply":      { "requests": 0, "credits": 0 }
    },
    "this_month": {
      "product_description": { "requests": 45, "credits": 45 },
      ...
    },
    "limits": {
      "daily_limit": 10,
      "monthly_limit": 100,
      "is_enabled": true
    }
  }
}
```

---

## AI Analytics (Admin)

### `GET /ai/analytics`

**Auth required. Role: `admin`.** Generate AI-powered platform analytics insights.

**Query parameters:**
| Param | Type | Notes |
|---|---|---|
| `type` | string | `overview` \| `products` \| `orders` \| `users` (default: `overview`) |
| `period_days` | int | Days to analyse — 1–365 (default: 30) |
| `language` | string | Language for AI response (default: English) |

**Response 200:**
```json
{
  "data": {
    "result": "AI-generated analytics summary...",
    "tokens_used": 250,
    "service_type": "analytics",
    "type": "overview"
  }
}
```

---

## Admin — Users

### `GET /admin/users`

**Auth required. Role: `admin`.** Paginated user list.

**Query:** `?role=merchant&status=active&per_page=15`

**Response 200:** Paginated user list.

---

### `GET /admin/users/{id}`

**Auth required. Role: `admin`.** User detail.

**Response 200:** User object.

---

### `PUT /admin/users/{id}/status`

**Auth required. Role: `admin`.** Change user status.

**Body:** `{ "status": "banned" }` — values: `active`, `banned`, `inactive`

**Response 200:** Updated user object.

---

### `PUT /admin/users/{id}/role`

**Auth required. Role: `admin`.** Change user role.

**Body:** `{ "role": "merchant" }` — values: `client`, `merchant`, `admin`

**Response 200:** Updated user object.

---

### `DELETE /admin/users/{id}`

**Auth required. Role: `admin`.** Permanently delete a user and all their data.

**Response 200:** `"data": null`

---

## Admin — Stores

### `GET /admin/stores`

**Auth required. Role: `admin`.** Paginated store list.

**Query:** `?status=active&per_page=15`

**Response 200:** Paginated store list.

---

### `GET /admin/stores/{id}`

**Auth required. Role: `admin`.** Store detail.

**Response 200:** Store object with owner info.

---

### `PUT /admin/stores/{id}/status`

**Auth required. Role: `admin`.** Change store status.

**Body:** `{ "status": "suspended" }` — values: `active`, `inactive`, `suspended`

**Response 200:** Updated store object.

---

## Admin — Categories

### `GET /admin/categories`

**Auth required. Role: `admin`.** All categories (including inactive).

**Response 200:** Paginated category list with `products_count`.

---

### `POST /admin/categories`

**Auth required. Role: `admin`.** Create a category. `multipart/form-data`.

**Body:**
| Field | Type | Required |
|---|---|---|
| `name` | string | ✓ |
| `image` | file | — | jpeg/png/webp, max 2 MB |
| `status` | string | — | `active` or `inactive` |

**Response 201:** Category object.

---

### `PUT /admin/categories/{id}`

**Auth required. Role: `admin`.** Update a category.

**Response 200:** Updated category object.

---

### `DELETE /admin/categories/{id}`

**Auth required. Role: `admin`.** Delete a category. Fails with 422 if products are assigned to it.

**Response 200:** `"data": null`  
**Response 422:** Category has associated products.

---

## Admin — Plans

### `GET /admin/plans`

**Auth required. Role: `admin`.** All plans.

**Response 200:** List of plan objects.

---

### `POST /admin/plans`

**Auth required. Role: `admin`.** Create a subscription plan.

**Body:**
| Field | Type | Required |
|---|---|---|
| `name` | string | ✓ |
| `price` | number | ✓ |
| `duration_months` | int | ✓ |
| `ai_credits_per_month` | int | ✓ |
| `description` | string | — |
| `is_active` | boolean | — |

**Response 201:** Plan object.

---

### `PUT /admin/plans/{id}`

**Auth required. Role: `admin`.** Update a plan.

**Response 200:** Updated plan object.

---

### `DELETE /admin/plans/{id}`

**Auth required. Role: `admin`.** Delete a plan.

**Response 200:** `"data": null`

---

## Admin — Subscription Requests

### `GET /admin/subscription-requests`

**Auth required. Role: `admin`.** Paginated subscription requests.

**Query:** `?status=pending&per_page=15`

**Response 200:** Paginated list of subscription request objects.

---

### `GET /admin/subscription-requests/{id}`

**Auth required. Role: `admin`.** Request detail with payment proof image URL.

**Response 200:** Subscription request object.

---

### `PUT /admin/subscription-requests/{id}/approve`

**Auth required. Role: `admin`.** Approve request — creates an active `Subscription` and updates the merchant's `ai_settings`.

**Response 200:** Updated subscription request object.

---

### `PUT /admin/subscription-requests/{id}/reject`

**Auth required. Role: `admin`.** Reject request.

**Body:** `{ "notes": "Payment amount doesn't match plan price." }` (optional)

**Response 200:** Updated subscription request object.

---

## Admin — Reviews

### `GET /admin/products/{productId}/reviews`

**Auth required. Role: `admin`.** All reviews for a product.

**Response 200:** Paginated review list.

---

### `DELETE /admin/reviews/{id}`

**Auth required. Role: `admin`.** Delete any review.

**Response 200:** `"data": null`

---

## Admin — Dashboard & Analytics

### `GET /admin/dashboard`

**Auth required. Role: `admin`.** Platform summary: total users, merchants, products, orders, revenue.

**Response 200:** Dashboard data object.

---

### `GET /admin/analytics`

**Auth required. Role: `admin`.** Extended analytics: user growth, revenue trends, product statistics.

**Response 200:** Analytics data object.

---

## Admin — Products (Read-only)

### `GET /admin/products`

**Auth required. Role: `admin`.** List all products across all stores.

**Query parameters:**
| Param | Type | Description |
|---|---|---|
| `search` | string | Keyword search |
| `category_id` | int | Filter by category |
| `status` | string | `active` \| `inactive` \| `out_of_stock` |
| `sort_by` | string | `name` \| `price` \| `quantity` \| `created_at` \| `status` |
| `sort_dir` | string | `asc` \| `desc` |
| `per_page` | int | 1–100 (default: 15) |

**Response 200:** Paginated product list.

---

### `GET /admin/products/{id}`

**Auth required. Role: `admin`.** View any product regardless of status.

**Response 200:** Full product object.
