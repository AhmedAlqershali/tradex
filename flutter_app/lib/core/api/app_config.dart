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

  /// Resolves media paths returned by the API without coupling the UI to a
  /// deployment hostname. The API normally returns an absolute Storage URL,
  /// but older environments may return a root-relative path.
  static String resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final apiUri = Uri.parse(baseUrl);
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
      // Local Laravel development commonly generates http://localhost URLs
      // from APP_URL. Those URLs are not reachable by a device or the
      // proxied Replit preview, so keep the returned path but use the same
      // origin as the configured API.
      if (parsed.host != 'localhost' &&
          parsed.host != '127.0.0.1' &&
          parsed.host != '0.0.0.0') {
        return trimmed;
      }

      final localPath = parsed.path.isEmpty ? '/' : parsed.path;
      return apiUri.replace(path: '', query: null, fragment: null).toString() +
          localPath +
          (parsed.hasQuery ? '?${parsed.query}' : '');
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return apiUri.replace(path: '', query: null, fragment: null).toString() +
        path;
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
