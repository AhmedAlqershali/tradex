// ─── ApiException ─────────────────────────────────────────────────────────────
//
// Typed exception hierarchy for every failure that can come from the network
// layer. Controllers catch [ApiException] and expose the [message] to the UI
// via their error notifiers — screens never import Dio directly.
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all Tradex API errors.
sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

// ── Concrete subtypes ─────────────────────────────────────────────────────────

/// The device has no internet connection or the host is unreachable.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.',
  ]);
}

/// The request timed out before a response arrived.
final class TimeoutException extends ApiException {
  const TimeoutException([
    super.message = 'انتهت مهلة الطلب. حاول مجدداً.',
  ]);
}

/// The server returned an HTTP 4xx or 5xx status code.
final class ServerException extends ApiException {
  const ServerException(super.message, {required this.statusCode});
  final int statusCode;

  @override
  String toString() => 'ServerException[$statusCode]: $message';
}

/// The stored token is missing or expired and the refresh also failed.
/// Controllers should call [UserController.logout()] when they catch this.
final class AuthException extends ApiException {
  const AuthException([
    super.message = 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.',
  ]);
}

/// The client sent a malformed request (HTTP 422 / validation failure).
final class ValidationException extends ApiException {
  const ValidationException(super.message, {this.errors = const {}});
  final Map<String, List<String>> errors;
}

/// An unexpected error that does not fit any of the above categories.
final class UnknownException extends ApiException {
  const UnknownException([
    super.message = 'حدث خطأ غير متوقع. حاول مجدداً.',
  ]);
}
