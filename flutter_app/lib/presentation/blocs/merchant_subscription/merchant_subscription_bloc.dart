import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/merchant_subscription_service.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';

part 'merchant_subscription_event.dart';
part 'merchant_subscription_state.dart';

class MerchantSubscriptionBloc
    extends Bloc<MerchantSubscriptionEvent, MerchantSubscriptionState> {
  MerchantSubscriptionBloc({
    Future<AdminSubscription?> Function()? loadSubscription,
  })  : _loadSubscription = loadSubscription ??
            MerchantSubscriptionService.instance.getCurrentSubscription,
        super(const MerchantSubscriptionInitial()) {
    on<MerchantSubscriptionLoadRequested>(_onLoadRequested);
  }

  final Future<AdminSubscription?> Function() _loadSubscription;

  Future<void> _onLoadRequested(
    MerchantSubscriptionLoadRequested event,
    Emitter<MerchantSubscriptionState> emit,
  ) async {
    emit(const MerchantSubscriptionLoading());
    try {
      final subscription = await _loadSubscription();
      if (!isClosed) emit(MerchantSubscriptionLoaded(subscription));
    } on ApiException catch (e) {
      if (!isClosed) emit(MerchantSubscriptionFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(MerchantSubscriptionFailure(e.toString()));
    }
  }
}
