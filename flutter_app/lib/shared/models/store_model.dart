import 'package:ai_saas/core/api/app_config.dart';

/// Represents a store in the Tradex catalog.
///
/// Kept lean for the local-only phase.
/// Migration path:
///   - Populate [id] from the server merchant profile when auth is added.
///   - [location] and [hours] will map to server address/schedule fields.
class StoreModel {
  /// Unique store identifier.
  /// Matches [Product.storeId] for store → product lookup.
  final String? id;

  final String title;
  final String subTitle;
  final String imageUrl;
  final String? ownerAvatarUrl;

  /// Physical address shown in store cards and store detail info row.
  final String? location;

  final String? tag;
  final String? badge;
  final double? rating;
  final String? phone;

  StoreModel({
    this.id,
    required this.title,
    required this.subTitle,
    required this.imageUrl,
    this.ownerAvatarUrl,
    this.location,
    this.tag,
    this.badge,
    this.rating,
    this.phone,
  });

  // ── Local JSON serialisation ──────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subTitle': subTitle,
        'imageUrl': imageUrl,
        'ownerAvatarUrl': ownerAvatarUrl,
        'location': location,
        'tag': tag,
        'badge': badge,
        'rating': rating,
        'phone': phone,
      };

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: json['id']?.toString(),
        title: json['title'] as String? ?? '',
        subTitle: json['subTitle'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
        location: json['location'] as String?,
        tag: json['tag'] as String?,
        badge: json['badge'] as String?,
        rating: _toDouble(json['rating']),
        phone: json['phone']?.toString(),
      );

  /// Constructs a [StoreModel] from a server API response (snake_case keys).
  factory StoreModel.fromServerJson(Map<String, dynamic> json) {
    final rawImage = json['logo'] ??
        json['logo_url'] ??
        json['imageUrl'] ??
        json['image_url'];
    final rawOwnerAvatar = json['owner_avatar'];

    return StoreModel(
      id: json['id']?.toString(),
      title: json['store_name'] as String? ??
          json['name'] as String? ??
          json['title'] as String? ??
          '',
      subTitle:
          json['description'] as String? ?? json['subTitle'] as String? ?? '',
      imageUrl: rawImage is String ? AppConfig.resolveMediaUrl(rawImage) : '',
      ownerAvatarUrl: rawOwnerAvatar is String && rawOwnerAvatar.trim().isNotEmpty
          ? AppConfig.resolveMediaUrl(rawOwnerAvatar)
          : null,
      location: json['region'] as String? ??
          json['city'] as String? ??
          json['location'] as String?,
      tag: (json['category'] is Map
              ? (json['category'] as Map)['name']?.toString()
              : json['category']?.toString()) ??
          json['tag'] as String?,
      badge: json['badge'] as String?,
      rating: _toDouble(json['rating']),
      phone: json['phone']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse(value.toString());
  }
}
