// ─── AppConfig ────────────────────────────────────────────────────────────────
//
// Single source of truth for environment-specific configuration.
//
// Usage:
//   flutter run  --dart-define=TRADEX_BASE_URL=http://192.168.1.100/api/v1
//   flutter build apk --dart-define=TRADEX_BASE_URL=https://api.tradex.ps/v1
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
  // The default points to this Replit development server so the app works
  // out of the box in this environment without extra build flags.
  static const String baseUrl = String.fromEnvironment(
    'TRADEX_BASE_URL',
    defaultValue: 'https://ff165008-2154-4c2f-8178-3dc0b1cfc493-00-2n43d3gdvzyud.sisko.replit.dev/api/v1',
  );

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
