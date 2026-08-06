---
name: Flutter base URL mechanism
description: The dart-define TRADEX_BASE_URL mechanism was commented out, hardcoding a LAN IP. Always use String.fromEnvironment with Replit domain as default.
---

`flutter_app/lib/core/api/app_config.dart` had the `String.fromEnvironment` call commented out, replaced with a hardcoded LAN IP `http://192.168.0.108:8000/api/v1`.

**Fix applied:** Restored `String.fromEnvironment('TRADEX_BASE_URL', defaultValue: 'https://<replit-dev-domain>/api/v1')`.

**How to apply:** When running or building the Flutter app, pass the correct backend URL:
```bash
flutter run --dart-define=TRADEX_BASE_URL=https://<replit-domain>/api/v1
flutter build apk --dart-define=TRADEX_BASE_URL=https://api.tradex.ps/v1
```

The Replit dev domain changes per session — update the default in `app_config.dart` if you need it to work without a dart-define flag.
