import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:ai_saas/shared/users/user_controller.dart';

part 'store_event.dart';
part 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  StoreBloc() : super(const StoreInitial()) {
    on<StoresLoadRequested>(_onStoresLoadRequested);
    on<StoreByIdRequested>(_onStoreByIdRequested);
    on<MyStoreLoadRequested>(_onMyStoreLoadRequested);
    on<MyStoreUpdateRequested>(_onMyStoreUpdateRequested);
    on<StoreLogoUploadRequested>(_onStoreLogoUploadRequested);
    on<StoreProductsLoadRequested>(_onStoreProductsLoadRequested);
  }

  Future<void> _onStoresLoadRequested(
    StoresLoadRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final stores = await StoreService.instance.getAllStores();
      emit(StoresLoaded(stores));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }

  Future<void> _onStoreByIdRequested(
    StoreByIdRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final store = await StoreService.instance.getStoreById(event.id);
      emit(StoreDetailLoaded(store));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }

  Future<void> _onMyStoreLoadRequested(
    MyStoreLoadRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final store = await StoreService.instance.getMyStore();
      emit(MyStoreLoaded(store));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }

  Future<void> _onMyStoreUpdateRequested(
    MyStoreUpdateRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final storeId = UserController.instance.currentUser?.storeId;
      if (storeId == null || storeId.isEmpty) {
        emit(const StoreFailure('لا يوجد متجر مرتبط بهذا الحساب.'));
        return;
      }
      final store = await StoreService.instance.updateMyStore(
        storeId: storeId,
        name: event.name,
        description: event.description,
        phone: event.phone,
      );
      emit(StoreUpdated(store));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }

  Future<void> _onStoreLogoUploadRequested(
    StoreLogoUploadRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final storeId = UserController.instance.currentUser?.storeId;
      if (storeId == null || storeId.isEmpty) {
        emit(const StoreFailure('لا يوجد متجر مرتبط بهذا الحساب.'));
        return;
      }
      await StoreService.instance.uploadStoreLogo(
        storeId: storeId,
        filePath: event.filePath,
      );
      // Reload so MyStoreLoaded carries the fresh logo URL from the server.
      final store = await StoreService.instance.getMyStore();
      emit(MyStoreLoaded(store));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }

  Future<void> _onStoreProductsLoadRequested(
    StoreProductsLoadRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final products =
          await StoreService.instance.getStoreProducts(event.storeId);
      emit(StoreProductsLoaded(products, event.storeId));
    } on ApiException catch (e) {
      emit(StoreFailure(e.message));
    }
  }
}
