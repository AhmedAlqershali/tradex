import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/google_sign_in_service.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({GoogleSignInService? googleSignInService})
      : _googleSignInService =
            googleSignInService ?? GoogleSignInService.instance,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthSessionLoaded>(_onSessionLoaded);
  }

  final GoogleSignInService _googleSignInService;

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await UserController.instance.login(
        email: event.email,
        password: event.password,
        role: event.role,
      );
      if (!isClosed) emit(AuthAuthenticated(user: user));
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) {
        emit(const AuthFailure(message: 'حدث خطأ غير متوقع. حاول مجدداً.'));
      }
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final credential = await _googleSignInService.signIn();
      if (credential == null) {
        if (!isClosed) emit(const AuthGoogleSignInCancelled());
        return;
      }

      final user = await UserController.instance.loginWithGoogle(
        credential: credential,
      );
      if (!isClosed) {
        emit(AuthAuthenticated(user: user, isGoogle: true));
      }
    } on GoogleSignInException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AuthFailure(message: _googleApiErrorMessage(e)));
      }
    } catch (_) {
      if (!isClosed) {
        emit(const AuthFailure(
          message: 'تعذر تسجيل الدخول عبر Google. حاول مرة أخرى.',
        ));
      }
    }
  }

  String _googleApiErrorMessage(ApiException error) {
    if (error is ValidationException) {
      final first = error.errors.values.firstOrNull?.firstOrNull;
      return first ?? 'تعذر التحقق من حساب Google. حاول مرة أخرى.';
    }
    if (error is AuthException) {
      return 'بيانات اعتماد Google غير صالحة أو منتهية الصلاحية.';
    }
    if (error is NetworkException) {
      return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';
    }
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    }
    if (error is ServerException && error.statusCode == 503) {
      return 'تسجيل الدخول عبر Google غير مهيأ حالياً. حاول لاحقاً.';
    }
    return error.message;
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await UserController.instance.startRegistration(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
      );
      if (!isClosed) emit(AuthAuthenticated(user: user));
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) {
        emit(const AuthFailure(message: 'حدث خطأ غير متوقع. حاول مجدداً.'));
      }
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await UserController.instance.logout();
      if (!isClosed) emit(const AuthUnauthenticated());
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      // Logout always clears local state in UserController; surface as
      // unauthenticated even when the server call fails.
      if (!isClosed) emit(const AuthUnauthenticated());
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await UserController.instance.forgotPassword(email: event.email);
      if (!isClosed) emit(const AuthOtpSent());
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) {
        emit(const AuthFailure(message: 'حدث خطأ غير متوقع. حاول مجدداً.'));
      }
    }
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await UserController.instance.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      if (!isClosed) emit(const AuthOtpVerified());
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) {
        emit(const AuthFailure(message: 'حدث خطأ غير متوقع. حاول مجدداً.'));
      }
    }
  }

  // ── Reset password ─────────────────────────────────────────────────────────

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await UserController.instance.resetPassword(
        email: event.email,
        otp: event.otp,
        newPassword: event.newPassword,
      );
      if (!isClosed) emit(const AuthPasswordReset());
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.toString()));
    }
  }

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> _onSessionLoaded(
    AuthSessionLoaded event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await UserController.instance.loadSession();
      if (!isClosed) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(AuthFailure(message: e.message));
    } catch (e) {
      if (!isClosed) emit(const AuthUnauthenticated());
    }
  }
}
