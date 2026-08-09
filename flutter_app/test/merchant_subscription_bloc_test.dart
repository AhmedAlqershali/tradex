import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_saas/presentation/blocs/merchant_subscription/merchant_subscription_bloc.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';

AdminSubscription _subscription() {
  return AdminSubscription.fromJson({
    'id': 7,
    'plan': {'display_name': 'Pro'},
    'billing_cycle': 'monthly',
    'type': 'trial',
    'is_trial': true,
    'status': 'active',
    'is_entitled': true,
    'ends_at': '2026-08-20T00:00:00Z',
  });
}

AdminSubscriptionRequest _request() {
  return AdminSubscriptionRequest.fromJson({
    'id': 9,
    'plan': {'id': 2, 'display_name': 'Pro'},
    'billing_cycle': 'monthly',
    'full_name': 'Ahmed Ali',
    'phone': '0501234567',
    'payment_method': 'bank_transfer',
    'status': 'pending',
  });
}

void main() {
  test('loads the merchant current subscription', () async {
    final bloc = MerchantSubscriptionBloc(
      loadSubscription: () async => _subscription(),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantSubscriptionLoading>(),
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.subscription?.isTrial,
          'trial status',
          true,
        ),
      ]),
    );

    bloc.add(const MerchantSubscriptionLoadRequested());
    await states;
    await bloc.close();
  });

  test('represents a merchant without a current subscription', () async {
    final bloc = MerchantSubscriptionBloc(
      loadSubscription: () async => null,
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantSubscriptionLoading>(),
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.subscription,
          'subscription',
          isNull,
        ),
      ]),
    );

    bloc.add(const MerchantSubscriptionLoadRequested());
    await states;
    await bloc.close();
  });

  test('loads the merchant subscription request history', () async {
    final request = _request();
    final bloc = MerchantSubscriptionBloc(
      loadRequests: () async => [request],
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.requestsLoading,
          'history loading',
          true,
        ),
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.requests.single.id,
          'request id',
          '9',
        ),
      ]),
    );

    bloc.add(const MerchantSubscriptionRequestsLoadRequested());
    await states;
    await bloc.close();
  });

  test('submits a request and exposes success state', () async {
    final request = _request();
    final bloc = MerchantSubscriptionBloc(
      submitRequest: ({
        required int planId,
        required String billingCycle,
        required String fullName,
        required String phone,
        required String paymentMethod,
        required XFile paymentProof,
        String? notes,
      }) async {
        expect(planId, 2);
        expect(billingCycle, 'monthly');
        expect(fullName, 'Ahmed Ali');
        expect(paymentProof.name, 'proof.jpg');
        return request;
      },
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.submitting,
          'submission loading',
          true,
        ),
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.submissionMessage,
          'submission message',
          isNotNull,
        ),
      ]),
    );

    bloc.add(MerchantSubscriptionRequestSubmitRequested(
      planId: 2,
      billingCycle: 'monthly',
      fullName: 'Ahmed Ali',
      phone: '0501234567',
      paymentMethod: 'bank_transfer',
      paymentProof: XFile('proof.jpg'),
    ));
    await states;
    await bloc.close();
  });
}
