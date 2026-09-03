// ─── AppConfig ────────────────────────────────────────────────────────────────
//
// Single source of truth for environment-specific configuration.
//
// Usage:
//   flutter run  --dart-define=TRADEX_BASE_URL=http://192.168.1.100/api/v1
//   flutter build apk --dart-define=TRADEX_BASE_URL=https://api.tradex.ps/api/v1
//
// When no --dart-define is passed, the production URL is used as the default
// so the release build is always production-ready without extra steps.
//
// Changing one URL here activates the entire application:
//   ApiClient reads ApiConstants.baseUrl
//   ApiConstants.baseUrl reads AppConfig.baseUrl
//   AppConfig.baseUrl reads the --dart-define value at compile time.
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  AppConfig._();

  // ── Base URL ──────────────────────────────────────────────────────────────────
  // Override at build time:
  //   --dart-define=TRADEX_BASE_URL=https://your-domain.com/api/v1
  // The default is the documented production API. Override this at build time
  // with TRADEX_BASE_URL for development or staging.
  static const String baseUrl = String.fromEnvironment(
    'TRADEX_BASE_URL',
    defaultValue: 'https://tradex-v2us.onrender.com/api/v1',
  );

  static String get mediaBaseUrl {
    final apiUri = Uri.parse(baseUrl);
    final scheme = apiUri.scheme.isEmpty ? 'https' : apiUri.scheme;
    final host = apiUri.host.isEmpty ? 'tradex-v2us.onrender.com' : apiUri.host;
    final port = apiUri.hasPort ? ':${apiUri.port}' : '';
    return '$scheme://$host$port';
  }

  static String _normalizeStoragePath(String value) {
    var path = value.trim();
    path = path.replaceAll(RegExp(r'^https?://[^/]+', caseSensitive: false), '');
    path = path.replaceAll(RegExp(r'^/+'), '');
    path = path.replaceAll(RegExp(r'^(?:api/v1/)?storage/', caseSensitive: false), '');
    path = path.replaceAll(RegExp(r'^/+'), '');
    if (path.isEmpty) return 'storage';
    return 'storage/$path';
  }

  /// Resolves media paths returned by the API without coupling the UI to a
  /// deployment hostname. The API normally returns an absolute Storage URL,
  /// but older environments may return a root-relative path.
  static String resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      return trimmed;
    }

    final normalizedPath = _normalizeStoragePath(trimmed);
    final mediaUri = Uri.parse(mediaBaseUrl);
    return mediaUri.replace(path: '/$normalizedPath', query: null, fragment: null).toString();
  }

  // ── Environment helpers ───────────────────────────────────────────────────────
  // Compile-time flag — true only in release/profile builds.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // Developer shorthand — set at build time to override release detection.
  // Example: --dart-define=TRADEX_ENV=development
  static const String _envOverride = String.fromEnvironment(
    'TRADEX_ENV',
    defaultValue: '',
  );

  static bool get isDevelopment =>
      _envOverride == 'development' || (!isProduction && _envOverride.isEmpty);

  static bool get isStaging => _envOverride == 'staging';

  /// Human-readable label shown in debug logs.
  static String get environmentLabel {
    if (_envOverride.isNotEmpty) return _envOverride;
    return isProduction ? 'production' : 'development';
  }
}
