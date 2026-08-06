import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:ai_saas/shared/widgets/info_row.dart';
import 'package:ai_saas/shared/widgets/order_customer_info_card.dart';
import 'package:ai_saas/shared/widgets/order_product_line.dart';
import 'package:ai_saas/shared/widgets/order_status_badge.dart';
import 'package:ai_saas/shared/widgets/order_status_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientOrderDetailsScreen extends StatelessWidget {
  /// The order is passed for initial display, but the screen always reads the
  /// latest copy from [OrderController] so merchant status updates are
  /// reflected immediately without re-navigation.
  final AppOrder order;

  const ClientOrderDetailsScreen({super.key, required this.order});

  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppOrder>>(
      valueListenable: OrderController.instance.ordersNotifier,
      builder: (context, orders, _) {
        final current = orders.firstWhere(
          (o) => o.ref == order.ref,
          orElse: () => order,
        );
        return _buildContent(context, current);
      },
    );
  }

  Widget _buildContent(BuildContext context, AppOrder o) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: _buildAppBar(context, o),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(o),
              SizedBox(height: 16.h),
              OrderStatusTimeline(order: o, title: 'تتبع الطلب'),
              SizedBox(height: 16.h),
              OrderCustomerInfoCard(order: o),
              SizedBox(height: 16.h),
              OrderProductsCard(products: o.products, total: o.total),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, AppOrder o) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        '#${o.ref}',
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 17.sp,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Order header card ──────────────────────────────────────────────────────
  Widget _buildOrderHeader(AppOrder o) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الطلب',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11.sp, color: _textGray)),
                  SizedBox(height: 2.h),
                  Text('#${o.ref}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      )),
                ],
              ),
              OrderStatusBadge(status: o.status),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(height: 1.h, color: const Color(0xffF0F0F0)),
          SizedBox(height: 14.h),
          InfoRow(
              icon: Icons.storefront_outlined,
              label: 'المتجر',
              value: o.storeName),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'تاريخ الطلب',
              value: o.formattedDate),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.shopping_bag_outlined,
              label: 'عدد المنتجات',
              value: '${o.itemCount} منتج'),
        ],
      ),
    );
  }
}
