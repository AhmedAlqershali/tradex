import 'package:equatable/equatable.dart';
import 'package:ai_saas/models/app_type.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final AppType role;

  @override
  List<Object?> get props => [email, password, role];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final AppType role;

  @override
  List<Object?> get props => [name, email, phone, password, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();

  @override
  List<Object?> get props => [];
}

class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOtpRequested extends AuthEvent {
  const AuthVerifyOtpRequested({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  @override
  List<Object?> get props => [email, otp, newPassword];
}

/// Triggers [UserController.loadSession()] — call on app start.
class AuthSessionLoaded extends AuthEvent {
  const AuthSessionLoaded();

  @override
  List<Object?> get props => [];
}
