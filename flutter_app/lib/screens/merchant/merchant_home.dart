import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/merchant/add_product.dart';
import 'package:ai_saas/screens/merchant/merchant_orders_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_products_screen.dart';
import 'package:ai_saas/screens/merchant/store_settings_screen.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                _buildHeader(context),
                SizedBox(height: 24.h),
                _buildSummaryRow(context),
                SizedBox(height: 28.h),
                _buildSectionLabel('الإجراءات السريعة'),
                SizedBox(height: 14.h),
                _buildQuickActions(context),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Greeting header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, storeState) {
        String storeName = 'متجرك';
        if (storeState is MyStoreLoaded) storeName = storeState.store.title;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً بك 👋',
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
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              int pendingCount = 0;
              if (state is MerchantOrdersLoaded) {
                pendingCount = state.orders
                    .where((o) => o.status == OrderStatus.pendingReview)
                    .length;
              }
              return _SummaryCard(
                label: 'طلبات جديدة',
                value: pendingCount.toString(),
                icon: Icons.receipt_long_outlined,
                color: _primary,
              );
            },
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              int productCount = 0;
              if (state is ProductsLoaded) productCount = state.products.length;
              return _SummaryCard(
                label: 'المنتجات',
                value: productCount.toString(),
                icon: Icons.inventory_2_outlined,
                color: const Color(0xff22C55E),
              );
            },
          ),
        ),
      ],
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
        label: 'إضافة منتج',
        color: _primary,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddProduct())),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'الطلبات',
        color: const Color(0xff22C55E),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MerchantOrdersScreen())),
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'المنتجات',
        color: const Color(0xffF59E0B),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MerchantProductsScreen())),
      ),
      _QuickAction(
        icon: Icons.person_outline,
        label: 'الملف الشخصي',
        color: const Color(0xffEC4899),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: 'إعدادات المتجر',
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
      children: actions
          .map((a) => _buildActionCard(a))
          .toList(),
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
