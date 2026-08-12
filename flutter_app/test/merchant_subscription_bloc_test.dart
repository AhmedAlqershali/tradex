import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_saas/presentation/blocs/merchant_subscription/merchant_subscription_bloc.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';
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

AdminPlan _plan() {
  return AdminPlan.fromJson({
    'id': 2,
    'name': 'pro',
    'display_name': 'Pro Plan',
    'monthly_price': 19.99,
    'yearly_price': 199.99,
    'product_limit': 100,
    'store_limit': 1,
    'features': ['AI tools'],
    'status': 'active',
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

  test('refreshes expired state to active after a server-side renewal',
      () async {
    var renewed = false;
    var entitlementRefreshes = 0;
    final bloc = MerchantSubscriptionBloc(
      loadSubscription: () async => AdminSubscription.fromJson({
        'id': 7,
        'plan': {'display_name': 'Pro'},
        'billing_cycle': 'monthly',
        'type': renewed ? 'paid' : 'trial',
        'is_trial': !renewed,
        'status': renewed ? 'active' : 'expired',
        'is_entitled': renewed,
        'ends_at': renewed ? '2026-09-20T00:00:00Z' : '2026-08-01T00:00:00Z',
      }),
      loadRequests: () async => const [],
      refreshCurrentUser: () async {
        entitlementRefreshes++;
      },
    );

    bloc.add(const MerchantSubscriptionLoadRequested());
    await expectLater(
      bloc.stream,
      emitsThrough(isA<MerchantSubscriptionLoaded>().having(
        (state) => state.subscription?.isEntitled,
        'expired entitlement',
        false,
      )),
    );

    renewed = true;
    bloc.add(const MerchantSubscriptionRefreshRequested());
    await expectLater(
      bloc.stream,
      emitsThrough(isA<MerchantSubscriptionLoaded>().having(
        (state) => state.subscription?.isEntitled,
        'renewed entitlement',
        true,
      )),
    );

    expect(entitlementRefreshes, 2);
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

  test('loads available active merchant subscription plans', () async {
    final plan = _plan();
    final bloc = MerchantSubscriptionBloc(
      loadPlans: () async => [plan],
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantSubscriptionLoaded>().having(
          (state) => state.plansLoading,
          'plans loading',
          true,
        ),
        isA<MerchantSubscriptionLoaded>()
            .having((state) => state.plans.single.id, 'plan id', '2')
            .having((state) => state.plans.single.displayName, 'plan name',
                'Pro Plan'),
      ]),
    );

    bloc.add(const MerchantSubscriptionPlansLoadRequested());
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
