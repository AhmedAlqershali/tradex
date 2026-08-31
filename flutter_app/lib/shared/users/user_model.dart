import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/core/api/app_config.dart';
import 'avatar_diagnostics.dart';

// ─── AppUser ──────────────────────────────────────────────────────────────────
//
// User identity model. Populated from the server via [AppUser.fromServerJson]
// (GET /auth/me, POST /auth/login, POST /auth/register/*). Also persisted
// locally via shared_preferences for cold-start session restore.
//
// Server fields:
//   id           → server-assigned UUID.
//   photoPath    → server-backed network URL after upload via POST /profile/avatar.
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

  /// Resolved display name returned by the location provider or selected by
  /// the user.
  final String? locationName;

  /// Coordinates persisted by Laravel for the latest GPS selection.
  final double? latitude;
  final double? longitude;

  /// Authoritative server URL for the profile photo. A picked local file is
  /// transient UI input only and must be uploaded before it reaches this model.
  final String? photoPath;

  final DateTime createdAt;

  /// The server-authoritative merchant trial/paid entitlement snapshot from
  /// `/auth/me`. This is intentionally not written to local session JSON:
  /// authorization and freshness always come from Laravel.
  final UserEntitlement? currentSubscription;

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
    this.locationName,
    this.latitude,
    this.longitude,
    this.photoPath,
    this.currentSubscription,
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
      'region': region,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: AppType.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AppType.client,
      ),
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      storeCategory: json['storeCategory'] as String?,
      region: json['region'] as String?,
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // Legacy session JSON may contain either the server-backed camelCase
      // value or an older avatar key. Apply the same server-path guard used
      // for API responses so a device path can never become durable state.
      photoPath: _resolvePhotoPath(
        _stringValue(json['photoPath']) ?? _stringValue(json['avatar']),
      ),
      // Deliberately ignore any locally cached subscription/trial fields.
      // Laravel `/auth/me` is the only authority for entitlement state.
      createdAt: _parseDate(json['createdAt'] as String?),
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
    final userRole = AppType.values.firstWhere(
      (e) => e.name == (_stringValue(json['role']) ?? 'client'),
      orElse: () => AppType.client,
    );

    final photoPath = _resolvePhotoPath(
      _stringValue(json['avatar']) ??
          _stringValue(json['photo_url']) ??
          _stringValue(json['avatar_url']) ??
          _stringValue(json['photoPath']),
    );
    AvatarDiagnostics.log('UserModel.fromJson stored photoPath', photoPath);

    return AppUser(
      id: json['id']?.toString() ?? '',
      name: _stringValue(json['name']) ?? '',
      email: _stringValue(json['email']) ?? '',
      phone: _stringValue(json['phone']) ?? '',
      role: userRole,
      storeId: _stringValue(json['store_id']) ??
          _stringValue(json['storeId']) ??
          firstStore?['id']?.toString(),
      storeName: _stringValue(json['store_name']) ??
          _stringValue(json['storeName']) ??
          firstStore?['name'],
      storeCategory: _stringValue(json['store_category']) ??
          _stringValue(json['storeCategory']),
      region: _stringValue(json['region']),
      locationName: _stringValue(json['location_name']) ??
          _stringValue(json['locationName']),
      latitude: _numberValue(json['latitude']),
      longitude: _numberValue(json['longitude']),
      photoPath: photoPath,
      createdAt: _parseDate(
        _stringValue(json['created_at']) ?? _stringValue(json['createdAt']),
      ),
      currentSubscription: _parseEntitlement(json, userRole),
    );
  }

  static String? _resolvePhotoPath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    final isAbsoluteUrl =
        parsed != null && parsed.hasScheme && parsed.host.isNotEmpty;
    final isRootRelativeServerPath = trimmed.startsWith('/storage/');

    // Never promote an arbitrary local/device path into the user's durable
    // profile state. Laravel returns either an absolute Storage::url() value
    // or a root-relative public storage path.
    if (!isAbsoluteUrl && !isRootRelativeServerPath) return null;

    return AppConfig.resolveMediaUrl(trimmed);
  }

  /// Returns whether [value] is a server-owned avatar reference rather than
  /// a path returned by the native image picker.
  ///
  /// The backend normally returns an absolute URL. `/storage/...` is also
  /// accepted because older Laravel deployments may return a root-relative
  /// public-storage URL.
  static bool isServerPhotoPath(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('/storage/')) return true;

    final parsed = Uri.tryParse(trimmed);
    return parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.host.isNotEmpty;
  }

  static DateTime _parseDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static double? _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static UserEntitlement? _parseEntitlement(
    Map<String, dynamic> json,
    AppType role,
  ) {
    // Laravel only exposes current_subscription for merchants. Ignore an
    // unexpected client/admin field rather than leaking merchant UI/state into
    // those roles.
    if (role != AppType.merchant) return null;
    final raw = json['current_subscription'];
    if (raw is! Map) return null;
    return UserEntitlement.fromServerJson(Map<String, dynamic>.from(raw));
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
    Object? locationName = _absent,
    Object? latitude = _absent,
    Object? longitude = _absent,
    Object? photoPath = _absent,
    Object? currentSubscription = _absent,
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
      locationName:
          locationName == _absent ? this.locationName : locationName as String?,
      latitude: latitude == _absent ? this.latitude : latitude as double?,
      longitude: longitude == _absent ? this.longitude : longitude as double?,
      photoPath: photoPath == _absent ? this.photoPath : photoPath as String?,
      currentSubscription: currentSubscription == _absent
          ? this.currentSubscription
          : currentSubscription as UserEntitlement?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Minimal entitlement snapshot embedded in the authenticated merchant user
/// payload. It is not an authorization mechanism; Laravel remains authoritative.
class UserEntitlement {
  const UserEntitlement({
    required this.type,
    required this.status,
    required this.isTrial,
    required this.isEntitled,
    this.startsAt,
    this.endsAt,
  });

  final String type;
  final String status;
  final bool isTrial;
  final bool isEntitled;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isPaid => type == 'paid' && !isTrial;

  /// Expiry is a server state, not a client-side date calculation. A future
  /// dated subscription can be non-entitled without being expired.
  bool get isExpired => status == 'expired';

  factory UserEntitlement.fromServerJson(Map<String, dynamic> json) {
    return UserEntitlement(
      type: _text(json['type']),
      status: _text(json['status']),
      isTrial: json['is_trial'] == true,
      isEntitled: json['is_entitled'] == true,
      startsAt: _date(json['starts_at']),
      endsAt: _date(json['ends_at']),
    );
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _date(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }
}
