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

  /// Physical address shown in store cards and store detail info row.
  final String? location;

  final String? tag;
  final String? badge;
  final double? rating;

  StoreModel({
    this.id,
    required this.title,
    required this.subTitle,
    required this.imageUrl,
    this.location,
    this.tag,
    this.badge,
    this.rating,
  });

  // ── Local JSON serialisation ──────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subTitle': subTitle,
        'imageUrl': imageUrl,
        'location': location,
        'tag': tag,
        'badge': badge,
        'rating': rating,
      };

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        subTitle: json['subTitle'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        location: json['location'] as String?,
        tag: json['tag'] as String?,
        badge: json['badge'] as String?,
        rating:
            json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      );

  /// Constructs a [StoreModel] from a server API response (snake_case keys).
  factory StoreModel.fromServerJson(Map<String, dynamic> json) {
    final rawImage = json['logo'] ??
        json['logo_url'] ??
        json['imageUrl'] ??
        json['image_url'];

    return StoreModel(
      id: json['id']?.toString(),
      title: json['store_name'] as String? ??
          json['name'] as String? ??
          json['title'] as String? ??
          '',
      subTitle:
          json['description'] as String? ?? json['subTitle'] as String? ?? '',
      imageUrl: rawImage is String ? AppConfig.resolveMediaUrl(rawImage) : '',
      location: json['city'] as String? ?? json['location'] as String?,
      tag: (json['category'] is Map
              ? (json['category'] as Map)['name']?.toString()
              : json['category']?.toString()) ??
          json['tag'] as String?,
      badge: json['badge'] as String?,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }
}
