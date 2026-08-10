import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_exception.dart';

void main() {
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
}