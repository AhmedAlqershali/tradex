import 'package:equatable/equatable.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:ai_saas/models/app_type.dart';

abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  List<Object?> get props => [];
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after a successful forgot-password request (OTP sent to email).
class AuthOtpSent extends AuthState {
  const AuthOtpSent();

  @override
  List<Object?> get props => [];
}

/// Emitted after a successful OTP verification.
class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();

  @override
  List<Object?> get props => [];
}

/// Emitted when registration is successful but email verification is required.
class AuthAwaitingEmailVerification extends AuthState {
  const AuthAwaitingEmailVerification({required this.user, required this.role});

  final AppUser user;
  final AppType role;

  @override
  List<Object?> get props => [user, role];
}

/// Emitted after a successful password reset.
class AuthPasswordReset extends AuthState {
  const AuthPasswordReset();

  @override
  List<Object?> get props => [];
}
