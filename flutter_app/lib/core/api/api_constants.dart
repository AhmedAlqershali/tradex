import 'package:ai_saas/core/api/app_config.dart';

// ─── API Constants ────────────────────────────────────────────────────────────
//
// Single source of truth for the backend base URL and every endpoint path.
// Import this file wherever an endpoint string is needed — never hardcode
// path strings in service files.
//
// To change the backend URL, pass --dart-define=TRADEX_BASE_URL=<url> at
// build or run time. See AppConfig for details.
// ─────────────────────────────────────────────────────────────────────────────

class ApiConstants {
  ApiConstants._();

  // ── Base URL ─────────────────────────────────────────────────────────────────
  // Reads from AppConfig which honours the --dart-define=TRADEX_BASE_URL flag.
  // Changing one dart-define activates the entire application.
  static const String baseUrl = AppConfig.baseUrl;

  // ── Timeouts ─────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Auth ──────────────────────────────────────────────────────────────────────
  // Backend exposes separate client/merchant registration endpoints (merchant
  // registration additionally creates a store atomically) — there is no single
  // unified /auth/register route.
  static const String registerClient = '/auth/register/client';
  static const String registerMerchant = '/auth/register/merchant';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  // Backend does not implement a refresh-token endpoint — Sanctum issues a
  // single long-lived token per login. Kept unused by ApiClient's 401
  // handler (which already degrades gracefully when no refresh token is
  // stored) rather than pointed at a route that doesn't exist.
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  // Backend verifies email via a signed emailed link (GET
  // /auth/email/verify/{id}/{hash}), not an in-app OTP code. Kept for the
  // resend-verification action only.
  static const String resendVerification = '/auth/email/resend';

  // ── Profile ───────────────────────────────────────────────────────────────────
  // Backend route is /profile (all authenticated roles), not /users/me — there
  // is no /users/* route outside the admin namespace. `me` is kept as the
  // constant name for readability at call sites (it means "the current user").
  static const String me = '/profile';
  static const String meAvatar = '/profile/avatar';
  static const String mePassword = '/profile/password';

  // ── Stores ───────────────────────────────────────────────────────────────────
  // Public/client browsing.
  static const String stores = '/stores';
  static String storeById(String id) => '/stores/$id';
  static String storeProducts(String storeId) => '/stores/$storeId/products';

  // Merchant-owned store management — backend has no "/stores/me" shortcut;
  // every merchant store route is id-based.
  static const String myStores = '/merchant/stores';
  static String myStoreById(String id) => '/merchant/stores/$id';
  static String myStoreLogo(String id) => '/merchant/stores/$id/logo';

  // ── Products ─────────────────────────────────────────────────────────────────
  // Public/client browsing (read-only).
  static const String products = '/products';
  // Note: product search is a query parameter on /products (?search=…),
  // not a separate route. Use: ApiConstants.products + queryParameters: {'search': q}
  static String productById(String id) => '/products/$id';

  // Merchant product CRUD — separate namespace from public browsing.
  static const String merchantProducts = '/merchant/products';
  static String merchantProductById(String id) => '/merchant/products/$id';

  // ── Config (categories) ───────────────────────────────────────────────────────
  static const String categories = '/categories';

  // ── Cart ──────────────────────────────────────────────────────────────────────
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String itemId) => '/cart/items/$itemId';

  // ── Orders ───────────────────────────────────────────────────────────────────
  // Client (own orders only).
  static const String orders = '/orders';
  static String orderByRef(String ref) => '/orders/$ref';

  // Merchant order management — separate namespace; status updates are PUT,
  // not PATCH.
  static const String merchantOrders = '/merchant/orders';
  static String merchantOrderById(String id) => '/merchant/orders/$id';
  static String merchantOrderStatus(String id) => '/merchant/orders/$id/status';

  // Client dashboard counters for the authenticated shopper.
  static const String clientDashboard = '/client/dashboard';

  // Merchant dashboard summary and analytics.
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantAnalytics = '/merchant/analytics';
  static const String merchantSubscription = '/merchant/subscription';
  static const String merchantSubscriptionRequests =
      '/merchant/subscription-requests';
  static String merchantSubscriptionRequestById(String id) =>
      '/merchant/subscription-requests/$id';

  // ── Admin ────────────────────────────────────────────────────────────────────
  // System-wide overview for authenticated admin users.
  static const String adminDashboard = '/admin/dashboard';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static const String adminStores = '/admin/stores';
  static String adminStoreById(String id) => '/admin/stores/$id';
  static String adminStoreStatus(String id) => '/admin/stores/$id/status';
  static const String adminProducts = '/admin/products';
  static String adminProductById(String id) => '/admin/products/$id';
  static const String adminCategories = '/admin/categories';
  static String adminCategoryById(String id) => '/admin/categories/$id';
  static const String adminPlans = '/admin/plans';
  static String adminPlanById(String id) => '/admin/plans/$id';
  static String adminProductReviews(String productId) =>
      '/admin/products/$productId/reviews';
  static String adminReviewById(String id) => '/admin/reviews/$id';
  static const String adminSubscriptionRequests =
      '/admin/subscription-requests';
  static String adminSubscriptionRequestById(String id) =>
      '/admin/subscription-requests/$id';
  static String adminSubscriptionRequestApprove(String id) =>
      '/admin/subscription-requests/$id/approve';
  static String adminSubscriptionRequestReject(String id) =>
      '/admin/subscription-requests/$id/reject';
  static String adminSubscriptionRequestProof(String id) =>
      '/admin/subscription-requests/$id/proof';

  // ── Favorites ────────────────────────────────────────────────────────────────
  static const String favorites = '/favorites';
  // The client favorite endpoint identifies the product in the URL.
  static String favoriteById(String productId) => '/favorites/$productId';

  // ── AI ────────────────────────────────────────────────────────────────────────
  static const String aiProductDescription = '/ai/product-description';
  // Backend combines caption + hashtags + tagline into one endpoint — there
  // is no separate /ai/marketing-post or /ai/hashtags route.
  static const String aiMarketingContent = '/ai/marketing-content';
  static const String aiCustomerReply = '/ai/customer-reply';
  // No /ai/history endpoint exists; usage/limit info is at /ai/usage.
  static const String aiUsage = '/ai/usage';
  static const String aiAnalytics = '/ai/analytics';
}
