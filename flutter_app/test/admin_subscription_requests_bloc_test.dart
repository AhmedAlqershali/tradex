import 'package:ai_saas/presentation/blocs/admin_subscription_requests/admin_subscription_requests_bloc.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

AdminSubscriptionRequest _request(String status) =>
    AdminSubscriptionRequest.fromJson({
      'id': 7,
      'full_name': 'Merchant',
      'phone': '0501234567',
      'payment_method': 'bank_transfer',
      'billing_cycle': 'monthly',
      'status': status,
    });

AdminSubscriptionRequestPage _page(String status) =>
    AdminSubscriptionRequestPage(
      requests: [_request(status)],
      pagination: const AdminSubscriptionRequestPagination(
        total: 1,
        perPage: 15,
        currentPage: 1,
        lastPage: 1,
      ),
    );

void main() {
  test('loads pending requests and completes approval with updated state',
      () async {
    final bloc = AdminSubscriptionRequestsBloc(
      listRequests: ({
        String? status,
        int page = 1,
        int perPage = 15,
      }) async =>
          _page('pending'),
      getRequest: (id) async => _request('pending'),
      approve: (id) async => _request('approved'),
    );
    addTearDown(bloc.close);

    bloc.add(const AdminSubscriptionRequestsLoadRequested());
    await expectLater(
        bloc.stream, emitsThrough(isA<AdminSubscriptionRequestsLoaded>()));

    bloc.add(const AdminSubscriptionRequestDetailsRequested('7'));
    await expectLater(
      bloc.stream,
      emitsThrough(
        isA<AdminSubscriptionRequestsLoaded>().having(
          (state) => state.selectedRequest?.status,
          'selected status',
          'pending',
        ),
      ),
    );

    bloc.add(const AdminSubscriptionRequestApproveRequested('7'));
    await expectLater(
      bloc.stream,
      emitsThrough(
        isA<AdminSubscriptionRequestsLoaded>().having(
          (state) => state.selectedRequest?.status,
          'approved status',
          'approved',
        ),
      ),
    );
  });

  test('exposes request loading failures', () async {
    final bloc = AdminSubscriptionRequestsBloc(
      listRequests: ({
        String? status,
        int page = 1,
        int perPage = 15,
      }) async =>
          throw Exception('request list unavailable'),
    );
    addTearDown(bloc.close);

    bloc.add(const AdminSubscriptionRequestsLoadRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminSubscriptionRequestsLoading>(),
        isA<AdminSubscriptionRequestsFailure>().having(
          (state) => state.message,
          'message',
          contains('request list unavailable'),
        ),
      ]),
    );
  });
}
