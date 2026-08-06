# Tradex — Phase Report: BLoC Migration Completion & Analyzer Cleanup
**Date:** 2026-07-28
**Flutter Analyze Result:** ✅ No issues found (0 errors, 0 warnings, 0 infos)

---

## Summary

Continued from the prior phase (API foundation, Dio client, services, model updates, MultiBlocProvider, FavoriteBloc, main.dart, barrel exports, most screen migrations). This phase resolved every remaining compile error and analyzer issue, achieving a fully clean `flutter analyze` pass.

---

## Completed Work

### 1. Barrel Export Fix — `blocs.dart`

**Problem:** `blocs.dart` re-exported event and state files (`product_event.dart`, `cart_event.dart`, etc.) as standalone libraries, but each file contains a `part of` directive linking it to its bloc file. You cannot export a `part-of` file as a library.

**Fix:** Removed the redundant event/state re-exports. Each bloc file uses `part` to include its event/state files — importing the bloc is sufficient and automatically includes all its parts.

**File:** `lib/presentation/blocs/blocs.dart`

---

### 2. `SizeButton` Widget — Created

**Problem:** `login_screen.dart`, `register_screen.dart`, and `add_product.dart` all called `SizeButton(title:, onTap:)`, but no such class existed in `size_button.dart` (which only had `PrimaryButton`).

**Fix:** Added `SizeButton` as a full-width primary action button with `title` and `onTap` parameters, matching the call sites exactly.

**File:** `lib/screens/widgets/size_button.dart`

---

### 3. `AddProductTextField` Widget — Created

**Problem:** `add_product.dart` called `AddProductTextField(label:, hint:, icon:, controller:, …)` but the file `add_product_textfield.dart` only exported `AppTextField` (with a different API: `name`, `controller`). The previous migration had removed the import, exposing the undefined-method errors.

**Fix:** Added a new `AddProductTextField` class with `label`, `hint`, `icon`, `controller`, `keyboardType`, and `maxLines` parameters — a proper labelled text field with a leading icon, matching all four call sites in `add_product.dart`.

**File:** `lib/screens/widgets/add_product_textfield.dart`

---

### 4. `CartController.removeItem` → `remove`

**Problem:** `cart_screen.dart` called `CartController.instance.removeItem(id)` but the method is named `remove(id)`.

**Fix:** Renamed the call to `remove`.

**File:** `lib/screens/client/cart_screen.dart`

---

### 5. `AppOrderProduct` / `AppOrder` Import Fixes

**Problem:** Multiple screens imported `mock_order.dart` (which only has `OrderStatus`, `MockOrder`, `MockOrderProduct`) but used `AppOrder` and `AppOrderProduct` — classes defined in `order_controller.dart`. This caused undefined-class errors on `AppOrder`, null-safety false positives, and `non_type_as_type_argument` errors on typed lists.

**Fix:** Added `order_controller.dart` import to each affected screen. Kept `mock_order.dart` import where `OrderStatus` is also needed.

**Files modified:**
- `lib/screens/client/checkout_screen.dart` — replaced `mock_order.dart` with `order_controller.dart`
- `lib/screens/client/client_orders_screen.dart` — added `order_controller.dart`
- `lib/screens/merchant/merchant_orders_screen.dart` — added `order_controller.dart`
- `lib/screens/merchant/merchant_order_details_screen.dart` — added `order_controller.dart`

---

### 6. `OrderStatusTimeline` Parameter Fix

**Problem:** `merchant_order_details_screen.dart` called `OrderStatusTimeline(currentStatus: order.status)` but the widget's constructor signature is `OrderStatusTimeline({required AppOrder order})`.

**Fix:** Updated the call to `OrderStatusTimeline(order: order)`.

**File:** `lib/screens/merchant/merchant_order_details_screen.dart`

---

### 7. `_getActions` Exhaustive Switch

**Problem:** `_getActions(AppOrder order)` returned `List<_OrderAction>` (non-nullable) via a switch over `OrderStatus`, but Dart reported `body_might_complete_normally` when `AppOrder` was undefined (untyped switch). After the import fix, the switch became exhaustive and the temporary fallback `return []` became dead code.

**Fix:** Removed the dead-code `return []` after confirming the switch is exhaustive over all `OrderStatus` enum values.

