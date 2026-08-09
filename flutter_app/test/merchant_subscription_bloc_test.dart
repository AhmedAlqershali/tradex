import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/presentation/blocs/merchant_subscription/merchant_subscription_bloc.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';

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
}
