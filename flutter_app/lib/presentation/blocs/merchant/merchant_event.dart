part of 'merchant_bloc.dart';

abstract class MerchantEvent extends Equatable {
  const MerchantEvent();

  @override
  List<Object?> get props => [];
}

/// Upload a store logo image (POST /stores/me/logo).
/// [filePath] — absolute path returned by the image picker.
class MerchantLogoUploadRequested extends MerchantEvent {
  const MerchantLogoUploadRequested({required this.filePath});

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

/// Create or update the merchant's store profile (PUT /stores/me).
class MerchantStoreSetupRequested extends MerchantEvent {
  const MerchantStoreSetupRequested({
    required this.storeName,
    this.description,
    this.city,
    this.category,
  });

  final String storeName;
  final String? description;
  final String? city;
  final String? category;

  @override
  List<Object?> get props => [storeName, description, city, category];
}
