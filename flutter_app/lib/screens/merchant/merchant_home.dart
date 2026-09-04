import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/merchant/add_product.dart';
import 'package:ai_saas/screens/merchant/merchant_orders_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_products_screen.dart';
import 'package:ai_saas/screens/merchant/store_settings_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_subscription_screen.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const MerchantOrdersLoadRequested());
    context.read<ProductBloc>().add(const MerchantProductsLoadRequested());
    context.read<StoreBloc>().add(const MyStoreLoadRequested());
    context
        .read<MerchantDashboardBloc>()
        .add(const MerchantDashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildHeader(context),
                SizedBox(height: 16.h),
                _buildSummaryRow(context),
                SizedBox(height: 20.h),
                _buildSectionLabel(l10n.continueText),
                SizedBox(height: 10.h),
                _buildQuickActions(context),
                SizedBox(height: 16.h),
                _buildSubscriptionShortcut(context),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionShortcut(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MerchantSubscriptionScreen(),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(9.r),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.card_membership_outlined,
                  color: _primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.subscriptionStatus,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1A1A1A))),
                  SizedBox(height: 3.h),
                  Text(l10n.subscriptionStatus,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.sp, color: const Color(0xff888888))),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded,
                color: const Color(0xff888888), size: 24.sp),
          ],
        ),
      ),
    );
  }

  // ── Greeting header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, storeState) {
        String storeName = AppLocalizations.of(context).store;
        if (storeState is MyStoreLoaded) storeName = storeState.store.title;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).welcomeBack,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                color: const Color(0xff707070),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              storeName,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1A1A1A),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Summary row: orders + products ──────────────────────────────────────────
  Widget _buildSummaryRow(BuildContext context) {
    return BlocBuilder<MerchantDashboardBloc, MerchantDashboardState>(
      builder: (context, state) {
        if (state is MerchantDashboardLoading ||
            state is MerchantDashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MerchantDashboardFailure) {
          return _DashboardMessage(
            message: state.message,
            onRetry: () => context
                .read<MerchantDashboardBloc>()
                .add(const MerchantDashboardLoadRequested()),
          );
        }
        if (state is MerchantDashboardLoaded) {
          final dashboard = state.dashboard;
          if (dashboard.isEmpty) {
            return _DashboardMessage(
                message: AppLocalizations.of(context).noDashboardData);
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: AppLocalizations.of(context).newOrders,
                      value: dashboard.orders.pendingReview.toString(),
                      icon: Icons.receipt_long_outlined,
                      color: _primary,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _SummaryCard(
                      label: AppLocalizations.of(context).products,
                      value: dashboard.products.total.toString(),
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xff22C55E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: AppLocalizations.of(context).completedSales,
                      value: '₪${dashboard.totalSales.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: const Color(0xff0EA5E9),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _SummaryCard(
                      label: AppLocalizations.of(context).lowStock,
                      value: dashboard.products.lowStock.toString(),
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xffF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xff1A1A1A),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_box_outlined,
        label: AppLocalizations.of(context).addProductAction,
        color: _primary,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddProduct())),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: AppLocalizations.of(context).ordersAction,
        color: const Color(0xff22C55E),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MerchantOrdersScreen())),
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: AppLocalizations.of(context).products,
        color: const Color(0xffF59E0B),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MerchantProductsScreen())),
      ),
      _QuickAction(
        icon: Icons.person_outline,
        label: AppLocalizations.of(context).profileAction,
        color: const Color(0xffEC4899),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: AppLocalizations.of(context).storeSettingsAction,
        color: const Color(0xff0EA5E9),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StoreSettingsScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14.w,
      mainAxisSpacing: 14.h,
      childAspectRatio: 1.8,
      children: actions.map((a) => _buildActionCard(a)).toList(),
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(action.icon, color: action.color, size: 22.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                action.label,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1A1A1A),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 11.sp, color: const Color(0xff888888)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              color: const Color(0xff707070),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 8.h),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ],
      ),
    );
  }
}
