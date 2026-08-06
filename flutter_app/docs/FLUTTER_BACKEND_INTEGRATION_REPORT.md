# Tradex Flutter — Backend Integration Report

**Date:** 2026-07-29  
**Phase:** Backend Integration (Phases A–F)  
**Status:** Complete

---

## Summary

All Flutter screens have been migrated from mock/seed data to live Laravel API calls via BLoC state management. Mock data classes have been removed. The app now makes real HTTP requests for every user-facing data operation.

---

## BLoCs — Final Inventory

| BLoC | Events | Backend Endpoints | Status |
|---|---|---|---|
| `AuthBloc` | Login, Register, Logout, ForgotPassword, VerifyOtp, ResetPassword, SessionRestore | POST /auth/login, /register, /logout, /forgot-password, /verify-otp, /reset-password · GET /auth/me | ✅ Complete |
| `UserBloc` | Load, Update, AvatarUpload, MerchantProfile, FullProfileUpdate | GET /users/me · PUT /users/me · POST /users/me/avatar · PUT /stores/me | ✅ Complete |
| `ProductBloc` | LoadList, LoadById, Search, Create, Update, Delete, ImageUpload, ImageDelete, Categories | GET/POST /products · PUT/DELETE /products/:id · POST/DELETE /products/:id/images · GET /config/categories | ✅ Complete |
| `StoreBloc` | LoadAll, LoadById, LoadMyStore, UpdateMyStore, LoadStoreProducts | GET /stores · GET /stores/:id · GET/PUT /stores/me · GET /stores/:id/products | ✅ Complete |
| `CartBloc` | Load, AddItem, UpdateItem, RemoveItem, Clear, LocalAdd/Increment/Decrement | GET/POST/PUT/DELETE /cart · DELETE /cart/clear | ✅ Complete |
| `OrderBloc` | ClientOrders, MerchantOrders, OrderByRef, Create, UpdateStatus | GET /orders · GET /orders/merchant · GET /orders/:ref · POST /orders · PATCH /orders/:ref/status | ✅ Complete |
| `FavoriteBloc` | Load, Add, Remove, Toggle | GET /favorites · POST /favorites · DELETE /favorites/:id | ✅ Complete |
| `NotificationBloc` | Load, MarkRead, MarkAllRead | GET /notifications · PATCH /notifications/:id/read · PATCH /notifications/read-all | ✅ Complete |
| `CategoryBloc` | CategoryListRequested, CityListRequested | GET /config/categories · GET /config/cities | ✅ **New — this session** |
| `MerchantBloc` | MerchantLogoUploadRequested, MerchantStoreSetupRequested | POST /stores/me/logo · PUT /stores/me | ✅ **New — this session** |

All 10 BLoCs are exported from `lib/presentation/blocs/blocs.dart` and registered as `MultiBlocProvider` entries in `lib/main.dart`.

---

## Screen Migration — This Session

### `notification_screen.dart` → `NotificationBloc`

**Before:** Hardcoded `NotificationCard` widgets with static Arabic strings and fixed timestamps.  
**After:** `StatefulWidget` that dispatches `NotificationsLoadRequested` on `initState`. `BlocBuilder` renders loading spinner, error retry, empty state, and live `AppNotification` objects grouped by today vs. older. Mark-read and mark-all-read wired to bloc events. Tapping a `newArrival` notification navigates to `RecentlyArrivedScreen`.

### `edit_product_screen.dart` → `ProductBloc`

**Before:** `ProductController.instance.updateProduct(updated)` — local in-memory update only.  
**After:** `BlocListener` + `BlocBuilder` wrapping the scaffold. `_saveProduct()` dispatches `ProductUpdateRequested(id, name:, price:, …)` → `PUT /products/:id`. Each newly-picked image triggers `ProductImageUploadRequested` → `POST /products/:id/images`. Loading state disables the save button. `ProductUpdated` state triggers snack + `Navigator.pop`. `ProductFailure` shows error snack.

---

## Profile Mutation Wiring — `UserController`

### `updateProfile()`

**Before:** Local `copyWith` on the in-memory user only (Phase C placeholder comment).  
**After:**
1. If `photoPath` is a local file path (not `http://` / `https://`), uploads via `UserService.uploadAvatar()` → `POST /users/me/avatar` and stores the returned URL.
2. If any text field (`name`, `phone`, `region`) is provided, calls `UserService.updateMe()` → `PUT /users/me` and merges the server response.
3. Falls back to local `copyWith` only when no server fields changed.

