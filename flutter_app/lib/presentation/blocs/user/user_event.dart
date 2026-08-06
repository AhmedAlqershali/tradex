import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
}

class UserLoadRequested extends UserEvent {
  const UserLoadRequested();

  @override
  List<Object?> get props => [];
}

class UserUpdateRequested extends UserEvent {
  const UserUpdateRequested({
    this.name,
    this.phone,
    this.city,
  });

  final String? name;
  final String? phone;
  final String? city;

  @override
  List<Object?> get props => [name, phone, city];
}

class UserAvatarUploadRequested extends UserEvent {
  const UserAvatarUploadRequested({required this.filePath});

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class UserMerchantProfileCompleted extends UserEvent {
  const UserMerchantProfileCompleted({
    required this.storeName,
    this.storeCategory,
    this.region,
    this.logoPath,
  });

  final String storeName;
  final String? storeCategory;
  final String? region;
  final String? logoPath;

  @override
  List<Object?> get props => [storeName, storeCategory, region, logoPath];
}

class UserProfileUpdated extends UserEvent {
  const UserProfileUpdated({
    this.name,
    this.email,
    this.phone,
    this.region,
    this.photoPath,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? region;
  final String? photoPath;

  @override
  List<Object?> get props => [name, email, phone, region, photoPath];
}
