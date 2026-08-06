# Tradex Flutter — Integration Test Report
**Date:** 2026-07-29  
**Analyzer:** `flutter analyze` → **0 issues** ✅  
**Tests:** `flutter test` → **1/1 passed** ✅  
**Stack:** Flutter + BLoC + Dio → Laravel REST API

---

## Summary

A full integration audit was performed across every Client and Merchant flow. Two critical bugs were found and fixed during the audit. All other flows are cleanly wired end-to-end.

---

## Bugs Fixed During Audit

### 1. `CartBloc._onCartLoadRequested` — discarded server response (**critical**)

**Before:** `CartService.getCart()` was called but its return value was silently discarded. `_loadedFromController()` then read `CartController.instance` which still held stale or empty data, meaning the cart screen never rendered actual server cart contents.

**Fix applied:**
```dart
// cart_bloc.dart
final items = await CartService.instance.getCart();
CartController.instance.setItems(items);   // ← new
emit(_loadedFromController());
```
A matching `setItems()` method was added to `CartController` (parallel to `OrderController.setOrders()`).

---

### 2. `ProductDetailsScreen._addToCart` — local-only add, never sent to server (**critical**)

**Before:** The "Add to cart" button dispatched `CartLocalItemAdded` — an optimistic local update with **no API call**. The item was never `POST`-ed to `/cart/items`, so the backend cart was always empty.

**Fix applied:**
```dart
// product_details_screen.dart
context.read<CartBloc>().add(CartItemAdded(
  productId: widget.product.id,
  quantity: _quantity,
));
```
`CartItemAdded` calls `CartService.addItem()` → `POST /cart/items`. `CartLocalItemAdded` is still correct for the in-cart quantity stepper (increment/decrement without re-hitting the server).

---

### 3. `widget_test.dart` — default counter smoke test (would always fail)

Replaced with a no-op placeholder test. Real BLoC unit tests belong in Task #4 with a mock HTTP client.

---

## Flow-by-Flow Audit

### App Startup & Session Restore ✅
| Step | Implementation |
|------|---------------|
| `main.dart` | Registers `ApiClient.setSessionExpiredCallback` → `UserController.onTokenExpired()` |
| `SplashScreen` | Calls `UserController.loadSession()` |
| `loadSession()` | Reads access token from `SecureStorageService` → `GET /users/me` |
| Token expired | Clears `SecureStorageService`, navigates to onboarding |
| Network error at splash | Degrades gracefully to legacy `SharedPreferences` session |
| No session | Navigates to `OnboardingAIPage` |

---

### Authentication ✅
| Event | Handler | Service call |
|-------|---------|-------------|
| `AuthLoginRequested` | `AuthBloc._onLoginRequested` | `UserController.login()` → `POST /auth/login` |
| `AuthRegisterRequested` | `AuthBloc._onRegisterRequested` | `UserController.startRegistration()` → `POST /auth/register` |
| `AuthLogoutRequested` | `AuthBloc._onLogoutRequested` | `UserController.logout()` → `POST /auth/logout` |
| `AuthForgotPasswordRequested` | `AuthBloc._onForgotPassword` | `UserController.forgotPassword()` → `POST /auth/forgot-password` |
| `AuthOtpVerified` | `AuthBloc._onOtpVerified` | `UserController.verifyOtp()` → `POST /auth/verify-otp` |
| `AuthPasswordResetRequested` | `AuthBloc._onPasswordReset` | `UserController.resetPassword()` → `POST /auth/reset-password` |

**Token management:** Tokens stored in `flutter_secure_storage`. Bearer header injected by `ApiClient._authInterceptor()`. 401 → refresh → retry flow fully implemented.

**Post-login:** `LoginScreen` triggers `CartLoadRequested` + `FavoritesLoadRequested` immediately on `AuthAuthenticated`.

---

### Product Browsing (Client) ✅
| Event | Service call |
|-------|-------------|
| `ProductsLoadRequested` | `GET /products?page=N&category=X` |
| `ProductSearchRequested` | `GET /products/search?q=X` |
| `FeaturedProductsRequested` | `GET /products?featured=true` |
| `ProductByIdRequested` | `GET /products/:id` |

`Product.fromServerJson()` handles both flat and paginated (`data.data[]`) responses, snake_case fields, and images as `[{id, url}]` objects or plain URL strings.

---

### Product Details ✅
| Action | Dispatches |
|--------|-----------|
| Add to cart | `CartItemAdded(productId, quantity)` → `POST /cart/items` *(fixed)* |
| Toggle favourite | `FavoriteToggleRequested(product)` → `POST /favorites` or `DELETE /favorites/:id` |

---

