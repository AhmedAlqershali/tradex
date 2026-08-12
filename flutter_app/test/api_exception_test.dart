import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_exception.dart';

void main() {
  test('network logger never logs request or response bodies', () {
    final logger = ApiClient.logInterceptorForTesting() as LogInterceptor;

    expect(logger.request, isFalse);
    expect(logger.requestHeader, isFalse);
    expect(logger.requestBody, isFalse);
    expect(logger.responseHeader, isFalse);
    expect(logger.responseBody, isFalse);
    expect(logger.error, isFalse);
  });

  test('maps a Laravel 403 response to ForbiddenException', () {
    final exception = ApiClient.mapDioExceptionForTesting(
      DioException(
        requestOptions: RequestOptions(path: '/merchant/products/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/merchant/products/1'),
          statusCode: 403,
          data: <String, dynamic>{
            'success': false,
            'message': 'Forbidden. You do not have permission.',
            'data': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(exception, isA<ForbiddenException>());
    expect(exception.message, 'Forbidden. You do not have permission.');
  });

  test('preserves Laravel subscription denial as a typed 403', () {
    final exception = ApiClient.mapDioExceptionForTesting(
      DioException(
        requestOptions: RequestOptions(path: '/ai/product-description'),
        response: Response(
          requestOptions: RequestOptions(path: '/ai/product-description'),
          statusCode: 403,
          data: <String, dynamic>{
            'success': false,
            'message':
                'An active trial or paid subscription is required to access merchant business features.',
            'data': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(exception, isA<ForbiddenException>());
    expect(
      exception.message,
      contains('active trial or paid subscription'),
    );
  });

  test('maps an avatar validation failure to a typed 422 exception', () {
    final exception = ApiClient.mapDioExceptionForTesting(
      DioException(
        requestOptions: RequestOptions(path: '/profile/avatar'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/avatar'),
          statusCode: 422,
          data: <String, dynamic>{
            'success': false,
            'message': 'The avatar must be an image.',
            'errors': <String, dynamic>{
              'avatar': <String>['The avatar must be an image.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(exception, isA<ValidationException>());
    expect(exception.message, 'The avatar must be an image.');
    expect(
      (exception as ValidationException).errors['avatar'],
      contains('The avatar must be an image.'),
    );
  });
}