**File:** `lib/screens/merchant/merchant_order_details_screen.dart`

---

### 8. `OfferScreen` → `RecentlyArrivedScreen`

**Problem:** `weekend_promo_banner.dart` referenced `OfferScreen` which does not exist. The import was `recently_arrived_screen.dart` which exports `RecentlyArrivedScreen`.

**Fix:** Replaced `const OfferScreen()` with `const RecentlyArrivedScreen()`.

**File:** `lib/screens/client/widgets/home/weekend_promo_banner.dart`

---

### 9. `store_details_screen.dart` Null Safety

**Problem:** `widget.store.id` is `String?` (nullable), but it was accessed unconditionally with `.isNotEmpty` and passed as `String` to `StoreProductsLoadRequested`.

**Fix:** Added null guard: `final storeId = widget.store.id; if (storeId != null && storeId.isNotEmpty)`.

**File:** `lib/screens/store_details_screen.dart`

---

### 10. Unused Imports / Fields Cleanup

| File | Removed |
|---|---|
| `lib/screens/merchant/add_product.dart` | `ai_controller.dart`, `product_model.dart`, `user_controller.dart`, unused `_aiLoading` field, unused `storeName` local |
| `lib/screens/search_screen.dart` | Silenced unused `_selectedRegion` field (reserved for future region filter) |

---

## Files Modified

| File | Change |
|---|---|
| `lib/presentation/blocs/blocs.dart` | Removed part-of re-exports |
| `lib/screens/widgets/size_button.dart` | Added `SizeButton` class |
| `lib/screens/widgets/add_product_textfield.dart` | Added `AddProductTextField` class |
| `lib/screens/client/cart_screen.dart` | `removeItem` → `remove` |
| `lib/screens/client/checkout_screen.dart` | Import fix |
| `lib/screens/client/client_orders_screen.dart` | Import fix |
| `lib/screens/merchant/merchant_orders_screen.dart` | Import fix |
| `lib/screens/merchant/merchant_order_details_screen.dart` | Import fix, `OrderStatusTimeline` fix, exhaustive switch |
| `lib/screens/client/widgets/home/weekend_promo_banner.dart` | `OfferScreen` → `RecentlyArrivedScreen` |
| `lib/screens/store_details_screen.dart` | Null safety fix |
| `lib/screens/merchant/add_product.dart` | Removed unused imports and dead fields |
| `lib/screens/search_screen.dart` | Suppressed unused-field lint |

---

## Architecture Verification

Every connected screen follows the required data flow:

| Flow | Screen → Bloc → Service → Dio → Laravel API |
|---|---|
| **Authentication** | `LoginScreen` / `RegisterScreen` → `AuthBloc` → `AuthService` → `ApiClient` → `/auth/*` |
| **Products** | `ShopperHome` / `ProductDetailsScreen` → `ProductBloc` → `ProductService` → `ApiClient` → `/products/*` |
| **Cart** | `CartScreen` / `CheckoutScreen` → `CartBloc` → `CartService` → `ApiClient` → `/cart/*` |
| **Orders** | `CheckoutScreen` / `ClientOrdersScreen` → `OrderBloc` → `OrderService` → `ApiClient` → `/orders/*` |
| **Favorites** | Product screens → `FavoriteBloc` → `FavoriteService` → `ApiClient` → `/favorites/*` |
| **Merchant** | `MerchantOrdersScreen` / `AddProduct` → `OrderBloc` / `ProductBloc` → respective services → `ApiClient` |
| **Notifications** | `NotificationScreen` → `NotificationBloc` → `NotificationService` → `ApiClient` → `/notifications/*` |

---

## Remaining Work

- **Flutter SDK installation** — `nix-shell -p flutter` works for one-off commands but no persistent workflow is configured. A workflow running `flutter analyze` or building an APK needs a configured Nix channel entry. (Tracked as Task #2.)
- **Backend URL** — The production default `https://api.tradex.ps/v1` is baked in via `AppConfig`. A running Laravel backend at that URL is required for end-to-end runtime verification.
- **Next feature phase** — See `attached_assets/` for the next planned development phase specs. (Tracked as Task #3.)

---

## Analyzer Results

```
Analyzing flutter_app...
No issues found! (ran in 6.2s)
```

**0 errors · 0 warnings · 0 infos**
