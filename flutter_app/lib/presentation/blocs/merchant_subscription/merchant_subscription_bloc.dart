import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/merchant_subscription_service.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';

part 'merchant_subscription_event.dart';
part 'merchant_subscription_state.dart';

class MerchantSubscriptionBloc
    extends Bloc<MerchantSubscriptionEvent, MerchantSubscriptionState> {
  MerchantSubscriptionBloc({
    Future<AdminSubscription?> Function()? loadSubscription,
    Future<List<AdminSubscriptionRequest>> Function()? loadRequests,
    Future<AdminSubscriptionRequest> Function(String id)? loadRequestDetails,
    Future<AdminSubscriptionRequest> Function({
      required int planId,
      required String billingCycle,
      required String fullName,
      required String phone,
      required String paymentMethod,
      required XFile paymentProof,
      String? notes,
    })? submitRequest,
  })  : _loadSubscription = loadSubscription ??
            MerchantSubscriptionService.instance.getCurrentSubscription,
        _loadRequests =
            loadRequests ?? MerchantSubscriptionService.instance.listRequests,
        _loadRequestDetails = loadRequestDetails ??
            MerchantSubscriptionService.instance.getRequest,
        _submitRequest =
            submitRequest ?? MerchantSubscriptionService.instance.submitRequest,
        super(const MerchantSubscriptionInitial()) {
    on<MerchantSubscriptionLoadRequested>(_onLoadRequested);
    on<MerchantSubscriptionRequestsLoadRequested>(_onRequestsLoadRequested);
    on<MerchantSubscriptionRequestDetailsRequested>(_onDetailsRequested);
    on<MerchantSubscriptionRequestSubmitRequested>(_onSubmitRequested);
  }

  final Future<AdminSubscription?> Function() _loadSubscription;
  final Future<List<AdminSubscriptionRequest>> Function() _loadRequests;
  final Future<AdminSubscriptionRequest> Function(String id)
      _loadRequestDetails;
  final Future<AdminSubscriptionRequest> Function({
    required int planId,
    required String billingCycle,
    required String fullName,
    required String phone,
    required String paymentMethod,
    required XFile paymentProof,
    String? notes,
  }) _submitRequest;

  AdminSubscription? _subscription;
  List<AdminSubscriptionRequest> _requests = const [];
  AdminSubscriptionRequest? _selectedRequest;

  Future<void> _onLoadRequested(
    MerchantSubscriptionLoadRequested event,
    Emitter<MerchantSubscriptionState> emit,
  ) async {
    emit(const MerchantSubscriptionLoading());
    try {
      final subscription = await _loadSubscription();
      _subscription = subscription;
      if (!isClosed) {
        emit(MerchantSubscriptionLoaded(
          subscription,
          requests: _requests,
          selectedRequest: _selectedRequest,
        ));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(MerchantSubscriptionFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(MerchantSubscriptionFailure(e.toString()));
    }
  }

  Future<void> _onRequestsLoadRequested(
    MerchantSubscriptionRequestsLoadRequested event,
    Emitter<MerchantSubscriptionState> emit,
  ) async {
    emit(MerchantSubscriptionLoaded(
      _subscription,
      requests: _requests,
      requestsLoading: true,
      selectedRequest: _selectedRequest,
    ));
    try {
      _requests = await _loadRequests();
      if (!isClosed) {
        emit(MerchantSubscriptionLoaded(
          _subscription,
          requests: _requests,
          selectedRequest: _selectedRequest,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onDetailsRequested(
    MerchantSubscriptionRequestDetailsRequested event,
    Emitter<MerchantSubscriptionState> emit,
  ) async {
    emit(MerchantSubscriptionLoaded(
      _subscription,
      requests: _requests,
      selectedRequest: _selectedRequest,
      detailsLoading: true,
    ));
    try {
      _selectedRequest = await _loadRequestDetails(event.id);
      if (!isClosed) {
        emit(MerchantSubscriptionLoaded(
          _subscription,
          requests: _requests,
          selectedRequest: _selectedRequest,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onSubmitRequested(
    MerchantSubscriptionRequestSubmitRequested event,
    Emitter<MerchantSubscriptionState> emit,
  ) async {
    emit(MerchantSubscriptionLoaded(
      _subscription,
      requests: _requests,
      selectedRequest: _selectedRequest,
      submitting: true,
    ));
    try {
      final request = await _submitRequest(
        planId: event.planId,
        billingCycle: event.billingCycle,
        fullName: event.fullName,
        phone: event.phone,
        paymentMethod: event.paymentMethod,
        paymentProof: event.paymentProof,
        notes: event.notes,
      );
      _requests = [
        request,
        ..._requests.where((item) => item.id != request.id),
      ];
      if (!isClosed) {
        emit(MerchantSubscriptionLoaded(
          _subscription,
          requests: _requests,
          selectedRequest: request,
          submissionMessage:
              'تم إرسال طلب الاشتراك بنجاح، وسيتم مراجعته من الإدارة.',
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message);
    } catch (e) {
      _emitFailure(emit, e.toString());
    }
  }

  void _emitFailure(
    Emitter<MerchantSubscriptionState> emit,
    String message,
  ) {
    if (!isClosed) {
      emit(MerchantSubscriptionFailure(
        message,
        subscription: _subscription,
        requests: _requests,
        selectedRequest: _selectedRequest,
      ));
    }
  }
}
