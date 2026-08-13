import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'user_event.dart';
import 'user_state.dart';

export 'user_event.dart';
export 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserInitial()) {
    on<UserLoadRequested>(_onLoadRequested);
    on<UserUpdateRequested>(_onUpdateRequested);
    on<UserAvatarUploadRequested>(_onAvatarUploadRequested);
    on<UserMerchantProfileCompleted>(_onMerchantProfileCompleted);
    on<UserProfileUpdated>(_onProfileUpdated);
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    UserLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = UserController.instance.currentUser;
    if (current == null) {
      emit(const UserFailure(message: 'لا يوجد مستخدم مسجل الدخول.'));
      return;
    }

    try {
      // Profile is server-authoritative. Refresh it so avatar state always
      // comes from Laravel rather than a stale/local client value.
      final user = await UserController.instance.refreshProfileIfCurrent();
      if (user != null && !isClosed) emit(UserLoaded(user: user));
    } on ApiException catch (e) {
      if (!isClosed) emit(UserFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(UserFailure(message: e.toString()));
    }
  }

  // ── Update (generic fields) ────────────────────────────────────────────────

  Future<void> _onUpdateRequested(
    UserUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = UserController.instance.currentUser;
    if (current == null) {
      emit(const UserFailure(message: 'لا يوجد مستخدم مسجل الدخول.'));
      return;
    }
    emit(UserUpdating(user: current));
    try {
      await UserController.instance.updateProfile(
        name: event.name,
        phone: event.phone,
      );
      final updated = UserController.instance.currentUser;
      if (!isClosed) {
        emit(UserLoaded(user: updated ?? current));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(UserFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(UserFailure(message: e.toString()));
    }
  }

  // ── Avatar upload ──────────────────────────────────────────────────────────

  Future<void> _onAvatarUploadRequested(
    UserAvatarUploadRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = UserController.instance.currentUser;
    if (current == null) {
      emit(const UserFailure(message: 'لا يوجد مستخدم مسجل الدخول.'));
      return;
    }
    emit(UserUpdating(user: current));
    try {
      await UserController.instance.updateProfile(photoPath: event.filePath);
      final updated = UserController.instance.currentUser;
      if (!isClosed) {
        emit(UserLoaded(user: updated ?? current));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(UserFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(UserFailure(message: e.toString()));
    }
  }

  // ── Merchant profile completion ────────────────────────────────────────────

  Future<void> _onMerchantProfileCompleted(
    UserMerchantProfileCompleted event,
    Emitter<UserState> emit,
  ) async {
    final current = UserController.instance.currentUser;
    if (current != null) emit(UserUpdating(user: current));
    try {
      await UserController.instance.completeMerchantProfile(
        storeName: event.storeName,
        storeCategory: event.storeCategory,
        region: event.region,
        logoPath: event.logoPath,
      );
      final updated = UserController.instance.currentUser;
      if (!isClosed && updated != null) {
        emit(UserLoaded(user: updated));
      } else if (!isClosed) {
        emit(const UserFailure(message: 'فشل تحديث ملف التاجر.'));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(UserFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(UserFailure(message: e.toString()));
    }
  }

  // ── Full profile update ────────────────────────────────────────────────────

  Future<void> _onProfileUpdated(
    UserProfileUpdated event,
    Emitter<UserState> emit,
  ) async {
    final current = UserController.instance.currentUser;
    if (current == null) {
      emit(const UserFailure(message: 'لا يوجد مستخدم مسجل الدخول.'));
      return;
    }
    emit(UserUpdating(user: current));
    try {
      await UserController.instance.updateProfile(
        name: event.name,
        email: event.email,
        phone: event.phone,
        region: event.region,
        photoPath: event.photoPath,
      );
      final updated = UserController.instance.currentUser;
      if (!isClosed) {
        emit(UserLoaded(user: updated ?? current));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(UserFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(UserFailure(message: e.toString()));
    }
  }
}
