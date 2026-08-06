import 'package:equatable/equatable.dart';
import 'package:ai_saas/shared/users/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();
}

class UserInitial extends UserState {
  const UserInitial();

  @override
  List<Object?> get props => [];
}

class UserLoading extends UserState {
  const UserLoading();

  @override
  List<Object?> get props => [];
}

class UserLoaded extends UserState {
  const UserLoaded({required this.user});

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// Emitted while a profile mutation is in progress; carries the current user
/// so the UI can show the existing data without resetting to a loading skeleton.
class UserUpdating extends UserState {
  const UserUpdating({required this.user});

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class UserFailure extends UserState {
  const UserFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
