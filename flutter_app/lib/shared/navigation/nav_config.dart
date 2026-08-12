import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/client/categories_screen.dart';
import 'package:ai_saas/screens/merchant/ai_marketing_tools_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_home.dart';
import 'package:ai_saas/screens/merchant/merchant_orders_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_products_screen.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:ai_saas/screens/shopper_home.dart';
import 'package:flutter/material.dart';
import 'package:ai_saas/shared/navigation/nav_item.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';

class NavConfig {
  static List<BnItem> getItems(AppType type, AppLocalizations l10n) {
    switch (type) {
      // 👇 العميل
      case AppType.client:
        return [
          BnItem(
            widget: ShopperHomePage(),
            title: l10n.home,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
          ),
          BnItem(
            widget: SearchScreen(),
            title: l10n.search,
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
          ),
          BnItem(
            widget: CategoriesScreen(),
            title: l10n.categories,
            icon: Icons.category_outlined,
            activeIcon: Icons.category_rounded,
          ),
          BnItem(
            widget: ProfileScreen(),
            title: l10n.account,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ];

      // 👇 التاجر
      case AppType.merchant:
        return [
          BnItem(
            widget: MerchantHomePage(),
            title: l10n.home,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          BnItem(
            widget: MerchantOrdersScreen(),
            title: l10n.orders,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
          BnItem(
            widget: AlMarketingToolsScreen(),
            title: l10n.aiTools,
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
          ),
          BnItem(
            widget: MerchantProductsScreen(),
            title: l10n.myProducts,
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
          ),
          BnItem(
            widget: ProfileScreen(),
            title: l10n.account,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
        ];

      // Admin accounts are managed through the Web Admin Dashboard only.
      case AppType.admin:
        return const [];
    }
  }
}
