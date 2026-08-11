import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/core/api/app_config.dart';

// ─── AppUser ──────────────────────────────────────────────────────────────────
//
// User identity model. Populated from the server via [AppUser.fromServerJson]
// (GET /profile, POST /auth/login, POST /auth/register/*). Also persisted
// locally via shared_preferences for cold-start session restore.
//
// Server fields:
//   id           → server-assigned UUID.
//   photoPath    → network URL after upload via POST /profile/avatar.
//   storeId      → comes from the backend merchant profile on registration.
// ─────────────────────────────────────────────────────────────────────────────

class AppUser {
  /// Unique user identifier.
  /// Local format: 'usr-{timestamp}'. Replace with server UUID at migration.
  final String id;

  final String name;
  final String email;
  final String phone;

  /// User role — client, merchant, or admin. Drives UI branching throughout
  /// the app.
  final AppType role;

  /// Merchant-only: the store this user owns.
  /// Null for client users and before the merchant completes their profile.
  final String? storeId;

  /// Merchant-only: display name of the merchant's store.
  final String? storeName;

  /// Merchant-only: chosen store category (e.g. 'ملابس', 'إلكترونيات').
  final String? storeCategory;

  /// City/region selected during registration (e.g. 'غزة', 'خانيونس').
  final String? region;

  /// Profile photo URL. Contains a network URL after upload via POST /profile/avatar,
  /// or a local file path when a new photo has been picked but not yet uploaded.
  final String? photoPath;

  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.storeId,
    this.storeName,
    this.storeCategory,
    this.region,
    this.photoPath,
    required this.createdAt,
  });

  // ── Convenience ─────────────────────────────────────────────────────────────

  bool get isMerchant => role == AppType.merchant;
  bool get isClient => role == AppType.client;
  bool get isAdmin => role == AppType.admin;

  /// Display-safe name — falls back to a generic label when name is blank.
  String get displayName => name.isNotEmpty ? name : 'مستخدم Tradex';

  // ── JSON serialization ───────────────────────────────────────────────────────
  // Used for local session persistence via shared_preferences and for parsing
  // /profile responses via [AppUser.fromServerJson].

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'storeId': storeId,
      'storeName': storeName,
      'storeCategory': storeCategory,
      'region': region,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: AppType.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AppType.client,
      ),
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      storeCategory: json['storeCategory'] as String?,
      region: json['region'] as String?,
      photoPath: json['photoPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Constructs an [AppUser] from a server API response (snake_case keys).
  /// Used by [AuthService] and [UserService] after any API call that returns
  /// user data. Handles both camelCase and snake_case for forward compatibility.
  factory AppUser.fromServerJson(Map<String, dynamic> json) {
    // GET /profile (and /auth/me) return merchant store info as a `stores`
    // array rather than flat store_id/store_name fields — those flat fields
    // are only present right after login/register (see AuthService._parseAuthResult,
    // which merges them in client-side). Flatten the first store here too, so
    // a merchant's store identity survives a plain GET /profile call (e.g. on
    // session restore).
    Map<String, dynamic>? firstStore;
    final stores = json['stores'];
    if (stores is List && stores.isNotEmpty && stores.first is Map) {
      firstStore = Map<String, dynamic>.from(stores.first as Map);
    }

    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AppType.values.firstWhere(
        (e) => e.name == (json['role'] as String? ?? 'client'),
        orElse: () => AppType.client,
      ),
      storeId: json['store_id'] as String? ??
          json['storeId'] as String? ??
          firstStore?['id']?.toString(),
      storeName: json['store_name'] as String? ??
          json['storeName'] as String? ??
          firstStore?['store_name'] as String?,
      storeCategory:
          json['store_category'] as String? ?? json['storeCategory'] as String?,
      region: json['region'] as String?,
      photoPath: _resolvePhotoPath(
        json['avatar'] as String? ??
            json['photo_url'] as String? ??
            json['avatar_url'] as String? ??
            json['photoPath'] as String?,
      ),
      createdAt: _parseDate(
        json['created_at'] as String? ?? json['createdAt'] as String?,
      ),
    );
  }

  static String? _resolvePhotoPath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return AppConfig.resolveMediaUrl(value);
  }

  static DateTime _parseDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  // ── Immutable update ─────────────────────────────────────────────────────────

  // Sentinel used to distinguish "pass null explicitly" from "omitted".
  static const _absent = Object();

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    AppType? role,
    Object? storeId = _absent,
    Object? storeName = _absent,
    Object? storeCategory = _absent,
    Object? region = _absent,
    Object? photoPath = _absent,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      storeId: storeId == _absent ? this.storeId : storeId as String?,
      storeName: storeName == _absent ? this.storeName : storeName as String?,
      storeCategory: storeCategory == _absent
          ? this.storeCategory
          : storeCategory as String?,
      region: region == _absent ? this.region : region as String?,
      photoPath: photoPath == _absent ? this.photoPath : photoPath as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
