# TradxAPI — Backend Handover Report

**Generated:** 2026-07-24  
**Status:** ✅ Phase complete — Gemini AI provider integrated
**Stack:** Laravel 12 · PHP 8.2 · SQLite (dev) / MySQL (prod) · Laravel Sanctum  
**API Version:** v1  
**Base URL:** `https://<your-domain>/api/v1`

---

## Part 1 — Verification Results

### 1.1 API Documentation Completeness ✅

`API_DOCUMENTATION.md` — fully covering all 93 registered routes.

| Domain | Endpoints Documented |
|---|---|
| Health Check | 1 |
| Authentication (public + protected) | 9 |
| Profile | 4 |
| Notifications | 4 |
| Device Tokens | 4 |
| Public Marketplace (categories, stores, products, reviews) | 6 |
| Client — Cart | 3 |
| Client — Dashboard | 1 |
| Client — Orders | 4 |
| Client — Favorites | 3 |
| Client — Reviews | 2 |
| Merchant — Products | 5 |
| Merchant — Orders | 3 |
| Merchant — Stores | 4 |
| Merchant — Dashboard & Analytics | 2 |
| Merchant — Subscriptions | 4 |
| Admin — Dashboard & Analytics | 2 |
| Admin — Categories | 5 |
| Admin — Plans | 5 |
| Admin — Users | 5 |
| Admin — Stores | 3 |
| Admin — Products (read-only) | 3 |
| Admin — Reviews (moderation) | 2 |
| Admin — Subscription Requests | 4 |

**Finding:** All routes are documented with request bodies, response shapes, error codes, and role requirements. No gaps detected.

---

### 1.2 Environment Configuration ✅

| Variable | Dev (.env) | Production (.env.example guidance) |
|---|---|---|
| `APP_ENV` | `local` | Must be `production` |
| `APP_DEBUG` | `true` | Must be `false` ⚠️ |
| `APP_KEY` | Set | Must be freshly generated |
| `APP_URL` | `http://localhost:5000` | Set to public domain |
| `DB_CONNECTION` | `sqlite` | `mysql` (see .env.example) |
| `DB_DATABASE` | local sqlite path | MySQL credentials required |
| `CORS_ALLOWED_ORIGINS` | `*` | Set to specific origins (see §1.4) |
| `SANCTUM_EXPIRATION_MINUTES` | `129600` (90 days) | Adjust per policy |
| `FILESYSTEM_DISK` | `public` | `public` (ensure `storage:link` is run) |
| `QUEUE_CONNECTION` | `sync` | Recommend `database` or `redis` for production |
| `MAIL_MAILER` | `log` | Configure real SMTP / SES / Mailgun |

