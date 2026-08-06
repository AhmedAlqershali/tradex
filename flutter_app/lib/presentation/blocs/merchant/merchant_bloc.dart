import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:ai_saas/shared/users/user_controller.dart';

part 'merchant_event.dart';
part 'merchant_state.dart';

/// Handles merchant-specific operations that are not covered by [StoreBloc]:
///   - Store logo upload (POST /merchant/stores/:id/logo)
///   - Store profile initial setup / update (PUT /merchant/stores/:id)
class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  MerchantBloc() : super(const MerchantInitial()) {
    on<MerchantLogoUploadRequested>(_onLogoUploadRequested);
    on<MerchantStoreSetupRequested>(_onStoreSetupRequested);
  }

  Future<void> _onLogoUploadRequested(
    MerchantLogoUploadRequested event,
    Emitter<MerchantState> emit,
  ) async {
    emit(const MerchantLoading());
    try {
      final storeId = UserController.instance.currentUser?.storeId;
      if (storeId == null || storeId.isEmpty) {
        if (!isClosed) {
          emit(const MerchantFailure('لا يوجد متجر مرتبط بهذا الحساب.'));
        }
        return;
      }
      final logoUrl = await StoreService.instance.uploadStoreLogo(
        storeId: storeId,
        filePath: event.filePath,
      );
      if (!isClosed) emit(MerchantLogoUploaded(logoUrl));
    } on ApiException catch (e) {
      if (!isClosed) emit(MerchantFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(MerchantFailure(e.toString()));
    }
  }

  Future<void> _onStoreSetupRequested(
    MerchantStoreSetupRequested event,
    Emitter<MerchantState> emit,
  ) async {
    emit(const MerchantLoading());
    try {
      final storeId = UserController.instance.currentUser?.storeId;
      if (storeId == null || storeId.isEmpty) {
        if (!isClosed) {
          emit(const MerchantFailure('لا يوجد متجر مرتبط بهذا الحساب.'));
        }
        return;
      }
      // Backend store record has no city/category fields — event.city and
      // event.category are intentionally not sent.
      final store = await StoreService.instance.updateMyStore(
        storeId: storeId,
        name: event.storeName,
        description: event.description,
      );
      if (!isClosed) emit(MerchantStoreSetupComplete(store));
    } on ApiException catch (e) {
      if (!isClosed) emit(MerchantFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(MerchantFailure(e.toString()));
    }
  }
}
