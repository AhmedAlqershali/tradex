# Tradex — AI SaaS Commerce App

## Project overview

Flutter mobile commerce app targeting Gaza, Palestine. Arabic RTL. Two roles: **Client** (shopper) and **Merchant**.

- **Backend:** Laravel API at `https://api.tradex.ps/v1` — Auth module fully wired (Phase B complete).
- **AI features must never be deleted**, only deferred.

## Architecture

**State pattern:** Singleton + `ValueNotifier` + `ValueListenableBuilder` for local state. `flutter_bloc` (BLoC) for all API-backed features (Auth, User, Product, Order, Notification, Store, Cart).

### Controllers (all singletons)
| Controller | File | Notifier |
|---|---|---|
| `CartController` | `lib/shared/cart/cart_controller.dart` | `ValueNotifier<List<CartItem>>` |
| `OrderController` | `lib/shared/orders/order_controller.dart` | `ValueNotifier<List<AppOrder>>` |
| `ProductController` | `lib/shared/products/product_controller.dart` | `ValueNotifier<List<Product>>` |

### Models
| Model | File | Purpose |
|---|---|---|
| `Product` | `lib/shared/models/product_model.dart` | Full product with `toJson`/`fromJson` |
| `StoreModel` | `lib/shared/models/store_model.dart` | Store with `id` + `location` fields |
| `AppOrder` / `AppOrderProduct` | `lib/shared/orders/order_controller.dart` | Order snapshot |
| `CartItem` | `lib/shared/cart/cart_controller.dart` | Cart line item |

## How to run

Workflow: **Start application**
Command: `nix-shell -p flutter --run 'flutter pub get && flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0 --profile'`

Notes:
- Must use `nix-shell -p flutter --run '...'` — the workflow shell does NOT load the Nix profile, so `flutter` is never in PATH directly. The nix-shell wrapper resolves `pkgs.flutter` from stable-25_05 to flutter 3.32.0 (sdk-links variant) which includes dart2js_aot.dart.snapshot required for web compilation.
- `--profile` mode is required. Debug mode serves Dart files via requirejs which fails through the Replit proxy.
- `cacert` nix package is installed to support TLS in the environment.

## Backend (Laravel API)

Location: `tradx/tradx/backend/`  
Stack: Laravel 12, PHP 8.4, Sanctum, SQLite (dev), PHPUnit  
Workflow: **Backend API** — `cd tradx/tradx/backend && php artisan serve --host=0.0.0.0 --port=5001`  
Tests: `cd tradx/tradx/backend && php artisan test` — **26/26 passing**

### Backend phase status

- ✅ Phase 1 — Product Management (merchant CRUD + admin monitoring, image upload, filters/pagination, ProductPolicy)
  - Routes: `POST/GET/PUT/DELETE /api/v1/merchant/products`, `GET /api/v1/admin/products`
  - Architecture: Service → Repository → Eloquent (interfaces + DI bindings)
  - Tests: 26 tests, 65 assertions, all green (SQLite in-memory)

### Run tests

```
cd tradx/tradx/backend && php artisan test
```

---

## Implemented phases

- ✅ Phase A — API Infrastructure (dio, flutter_secure_storage, ApiClient, SecureStorageService, 9 service stubs, ErrorState, NetworkError, model serialisation)
- ✅ Phase B — Authentication Module (AuthService, AuthBloc, UserController wired to Laravel API; login, register, logout, forgot-password, OTP verify, reset-password; JWT stored in flutter_secure_storage; auto-login on splash; token refresh interceptor; `flutter analyze` passes 0 issues)
- ✅ CartController + shared cart
- ✅ Checkout → OrderController → Order Confirmation
- ✅ Client Orders + Client Order Details (live status)
- ✅ Merchant Orders + Merchant Order Details (status updates)
- ✅ ProductController + Product model
- ✅ Merchant AddProduct → publishes to ProductController
- ✅ Home screen wired to ProductController
- ✅ Search wired to ProductController (live query)
- ✅ Store Details wired to ProductController
- ✅ Product Details accepts Product argument
- ✅ Recently Arrived sorted by createdAt
- ✅ Nearby Stores from ProductController seed data
- ✅ AI features preserved on disk
- ✅ UserController + AppUser model (singleton, ValueNotifier)
- ✅ Session persistence via shared_preferences (survives app restart)
- ✅ Splash screen checks saved session → routes client/merchant directly
- ✅ Register flow reads real form values → UserController.startRegistration()
- ✅ Login screen reads email/password → UserController.login()
- ✅ Complete client profile saves region → UserController.updateProfile()
- ✅ Complete photo screen saves photo path → UserController.updateProfile()
- ✅ Complete merchant profile calls UserController.completeMerchantProfile()
- ✅ ProfileScreen reads live data from UserController (name, region, role, store)
- ✅ EditProfileScreen pre-fills from UserController, save button wired

## Navigation rules

- `ProductDetailsScreen` requires `required Product product`
- `StoreDetailsScreen` requires `required StoreModel store`
- All product cards in every screen navigate to `ProductDetailsScreen(product: p)`
- All store cards navigate to `StoreDetailsScreen(store: store)`

## AI features

`lib/screens/merchant/ai_marketing_tools_screen.dart` — 966 lines. Included in merchant bottom-nav (AI أدوات tab). `AiController` makes real calls to the backend AI endpoints. `lib/core/services/ai_service.dart` is also implemented and available for direct service-layer use.

## User preferences

- Arabic RTL throughout
- IBM Plex Sans font
- Primary color: `Color(0xff4D41DF)`
- State management: `flutter_bloc` (BLoC pattern) for all API-backed features; singleton `ValueNotifier` for local cache layers
- Backend: Laravel 12 API at `https://api.tradex.ps/v1` (fully integrated)
- All user flows wired to real backend — no mock data in production paths
