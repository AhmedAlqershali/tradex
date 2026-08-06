# Tradex — Full-Stack Project

A marketplace platform with a **Laravel 12 REST API backend** and a **Flutter mobile app**.

---

## Project Structure

```
tradex-backend/   — Laravel 12 API (PHP 8.4, Sanctum, SQLite)
flutter_app/      — Flutter mobile app (BLoC state management)
```

---

## Backend — tradex-backend/

### Running on Replit

The `Start application` workflow runs from the root:
```bash
cd tradex-backend && php artisan config:clear && php artisan serve --host=0.0.0.0 --port=5000
```

Health check: `GET /api/v1/health`  
API base: `/api/v1`

### Stack
- **Laravel 12** · PHP 8.4
- **Laravel Sanctum** — token-based auth (Bearer tokens)
- **SQLite** — `tradex-backend/database/database.sqlite`
- **Google Gemini API** — AI content generation (set `GEMINI_API_KEY` secret)

### Roles
| Role | Access |
|---|---|
| `client` | Browse, cart, orders, favorites, reviews, profile |
| `merchant` | Store & product management, orders, AI tools, subscriptions |
| `admin` | Users, stores, categories, plans, analytics |

### Testing
```bash
cd tradex-backend && php artisan test
# 522 tests, 1404 assertions — all passing
```

### Replit audit status (2026-08-06)
- Java/GraalVM 19.0.2 is available and the Gradle wrapper runs with Gradle 8.14.
- `flutter clean`, `flutter pub get`, `flutter analyze`, and `flutter test` pass.
- Laravel smoke tests pass for client and merchant registration, login, authenticated
  profile/session endpoints, catalog reads, cart/favorites/orders reads, merchant
  store/product/order/dashboard/analytics reads, and logout.
- The Android SDK is not installed in this workspace. `adb` platform-tools are
  available, but `sdkmanager`, Android platforms, build-tools, and an emulator are
  not. Therefore `flutter build apk --debug` is blocked with `No Android SDK found`.
- Android status: **ANDROID BUILD BLOCKED — Android SDK/toolchain unavailable.**
  Runtime status: **ANDROID RUNTIME BLOCKED — no Android device/emulator available.**
- AI live testing remains blocked unless the server-side `GEMINI_API_KEY` is configured.

### Architecture
```
Controller → Service → Repository → Model
```
- All responses: `{ success, message, data }`
- AI: Controller → AiService → GeminiProviderService → Gemini API

### Documentation
- `tradex-backend/API_DOCUMENTATION.md` — all 93 endpoints
- `tradex-backend/HANDOVER_REPORT.md` — full audit and status
- `tradex-backend/docs/` — architecture, database, backend guide

---

## Flutter App — flutter_app/

### API Configuration
The base URL is set in `lib/core/api/app_config.dart`:
```bash
# Development (Replit default):
flutter run --dart-define=TRADEX_BASE_URL=https://<your-replit-domain>/api/v1

# Production:
flutter build apk --dart-define=TRADEX_BASE_URL=https://api.tradex.ps/v1
```

### Stack
- **Flutter/Dart** with BLoC state management
- **Dio** HTTP client
- **flutter_secure_storage** — token persistence
- **google_fonts**, **flutter_screenutil**

---

## Environment Variables

| Variable | Purpose | Where to set |
|---|---|---|
| `GEMINI_API_KEY` | Google Gemini AI | Replit Secrets |
| `DB_DATABASE` | SQLite path | Set automatically |
| `APP_URL` | Server URL | Set automatically |
| `MAIL_MAILER` | Mail driver (log for dev) | Set automatically |

---

## Fixes Applied (2026-08-06)

### Backend
1. Fixed `DB_DATABASE` path (was `/var/www/html/…`, now correct Replit path)
2. Fixed `FILESYSTEM_DISK` to `public` (storage links work)
3. Fixed `MAIL_MAILER` to `log` (no SMTP needed for dev)
4. Stripped UTF-8 BOM from 8 AI contract/service files (caused PHP fatal errors)
5. Fixed `AiServiceInterface` — was declaring `ask()`, now correctly declares `generate()`
6. Fixed `AiProviderInterface` — was declaring `generateResponse/streamResponse`, now correctly declares `complete()`
7. Fixed `AiUsageServiceInterface` — was declaring old `hasAvailableQuota/logUsage`, now declares real `checkLimit/record/recordRequest/getUsageSummary`
8. Rewrote `AiUsageService` with per-user limits from `AiSetting` model + subscription plan limits
9. Updated `GeminiAiProvider` to implement `complete()` (was implementing wrong interface)
10. Cleared `AiServiceProvider` conflicting bindings (now defers to `RepositoryServiceProvider`)
11. Created missing `config/view.php` (Blade compiler was getting empty path)
12. Configured root workflow + storage link

### Flutter
1. Fixed `app_config.dart` — restored `dart-define` mechanism (was hardcoded to LAN IP `192.168.0.108`)
2. Fixed `user_controller.dart::verifyOtp` — was calling `resendVerificationEmail()` (a protected endpoint) during the unauthenticated forgot-password flow, causing 401 crashes. Now a safe no-op.

---

## User Preferences

- Keep existing project architecture (Service → Repository → Eloquent pattern)
- Do not rewrite or restructure existing features
- All API responses must follow the `{ success, message, data }` envelope
- Images must always return complete URLs (not relative paths)
- Flutter BLoC integration — keep JSON clean, flat, and consistent
- Arabic and English language support in AI features
