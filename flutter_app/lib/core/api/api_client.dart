import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/storage/secure_storage_service.dart';

// ─── ApiClient ────────────────────────────────────────────────────────────────
//
// Singleton Dio instance. All service files use [ApiClient.instance] to make
// HTTP calls — never create a Dio object elsewhere.
//
// Interceptor order:
//   1. AuthInterceptor  — adds Bearer token header; handles 401 refresh.
//   2. LogInterceptor   — prints request/response in debug mode only.
//
// Error handling:
//   Every DioException is converted to a typed [ApiException] subclass so
//   controllers and screens never have to import Dio.
// ─────────────────────────────────────────────────────────────────────────────

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout:    ApiConstants.sendTimeout,
        headers: {
          'Accept':       'application/json',
          'Content-Type': 'application/json',
        },
      ),
    )
      ..interceptors.add(_authInterceptor())
      ..interceptors.add(_logInterceptor());
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  // ── Public HTTP helpers ───────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.get<T>(path,
          queryParameters: queryParameters, options: options));

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options));

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _wrap(() => _dio.put<T>(path, data: data, options: options));

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _wrap(() => _dio.patch<T>(path, data: data, options: options));

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _wrap(() => _dio.delete<T>(path, data: data, options: options));

  Future<Response<T>> postFormData<T>(
    String path,
    FormData formData,
  ) =>
      _wrap(() => _dio.post<T>(
            path,
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          ));

  // ── Error wrapper ─────────────────────────────────────────────────────────────

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw const UnknownException();
    }
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status == 401) return const AuthException();
        final body = e.response?.data;
        final message = (body is Map ? body['message'] as String? : null) ??
            'خطأ في الخادم ($status)';
        if (status == 422) {
          final errors = _parseValidationErrors(body);
          return ValidationException(message, errors: errors);
        }
        return ServerException(message, statusCode: status);

      default:
        return const UnknownException();
    }
  }

  Map<String, List<String>> _parseValidationErrors(dynamic body) {
    if (body is! Map) return {};
    final raw = body['errors'];
    if (raw is! Map) return {};
    return raw.map(
      (k, v) => MapEntry(
        k.toString(),
        (v is List ? v : [v]).map((e) => e.toString()).toList(),
      ),
    );
  }

  // ── Auth interceptor ──────────────────────────────────────────────────────────

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token =
            await SecureStorageService.instance.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // The backend (Laravel Sanctum) does not expose a refresh-token
        // endpoint — a token is valid until it is explicitly revoked
        // (logout) or expires server-side. A 401 therefore means the
        // session is no longer valid; clear it and let the app route back
        // to login rather than attempting to refresh.
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }
        await _clearSession();
        return handler.next(error);
      },
    );
  }

  // ── Session-expired callback ──────────────────────────────────────────────────
  // Registered from main.dart to avoid a circular import between ApiClient and
  // UserController. When the 401 refresh fails this fires so the app can clear
  // state and redirect to login without ApiClient importing UserController.

  static void Function()? _onSessionExpired;

  /// Register a callback to invoke when a 401 cannot be recovered via refresh.
  /// Call once from main() before runApp.
  static void setSessionExpiredCallback(void Function() callback) {
    _onSessionExpired = callback;
  }

  Future<void> _clearSession() async {
    await SecureStorageService.instance.clearAll();
    _onSessionExpired?.call();
  }

  // ── Log interceptor (debug only) ──────────────────────────────────────────────

  Interceptor _logInterceptor() {
    return LogInterceptor(
      request:         kDebugMode,
      // Request bodies can contain passwords and password-reset tokens.
      // Never log them, even in debug builds.
      requestBody:     false,
      responseBody:    kDebugMode,
      responseHeader:  false,
      requestHeader:   false,
      error:           true,
      // ignore: avoid_print
      logPrint: (obj) { if (kDebugMode) debugPrint(obj.toString()); },
    );
  }
}
