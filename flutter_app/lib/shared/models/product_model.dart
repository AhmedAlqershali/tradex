import 'package:ai_saas/core/api/app_config.dart';

/// Represents a product in the Tradex catalog.
///
/// Populated from the server via [Product.fromServerJson] (GET /products,
/// GET /products/:id, POST/PUT /merchant/products). Also held in the local
/// [ProductController] cache for optimistic UI updates.
///
/// All fields map 1-to-1 with server fields. [id] is the server-assigned UUID.
/// [merchantId] and [storeId] come from the authenticated merchant's profile.
class Product {
  /// Unique product identifier.
  /// Local format: 'prod-{timestamp}'. Replace with server UUID at migration.
  final String id;

  /// Reserved for future auth filtering.
  /// Set to the authenticated merchant's ID when the auth layer is added.
  final String? merchantId;

  /// The store this product belongs to.
  /// Matches [StoreModel.id] for product → store lookup.
  final String? storeId;

  final String name;
  final String storeName;
  final String description;
  final String category;

  /// Numeric category id as used by the backend's /merchant/products CRUD
  /// (`category_id`). Null when the product has no category or when built
  /// from client-side data that only has the display [category] name.
  final String? categoryId;
  final double price;
  final int quantity;
  final String status;

  /// Ordered list of image URLs from the server (object storage).
  /// The first entry is used as the primary image.
  final List<String> imageUrls;

  final bool isVisible;
  final bool isFeatured;
  final DateTime createdAt;

  Product({
    required this.id,
    this.merchantId,
    this.storeId,
    required this.name,
    required this.storeName,
    this.description = '',
    required this.category,
    this.categoryId,
    required this.price,
    this.quantity = 0,
    this.status = 'active',
    this.imageUrls = const [],
    this.isVisible = true,
    this.isFeatured = false,
    required this.createdAt,
  });

  /// Convenience getter — first image URL or empty string when no images exist.
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // ── Immutable update helper ─────────────────────────────────────────────────

  Product copyWith({
    String? id,
    String? merchantId,
    String? storeId,
    String? name,
    String? storeName,
    String? description,
    String? category,
    String? categoryId,
    double? price,
    int? quantity,
    String? status,
    List<String>? imageUrls,
    bool? isVisible,
    bool? isFeatured,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── JSON serialisation (backend migration ready) ────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchantId': merchantId,
        'storeId': storeId,
        'name': name,
        'storeName': storeName,
        'description': description,
        'category': category,
        'categoryId': categoryId,
        'price': price,
        'quantity': quantity,
        'status': status,
        'imageUrls': imageUrls,
        'isVisible': isVisible,
        'isFeatured': isFeatured,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        merchantId: json['merchantId']?.toString(),
        storeId: json['storeId']?.toString(),
        name: json['name'] as String? ?? '',
        storeName: json['storeName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        categoryId: json['categoryId']?.toString(),
        price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'active',
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        isVisible: json['isVisible'] as bool? ?? true,
        isFeatured: json['isFeatured'] as bool? ?? false,
        createdAt: _parseDate(json['createdAt'] as String?),
      );

  /// Constructs a [Product] from a server API response (snake_case keys).
  /// Server fields: id, merchant_id, store_id, name, store_name (or storeName),
  /// description, category, price, images (array of {id, url}),
  /// is_visible, is_featured, created_at.
  factory Product.fromServerJson(Map<String, dynamic> json) {
    // Extract image URLs from images array [{id, url}] or plain string list.
    final rawImages = json['images'];
    List<String> imageUrls = [];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is Map) {
          final url = img['url']?.toString() ?? img['image_url']?.toString();
          if (url != null && url.isNotEmpty) {
            imageUrls.add(AppConfig.resolveMediaUrl(url));
          }
        } else if (img is String) {
          imageUrls.add(AppConfig.resolveMediaUrl(img));
        }
      }
    }
    // Also fall back to imageUrls / image_urls plain array.
    if (imageUrls.isEmpty) {
      final plain = json['imageUrls'] ?? json['image_urls'];
      if (plain is List) {
        imageUrls = plain
            .map((value) => AppConfig.resolveMediaUrl(value.toString()))
            .toList();
      }
    }
    // Final fallback: the single primary thumbnail the backend always sends.
    if (imageUrls.isEmpty) {
      final primary = json['image'] as String?;
      if (primary != null && primary.isNotEmpty) {
        imageUrls.add(AppConfig.resolveMediaUrl(primary));
      }
    }

    // Backend sends `category` as a nested {id, name} object (or omits it
    // entirely when the relation isn't loaded), not a plain string.
    final rawCategory = json['category'];
    String categoryName = '';
    String? categoryId;
    if (rawCategory is Map) {
      categoryName = rawCategory['name'] as String? ?? '';
      categoryId = rawCategory['id']?.toString();
    } else if (rawCategory is String) {
      categoryName = rawCategory;
    }
    categoryId ??= json['category_id']?.toString();

    // Backend sends visibility as a `status` enum (active/inactive/
    // out_of_stock) plus a computed `is_available` flag — there is no
    // is_visible boolean. Legacy is_visible/isVisible kept as a fallback for
    // the local-only JSON path.
    final status = json['status'] as String?;
    final isVisible = status != null
        ? status == 'active'
        : (json['is_available'] as bool? ??
            json['is_visible'] as bool? ??
            json['isVisible'] as bool? ??
            true);

    return Product(
      id: json['id']?.toString() ?? '',
      merchantId: json['merchant_id']?.toString() ?? json['merchantId'] as String?,
      storeId: json['store_id']?.toString() ?? json['storeId'] as String?,
      name: json['name'] as String? ?? '',
      storeName: json['store_name'] as String? ??
          json['storeName'] as String? ??
          (json['store'] is Map ? (json['store']['store_name'] as String? ?? '') : ''),
      description: json['description'] as String? ?? '',
      category: categoryName,
      categoryId: categoryId,
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      status: status ?? 'active',
      imageUrls: imageUrls,
      isVisible: isVisible,
      // Backend has no "featured" concept — always false from server data.
      isFeatured: json['is_featured'] as bool? ?? json['isFeatured'] as bool? ?? false,
      createdAt: _parseDate(
        json['created_at'] as String? ?? json['createdAt'] as String?,
      ),
    );
  }

  static DateTime _parseDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return value == null ? 0.0 : double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return value == null ? 0 : int.tryParse(value.toString()) ?? 0;
  }
}