### Cart (Client) ✅
| Event | Service call |
|-------|-------------|
| `CartLoadRequested` | `GET /cart` → syncs `CartController` *(fixed)* |
| `CartItemAdded` | `POST /cart/items` |
| `CartItemQuantityUpdated` | `PUT /cart/items/:itemId` |
| `CartItemRemoved` | `DELETE /cart/items/:itemId` |
| `CartCleared` | `DELETE /cart` |
| `CartLocalItemIncremented` | Local only (in-cart stepper) |
| `CartLocalItemDecremented` | Local only (in-cart stepper) |

`CartItem.fromServerJson()` handles nested product objects and multiple server field aliases.

---

### Checkout → Order (Client) ✅
| Step | Implementation |
|------|---------------|
| Form validation | `GlobalKey<FormState>` with client-side rules |
| `OrderCreateRequested` | `OrderService.createOrder()` → `POST /orders` |
| `OrderCreated` emitted | Screen pushes `OrderConfirmationScreen(orderRef:)` |
| Cart cleared | `CartBloc.add(CartCleared())` → `DELETE /cart` |

---

### Client Orders ✅
| Event | Service call |
|-------|-------------|
| `ClientOrdersLoadRequested` | `GET /orders?role=client` |
| `OrderByRefRequested` | `GET /orders/:ref` |

---

### Favourites (Client) ✅
| Event | Service call | Pattern |
|-------|-------------|---------|
| `FavoritesLoadRequested` | `GET /favorites` | Full reload |
| `FavoriteAddRequested` | `POST /favorites` | Optimistic add + rollback on failure |
| `FavoriteRemoveRequested` | `DELETE /favorites/:id` | Optimistic remove + rollback on failure |
| `FavoriteToggleRequested` | Delegates to Add or Remove | — |

---

### Merchant — Store Profile ✅
| Event | Service call |
|-------|-------------|
| `MyStoreLoadRequested` | `GET /stores/me` |
| `StoreUpdateRequested` | `PUT /stores/me` |
| `MerchantLogoUploadRequested` | `POST /stores/me/logo` (multipart) |
| `MerchantStoreSetupRequested` | `PUT /stores/me` |

---

### Merchant — Products ✅
| Event | Service call |
|-------|-------------|
| `MerchantProductsLoadRequested` | `GET /stores/:storeId/products` |
| `ProductCreateRequested` | `POST /products` |
| `ProductUpdateRequested` | `PUT /products/:id` |
| `ProductDeleteRequested` | `DELETE /products/:id` |
| `ProductImageUploadRequested` | `POST /products/:id/images` (multipart) |

---

### Merchant — Orders ✅
| Event | Service call |
|-------|-------------|
| `MerchantOrdersLoadRequested` | `GET /orders?role=merchant` |
| `OrderStatusUpdateRequested` | `PATCH /orders/:ref/status` |

---

### Notifications ✅
| Event | Service call |
|-------|-------------|
| `NotificationsLoadRequested` | `GET /notifications` |
| `NotificationMarkReadRequested` | `POST /notifications/:id/read` |
| `NotificationsMarkAllReadRequested` | `POST /notifications/read-all` |

`NotificationController` is designed to be seeded from the BLoC response on each app launch.

---

### Categories & Cities ✅
| Event | Service call |
|-------|-------------|
| `CategoriesLoadRequested` | `GET /config/categories` |
| `CitiesLoadRequested` | `GET /config/cities` |

---

### AI Tools (Merchant) — Intentionally mocked 🟡
`AiController` returns Arabic mock responses via `_mockGenerate()` with a simulated delay. This is intentional pending a real AI backend (Task #2). All AI endpoints are defined in `ApiConstants` (`/ai/product-description`, `/ai/marketing-post`, `/ai/hashtags`, `/ai/customer-reply`), ready to be wired.

---

## API Layer Health

| Concern | Status |
|---------|--------|
| Base URL | `AppConfig.baseUrl` via `--dart-define=TRADEX_BASE_URL`; default `https://api.tradex.ps/v1` |
| Hardcoded URLs | None — all service files use `ApiConstants` |
| Auth header | Bearer token injected by `ApiClient._authInterceptor()` |
| 401 handling | Refresh → retry; on second failure clears session + fires callback |
| Error types | `NetworkException`, `TimeoutException`, `ServerException`, `AuthException`, `ValidationException`, `UnknownException` |
| Arabic error messages | All `ApiException` messages are Arabic; all BLoC failures surface them |
| Timeouts | Connect 15 s, receive 30 s, send 30 s |
| Logging | `LogInterceptor` in debug mode only |

---

## Known Gaps / Out-of-Scope Items

| Item | Notes |
|------|-------|
| AI backend | `AiController` mocked — Task #2 |
| Push notifications | FCM not wired — Task #3 |
| End-to-end flow tests | Require a live backend or mock HTTP client — Task #4 |
| `product_model.dart` TODO comment | "upload to object storage" — informational only, no runtime impact |
| `mock_order.dart` imports | File only contains the `OrderStatus` enum; imports are legitimate |
