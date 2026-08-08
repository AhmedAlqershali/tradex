import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/client/categories_screen.dart';
import 'package:ai_saas/screens/merchant/ai_marketing_tools_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_home.dart';
import 'package:ai_saas/screens/merchant/merchant_orders_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_products_screen.dart';
import 'package:ai_saas/screens/admin/admin_dashboard_screen.dart';
import 'package:ai_saas/screens/admin/admin_analytics_screen.dart';
import 'package:ai_saas/screens/admin/admin_merchants_screen.dart';
import 'package:ai_saas/screens/admin/admin_users_screen.dart';
import 'package:ai_saas/screens/admin/admin_categories_screen.dart';
import 'package:ai_saas/screens/admin/admin_plans_screen.dart';
import 'package:ai_saas/screens/admin/admin_reviews_screen.dart';
import 'package:ai_saas/screens/admin/admin_subscription_requests_screen.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:ai_saas/screens/shopper_home.dart';
import 'package:flutter/material.dart';
import 'package:ai_saas/shared/navigation/nav_item.dart';

class NavConfig {
  static List<BnItem> getItems(AppType type) {
    switch (type) {
      // 👇 العميل
      case AppType.client:
        return [
          BnItem(
            widget: ShopperHomePage(),
            title: 'الرئيسية',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
          ),
          BnItem(
            widget: SearchScreen(),
            title: 'بحث',
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
          ),
          BnItem(
            widget: CategoriesScreen(),
            title: 'التصنيفات',
            icon: Icons.category_outlined,
            activeIcon: Icons.category_rounded,
          ),
          BnItem(
            widget: ProfileScreen(),
            title: 'حسابي',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ];

      // 👇 التاجر
      case AppType.merchant:
        return [
          BnItem(
            widget: MerchantHomePage(),
            title: 'الرئيسية',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          BnItem(
            widget: MerchantOrdersScreen(),
            title: 'الطلبات',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
          const BnItem(
            widget: AlMarketingToolsScreen(),
            title: 'AI أدوات',
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
          ),
          const BnItem(
            widget: MerchantProductsScreen(),
            title: 'منتجاتي',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
          ),
          const BnItem(
            widget: ProfileScreen(),
            title: 'حسابي',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ];

      case AppType.admin:
        return [
          const BnItem(
            widget: AdminDashboardScreen(),
            title: 'نظرة عامة',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          const BnItem(
            widget: AdminAnalyticsScreen(),
            title: 'التحليلات',
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
          ),
          const BnItem(
            widget: AdminUsersScreen(),
            title: 'المستخدمون',
            icon: Icons.people_outline,
            activeIcon: Icons.people,
          ),
          const BnItem(
            widget: AdminMerchantsScreen(),
            title: 'التجار',
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
          ),
          const BnItem(
            widget: AdminCategoriesScreen(),
            title: 'التصنيفات',
            icon: Icons.category_outlined,
            activeIcon: Icons.category,
          ),
          const BnItem(
            widget: AdminPlansScreen(),
            title: 'الخطط',
            icon: Icons.card_membership_outlined,
            activeIcon: Icons.card_membership,
          ),
          const BnItem(
            widget: AdminReviewsScreen(),
            title: 'المراجعات',
            icon: Icons.rate_review_outlined,
            activeIcon: Icons.rate_review,
          ),
          const BnItem(
            widget: AdminSubscriptionRequestsScreen(),
            title: 'طلبات الاشتراك',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
          ),
          const BnItem(
            widget: ProfileScreen(),
            title: 'حسابي',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ];
    }
  }
}
