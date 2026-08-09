import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/merchant/merchant_order_details_screen.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const MerchantOrdersLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: _buildAppBar(),
        body: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderFailure) {
              return _buildErrorState(context, state.message);
            }
            if (state is MerchantOrdersLoaded) {
              return state.orders.isEmpty
                  ? _buildEmptyState(context)
                  : _buildList(context, state.orders);
            }
            // Fallback: show loading
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: Text(
        'الطلبات الواردة',
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
       actions: [
         PopupMenuButton<String>(
           tooltip: 'تصفية الحالة',
           icon: const Icon(Icons.filter_list_rounded, color: _textDark),
           onSelected: (value) {
             context.read<OrderBloc>().add(
                   MerchantOrdersLoadRequested(
                     status: value == 'all' ? null : value,
                   ),
                 );
           },
           itemBuilder: (_) => const [
             PopupMenuItem(value: 'all', child: Text('كل الطلبات')),
             PopupMenuItem(value: 'pending', child: Text('قيد المراجعة')),
             PopupMenuItem(value: 'confirmed', child: Text('تم التأكيد')),
             PopupMenuItem(value: 'processing', child: Text('قيد التجهيز')),
             PopupMenuItem(value: 'completed', child: Text('مكتمل')),
             PopupMenuItem(value: 'cancelled', child: Text('ملغي')),
           ],
         ),
       ],
    );
  }

  // ── Orders list ────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<AppOrder> orders) {
    final pending =
        orders.where((o) => o.status == OrderStatus.pendingReview).toList();
    final others =
        orders.where((o) => o.status != OrderStatus.pendingReview).toList();
    final sorted = [...pending, ...others];

    return RefreshIndicator(
      onRefresh: () async => context
          .read<OrderBloc>()
          .add(const MerchantOrdersLoadRequested()),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, i) => _buildOrderCard(context, sorted[i]),
      ),
    );
  }

  // ── Order card ─────────────────────────────────────────────────────────────
  Widget _buildOrderCard(BuildContext context, AppOrder order) {
    final bool isPending = order.status == OrderStatus.pendingReview;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MerchantOrderDetailsScreen(orderRef: order.ref),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isPending
              ? Border.all(
                  color: _primary.withValues(alpha: 0.25), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isPending)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        margin: EdgeInsets.only(left: 6.w),
                        decoration: const BoxDecoration(
                          color: Color(0xff4D41DF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '#${order.ref}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14.sp, color: _textGray),
                SizedBox(width: 4.w),
                Text(order.customerName,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp, color: _textGray)),
                SizedBox(width: 12.w),
                Icon(Icons.calendar_today_outlined,
                    size: 14.sp, color: _textGray),
                SizedBox(width: 4.w),
                Text(order.formattedDate,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp, color: _textGray)),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.itemCount} منتج',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp, color: _textGray)),
                Text(
                  '₪${order.total.toStringAsFixed(0)}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: status.color,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 60.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: _textGray)),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => context
                .read<OrderBloc>()
                .add(const MerchantOrdersLoadRequested()),
            child: Text('إعادة المحاولة', style: GoogleFonts.ibmPlexSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: const BoxDecoration(
                  color: Color(0xffEDE9FF), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined,
                  size: 46.sp, color: _primary),
            ),
            SizedBox(height: 20.h),
            Text('لا توجد طلبات بعد',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
            SizedBox(height: 8.h),
            Text('ستظهر هنا طلبات العملاء فور وصولها',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp, color: _textGray)),
          ],
        ),
      ),
    );
  }
}