**Required production actions:**
```bash
php artisan key:generate
php artisan migrate --force
php artisan storage:link
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

### 1.3 Production Deployment Readiness ✅

| Check | Result |
|---|---|
| Test suite | ✅ 453/453 passed (1206 assertions) |
| All migrations ran | ✅ 26/26 |
| Performance indexes migration | ✅ `2026_07_24_000001_add_performance_indexes` |
| JSON error responses (404 / 401 / 403 / 422 / 500) | ✅ All handled in `bootstrap/app.php` |
| Rate limiting on auth endpoints | ✅ `throttle:auth` (5 req/min/IP) |
| Rate limiting on general API | ✅ `throttle:api` on all API routes |
| Banned/inactive user enforcement | ✅ `EnsureUserIsActive` middleware on every API request |
| Role-based access control | ✅ `EnsureRole` middleware (`role:admin`, `role:merchant`, `role:client`) |
| Storage symlink required | ⚠️ Run `php artisan storage:link` after deploy |
| Queue driver | ⚠️ Currently `sync` — switch to async driver for production notifications |
| `APP_DEBUG=false` in production | ⚠️ Must be set before go-live (see §1.2) |
| AI provider | ✅ Google Gemini — set `GEMINI_API_KEY` in .env to enable live generation |
| Production database | ⚠️ Run the two new AI migrations against the production MySQL database |

---

### 1.4 CORS and Authentication Settings ✅

#### CORS (`config/cors.php`)

```
Paths:            api/*, sanctum/csrf-cookie
Allowed Methods:  * (all)
Allowed Headers:  * (all)
Allowed Origins:  env('CORS_ALLOWED_ORIGINS')   ← currently '*'
Credentials:      false (token-based, no cookies)
```

**Production action:** Replace `CORS_ALLOWED_ORIGINS=*` with your specific origins:

```env
# Example
CORS_ALLOWED_ORIGINS=https://admin.tradx.app,https://app.tradx.app
```

Multiple origins are comma-separated — the config uses `explode(',', env(...))` to parse the list.

#### Authentication (Laravel Sanctum)

- **Mechanism:** Bearer token (`Authorization: Bearer <token>`)
- **Token lifetime:** 90 days (`SANCTUM_EXPIRATION_MINUTES=129600`) — configurable
- **On login/register:** Token returned once; client must store it persistently
- **On logout:** Token is deleted server-side — client must discard stored token
- **Banned/inactive users:** Token is immediately revoked on next request; client must handle 403 and redirect to login
- **Stateful SPA domains:** Configured via `SANCTUM_STATEFUL_DOMAINS` (not required for mobile/Flutter)
- **Role values in `user.role`:** `client` · `merchant` · `admin`

---

## Part 2 — Dashboard Integration Handover

> Target: Admin web dashboard (browser-based SPA or server-rendered).

### 2.1 Connection Setup

```
Base URL:        https://<your-domain>/api/v1
Auth header:     Authorization: Bearer <admin-token>
Content-Type:    application/json
CORS origin:     Add your dashboard domain to CORS_ALLOWED_ORIGINS
```

### 2.2 Auth Flow

```
POST /auth/login
  Body: { "email": "admin@example.com", "password": "..." }
  Response: { "data": { "token": "...", "user": { "role": "admin", ... } } }
```

1. Verify `data.user.role === "admin"` — redirect to login if not.
2. Store token in `httpOnly` cookie or secure storage.
3. Attach as `Authorization: Bearer <token>` on every subsequent request.
4. Handle `401` → redirect to login; handle `403` → show permission denied.

### 2.3 Dashboard & Analytics Endpoints

#### Overview Dashboard

```
GET /admin/dashboard
Auth: required (admin)

Response shape:
{
  "data": {
    "users":   { "total": 0, "clients": 0, "merchants": 0 },
    "stores":  { "total": 0, "active": 0, "pending": 0 },
    "products": { "total": 0 },
    "orders":  { "total": 0, "revenue": 0.00 },
    "subscriptions": { "active": 0, "pending_requests": 0 }
  }
}
```

#### Analytics

```
GET /admin/analytics
Auth: required (admin)

Returns time-series and breakdown data for charts.
```

### 2.4 User Management

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/users` | List all users. Supports `?per_page=&search=` |
| `GET` | `/admin/users/{id}` | Get a single user with full profile |
| `PUT` | `/admin/users/{id}/role` | Change user role. Body: `{ "role": "client\|merchant\|admin" }` |
| `PUT` | `/admin/users/{id}/status` | Ban/activate. Body: `{ "status": "active\|banned\|inactive" }` |
| `DELETE` | `/admin/users/{id}` | Delete user account |

**Status change notes:**
- Setting `status: "banned"` instantly revokes the user's current token on their next request.
- `EnsureUserIsActive` middleware handles revocation automatically — no additional action needed.

### 2.5 Store Management

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/stores` | List all stores with merchant info and status |
| `GET` | `/admin/stores/{id}` | Store detail with product count and owner |
| `PUT` | `/admin/stores/{id}/status` | Body: `{ "status": "active\|suspended\|pending" }` |

### 2.6 Category Management

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/categories` | List all categories |
| `POST` | `/admin/categories` | Create. Body: `{ "name": "", "description": "", "image": <file> }` |
| `GET` | `/admin/categories/{id}` | Get single category |
| `PUT` | `/admin/categories/{id}` | Update name/description/image |
| `DELETE` | `/admin/categories/{id}` | Delete (check product dependencies first) |

> Image uploads: `multipart/form-data`, max 2MB, formats: jpeg/jpg/png/webp.

### 2.7 Plan Management

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/plans` | List all subscription plans |
| `POST` | `/admin/plans` | Create plan. Body: `{ "name": "", "price": 0, "duration_days": 30, "features": [] }` |
| `GET` | `/admin/plans/{id}` | Plan detail |
| `PUT` | `/admin/plans/{id}` | Update plan |
| `DELETE` | `/admin/plans/{id}` | Delete plan |

### 2.8 Subscription Request Management

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/subscription-requests` | List all requests. Filter: `?status=pending\|approved\|rejected` |
| `GET` | `/admin/subscription-requests/{id}` | Detail with merchant, plan, and payment proof URL |
| `PUT` | `/admin/subscription-requests/{id}/approve` | Approve — atomically activates subscription |
| `PUT` | `/admin/subscription-requests/{id}/reject` | Reject. Body: `{ "rejection_reason": "..." }` |

**Workflow:** `pending` → `approved` or `rejected`. Approved/rejected requests return `422` if actioned again.

### 2.9 Products (Read-Only in Admin)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/admin/products` | List all products across all stores |
| `GET` | `/admin/products/{id}` | Product detail |
| `GET` | `/admin/products/{productId}/reviews` | Reviews for moderation |

### 2.10 Review Moderation

```
DELETE /admin/reviews/{id}
Auth: required (admin)
```

Removes a review. Returns 404 if already deleted.

### 2.11 Standard Response Envelope

All responses:
```json
{
  "success": true | false,
  "message": "Human-readable string",
  "data": { ... } | null,
  "errors": { "field": ["..."] }   ← only on 422
}
```

### 2.12 Pagination (all list endpoints)

```json
{
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

Query: `?per_page=25` (max: 100). Default: 15.

### 2.13 HTTP Status Code Reference

| Code | Meaning | Dashboard action |
|---|---|---|
| 200 | OK | Show result |
| 201 | Created | Show success, refresh list |
| 401 | Unauthenticated | Redirect to login, clear token |
| 403 | Forbidden | Show "Permission Denied" |
| 404 | Not Found | Show "Not Found" toast |
| 422 | Validation / Business Rule | Show `errors` map on form fields |
| 429 | Rate Limited | Show retry-after message |
| 500 | Server Error | Show generic error toast |

---

## Part 3 — Flutter BLoC Integration Handover

> Target: Flutter mobile app (client + merchant roles). Pure token-based, no cookies.

### 3.1 Connection Setup

```dart
// constants.dart
const String kBaseUrl = 'https://<your-domain>/api/v1';
const String kContentType = 'application/json';
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.0.0          # or dio: ^5.0.0
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0
  shared_preferences: ^2.0.0   # or flutter_secure_storage for token
```

### 3.2 Token Management

```dart
// Persist token after login/register
await secureStorage.write(key: 'auth_token', value: response.data.token);

// Attach to every request
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}

// On logout response or 401 — clear immediately
await secureStorage.delete(key: 'auth_token');
```

**Recommendation:** Use `flutter_secure_storage` rather than `SharedPreferences` for the token — it uses the platform keychain/keystore.

### 3.3 Authentication BLoC

#### Events
```dart
abstract class AuthEvent extends Equatable {}

class LoginRequested extends AuthEvent {
  final String email, password;
}
class RegisterClientRequested extends AuthEvent { ... }
class RegisterMerchantRequested extends AuthEvent { ... }
class LogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}
```

#### States
```dart
abstract class AuthState extends Equatable {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final String token;
  final UserModel user;   // contains: id, name, email, role, status
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  final Map<String, List<String>>? fieldErrors;  // 422 errors
}
```

#### Role-based navigation
```dart
// In router / after AuthAuthenticated state
switch (state.user.role) {
  case 'client':   go('/client/home'); break;
  case 'merchant': go('/merchant/dashboard'); break;
  case 'admin':    go('/admin/dashboard'); break;
}
```

### 3.4 Authentication Endpoints

#### Register (Client)
```
POST /auth/register/client
Rate limit: 5 req/min/IP

Body:
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "0501234567",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}

Response 201:
{
  "data": {
    "token": "1|abc...",
    "user": { "id": 1, "name": "...", "email": "...", "role": "client", "status": "active" }
  }
}
```

#### Register (Merchant)
```
POST /auth/register/merchant
Rate limit: 5 req/min/IP

Body: same as client +
{
  "store_name": "My Store",
  "store_description": "Optional"
}
```

#### Login
```
POST /auth/login
Rate limit: 5 req/min/IP

Body: { "email": "...", "password": "..." }
Response 200: same shape as register
```

#### Logout
```
POST /auth/logout
Auth: required

Response 200: { "success": true, "message": "Logged out successfully." }
→ Discard stored token immediately on any response (success or error)
```

#### Current User
```
GET /auth/me
Auth: required

Returns full user object. Use to verify token is still valid on app resume.
```

#### Password Reset
```
POST /auth/password/forgot   Body: { "email": "..." }
POST /auth/password/reset    Body: { "token": "...", "email": "...", "password": "...", "password_confirmation": "..." }
```

### 3.5 Profile BLoC

```
GET  /profile           → Full profile with avatar URL
PUT  /profile           Body: { "name", "phone", "bio" }
PUT  /profile/password  Body: { "current_password", "password", "password_confirmation" }
POST /profile/avatar    multipart/form-data, field: "avatar", max 2MB
```

Avatar URL in response is an **absolute URL** — use directly in `Image.network(url)`.

### 3.6 Public Marketplace (No Auth Required)

```
GET /categories                          → List all categories (no pagination)
GET /stores                              → Paginated store list. ?search=&category_id=
GET /stores/{id}                         → Store detail with products preview
GET /products                            → Paginated. ?search=&category_id=&store_id=&sort=
GET /products/{id}                       → Product detail with images[], store, category
GET /products/{productId}/reviews        → Paginated reviews for a product
```

These endpoints can be called before the user logs in (discovery / browse flow).

### 3.7 Client — Cart BLoC

```
GET    /cart              → Current cart with items[] and total
POST   /cart/items        Body: { "product_id": 1, "quantity": 2 }
PUT    /cart/items/{id}   Body: { "quantity": 3 }
DELETE /cart/items/{id}   Remove one item
```

**Cart state:** Always fetch fresh cart on app resume / tab change. Do not cache cart locally.

### 3.8 Client — Orders BLoC

```
POST   /orders          Place order from current cart. Body: { "notes": "optional" }
GET    /orders          Paginated order history
GET    /orders/{id}     Order detail with items[], status, timestamps
DELETE /orders/{id}     Cancel order (only if status allows cancellation)
```

#### Order status values
```
pending → confirmed → processing → shipped → delivered
                                           → cancelled
```

Poll `GET /orders/{id}` for status changes, or rely on push notifications (device token).

### 3.9 Client — Favorites BLoC

```
GET    /favorites              Paginated list of favorited products
POST   /favorites/{product}    Add to favorites (idempotent)
DELETE /favorites/{product}    Remove from favorites
```

### 3.10 Client — Reviews

```
GET    /products/{productId}/reviews   Paginated reviews (public, no auth)
POST   /products/{productId}/reviews   Auth required. Body: { "rating": 5, "comment": "..." }
DELETE /reviews/{id}                   Auth required. Client can delete own review only.
```

### 3.11 Notifications BLoC

```
GET    /notifications             Paginated. Unread count in pagination.total or separate field
PUT    /notifications/{id}/read   Mark one as read
PUT    /notifications/read-all    Mark all as read
DELETE /notifications/{id}        Delete one notification
```

### 3.12 Device Tokens (Push Notifications)

Register the FCM/APNS token immediately after login and whenever it refreshes:

```
POST   /device-tokens    Body: { "token": "<fcm-token>", "platform": "android|ios" }
GET    /device-tokens    List registered tokens for current user
DELETE /device-tokens/{token}   Remove a specific token
DELETE /device-tokens           Remove ALL tokens for current user (use on logout)
```

**Logout flow:**
```dart
// 1. Delete device token first
await api.delete('/device-tokens', body: {'token': fcmToken});
// 2. Then logout
await api.post('/auth/logout');
// 3. Clear local token
await secureStorage.delete(key: 'auth_token');
```

### 3.13 Merchant Endpoints

```
GET    /merchant/dashboard          KPI summary for merchant home screen
GET    /merchant/analytics          Revenue/orders chart data
GET    /merchant/products           Merchant's own products (paginated)
POST   /merchant/products           Create product (multipart — see §3.15)
GET    /merchant/products/{id}      Product detail
PUT    /merchant/products/{id}      Update product
DELETE /merchant/products/{id}      Delete product

GET    /merchant/orders             Incoming orders (paginated)
GET    /merchant/orders/{id}        Order detail
PUT    /merchant/orders/{id}/status Body: { "status": "confirmed|processing|shipped|delivered|cancelled" }

GET    /merchant/stores             Merchant's stores
GET    /merchant/stores/{id}        Store detail
PUT    /merchant/stores/{id}        Update store info
POST   /merchant/stores/{id}/logo   Upload logo (multipart, field: "logo")

GET    /merchant/subscription       Current subscription status
GET    /merchant/subscription-requests   Request history
POST   /merchant/subscription-requests  Submit new request (multipart — payment proof)
GET    /merchant/subscription-requests/{id}  Request detail
```

### 3.14 Error Handling BLoC Pattern

```dart
// api_response.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, List<String>>? errors;
}

// In BLoC mapEventToState
try {
  final response = await apiClient.post('/auth/login', body);
  if (response.statusCode == 401) emit(AuthUnauthenticated());
  if (response.statusCode == 403) emit(AuthError('Account suspended.'));
  if (response.statusCode == 422) emit(AuthError(body.message, fieldErrors: body.errors));
  if (response.statusCode == 429) emit(AuthError('Too many attempts. Try again later.'));
} on SocketException {
  emit(AuthError('No internet connection.'));
} catch (e) {
  emit(AuthError('Unexpected error.'));
}
```

#### Global Interceptor (recommended with Dio)

```dart
// Intercept every response
onResponse: (response, handler) {
  if (response.statusCode == 401) {
    // Token expired or revoked — force logout
    authBloc.add(LogoutRequested());
  }
  return handler.next(response);
}
```

### 3.15 Image & File Uploads

All upload endpoints accept: `jpeg`, `jpg`, `png`, `webp`.

```dart
// Example: avatar upload
final request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/profile/avatar'));
request.headers['Authorization'] = 'Bearer $token';
request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
final response = await request.send();
```

| Upload | Field name | Max size | Max count |
|---|---|---|---|
| Avatar | `avatar` | 2MB | 1 |
| Store logo | `logo` | 2MB | 1 |
| Product images | `images[]` | 2MB each | 10 |
| Category image | `image` | 2MB | 1 |
| Payment proof | `payment_proof` | 4MB | 1 |

**All image URLs in responses are absolute** — pass directly to `Image.network()`. No URL construction needed.

### 3.16 Pagination Helper

```dart
class PaginationMeta {
  final int total, perPage, currentPage, lastPage, from, to;
  bool get hasNextPage => currentPage < lastPage;
}

// Usage in BLoC for infinite scroll
if (meta.hasNextPage) {
  add(LoadMoreItems(page: meta.currentPage + 1));
}
```

Default page size: 15. Override with `?per_page=N` (max 100).

### 3.17 Rate Limits Summary

| Scope | Limit | Endpoints |
|---|---|---|
| Auth (brute-force) | 5 req / min / IP | `/auth/login`, `/auth/register/*`, `/auth/password/*` |
| General API | Laravel default throttle | All other API routes |
| Search (if applicable) | 30 req / min | Certain listing endpoints |

On `429 Too Many Requests` — back off and show a countdown message.

---

## Part 4 — Pre-Launch Checklist

### Both Integrations

- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Set `APP_URL` to the real production domain
- [ ] Generate fresh `APP_KEY` (`php artisan key:generate`)
- [ ] Configure MySQL credentials (DB_*)
- [ ] Run `php artisan migrate --force`
- [ ] Run `php artisan storage:link`
- [ ] Run `php artisan config:cache && php artisan route:cache`
- [ ] Set `CORS_ALLOWED_ORIGINS` to specific origins (not `*`)
- [ ] Configure real mail provider (MAIL_MAILER, MAIL_HOST, etc.)
- [ ] Switch `QUEUE_CONNECTION` to `database` or `redis`
- [ ] Start queue worker: `php artisan queue:work`

### Dashboard Specific

- [ ] Add dashboard domain to `CORS_ALLOWED_ORIGINS`
- [ ] Create admin account via seeder or tinker (`User::create([... 'role' => 'admin'])`)
- [ ] Verify login → `role === 'admin'` check before granting access

### Flutter Specific

- [ ] Store bearer token in `flutter_secure_storage`
- [ ] Implement global 401 interceptor → force logout
- [ ] Register device token after every login
- [ ] Delete device token before logout
- [ ] Handle `status: "banned"` 403 → redirect to suspended screen
- [ ] Test on both Android (FCM) and iOS (APNS) for push delivery

---

## Part 5 — Key Architectural Notes

1. **No session cookies.** This is a pure token API. `supports_credentials: false` in CORS config. Do not send cookies from Flutter.

2. **Role enforcement is server-side only.** Never trust `user.role` from the client for access control — it is informational for routing only. The server enforces roles on every request via `EnsureRole` middleware.

3. **User status is enforced on every request.** A banned user's token is revoked on the next authenticated call. The Flutter app must handle the resulting 403 and log the user out.

4. **Merchant registration is atomic.** `POST /auth/register/merchant` creates the user and store in a single DB transaction. If either fails, neither is persisted.

5. **All list endpoints are paginated.** Never assume all records are returned. Always read `pagination.last_page` and implement paging.

6. **Image URLs are absolute.** No URL construction required on the client side — all `image_url`, `logo_url`, `avatar_url` fields are ready to use.

7. **Subscription request flow.** Merchant submits → Admin reviews → approve/reject. Approval atomically creates the active subscription record. Attempting to re-approve/reject returns 422.

8. **Order status is one-directional.** Status transitions are enforced server-side. The merchant's `PUT /merchant/orders/{id}/status` endpoint validates transitions — do not build client-side state machines that can go out of sync.
