---
name: Flutter base URL mechanism
description: The dart-define TRADEX_BASE_URL mechanism was commented out, hardcoding a LAN IP. Always use String.fromEnvironment with the deployed backend as default.
---

`flutter_app/lib/core/api/app_config.dart` had the `String.fromEnvironment` call commented out, replaced with a hardcoded LAN IP `http://192.168.0.108:8000/api/v1`.

**Fix applied:** Restored `String.fromEnvironment('TRADEX_BASE_URL', defaultValue: 'https://<backend-domain>/api/v1')`.

**How to apply:** When running or building the Flutter app, pass the correct backend URL:
```bash
flutter run --dart-define=TRADEX_BASE_URL=https://<backend-domain>/api/v1
flutter build apk --dart-define=TRADEX_BASE_URL=https://<backend-domain>/api/v1
```

The Laravel app's configured route prefix is `/api/v1`; the deployed backend URL must include both segments. A `TRADEX_BASE_URL` dart-define overrides the default at build time.