### `completeMerchantProfile()`

**Before:** Local `copyWith` to attach store name/ID with a generated local `store-{timestamp}` ID.  
**After:**
1. If `logoPath` is a local file path, uploads via `StoreService.uploadStoreLogo()` → `POST /stores/me/logo`.
2. Calls `StoreService.updateMyStore()` → `PUT /stores/me` with name, category, city.
3. Updates local user state with the server-confirmed store ID and name.

---

## Dead Code Removed

| File | Change |
|---|---|
| `lib/shared/models/mock_order.dart` | Removed `MockOrderProduct` and `MockOrder` classes. `OrderStatus` enum + `OrderStatusX` extension retained (used everywhere). |
| `lib/shared/notifications/notification_controller.dart` | Removed `_seedNotifications()` method and its constructor call. `AppNotification` model class retained (used by `NotificationBloc` and `NotificationService`). |
| `lib/screens/merchant/edit_product_screen.dart` | Removed `import 'package:ai_saas/shared/products/product_controller.dart'` and the `ProductController.instance.updateProduct()` call. |

> `lib/shared/products/product_controller.dart` — still present as it is referenced by no screen after the `edit_product_screen` migration, but the file itself contains no mock-seed side effects at construction time (only passive `ValueNotifier` seeding). It can be deleted in a cleanup pass once all remaining `ValueListenableBuilder` usages across the codebase are confirmed gone.

---

## Phase G Placeholder — AI Tools

`lib/screens/ai_marketing_tools_screen.dart` continues to use `AiController` (mock engine). `lib/core/services/ai_service.dart` exists but all methods throw `UnimplementedError`. This is intentional — backend AI endpoints are not yet finalized. The screen will be migrated to an `AiBloc` when Phase G is activated.

---

## Screens Already on BLoC (No Changes Needed)

| Screen | BLoCs |
|---|---|
| `shopper_home.dart` | StoreBloc + ProductBloc |
| `search_screen.dart` | ProductBloc |
| `nearby_stores_screen.dart` | StoreBloc |
| `recently_arrived_screen.dart` | ProductBloc |
| `store_details_screen.dart` | StoreBloc |
| `product_details_screen.dart` | CartBloc + FavoriteBloc |
| `merchant_home.dart` | OrderBloc + ProductBloc + StoreBloc |
| `merchant_orders_screen.dart` | OrderBloc |
| `merchant_order_details_screen.dart` | OrderBloc |
| `merchant_products_screen.dart` | ProductBloc |
| `add_product.dart` | ProductBloc |
| `cart_screen.dart` | CartBloc |
| `checkout_screen.dart` | OrderBloc + CartBloc |
| `client_orders_screen.dart` | OrderBloc |
| `profile_screen.dart` | UserBloc + FavoriteBloc |
| `login_screen.dart` | AuthBloc |

---

## State Patterns Consistently Applied

Every migrated screen follows this pattern:

```
initState → dispatch LoadRequested event
BlocBuilder:
  ProductLoading / NotificationLoading → CircularProgressIndicator
  *Loaded(data)                        → render data (grouped if needed)
  *Failure(message)                    → error + retry button
  empty list                           → illustrated empty state
BlocListener (mutations only):
  *Updated / *Created / *Deleted       → snack + optional Navigator.pop
  *Failure                             → error snack
```

Optimistic updates are used in `CartBloc` and `FavoriteBloc` for immediate UI responsiveness.

---

## Files Created / Modified — Quick Reference

```
NEW
  lib/presentation/blocs/category/category_bloc.dart
  lib/presentation/blocs/category/category_event.dart
  lib/presentation/blocs/category/category_state.dart
  lib/presentation/blocs/merchant/merchant_bloc.dart
  lib/presentation/blocs/merchant/merchant_event.dart
  lib/presentation/blocs/merchant/merchant_state.dart

MODIFIED
  lib/presentation/blocs/blocs.dart               — +2 exports
  lib/main.dart                                    — +2 BlocProviders
  lib/screens/notification_screen.dart             — full BLoC rewrite
  lib/screens/merchant/edit_product_screen.dart    — ProductBloc wiring
  lib/shared/users/user_controller.dart            — updateProfile + completeMerchantProfile → real APIs
  lib/shared/notifications/notification_controller.dart — seed removed
  lib/shared/models/mock_order.dart                — MockOrder/MockOrderProduct removed
```
