import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/client/client_order_details_screen.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const ClientOrdersLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: _buildAppBar(context),
        body: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderFailure) {
              return _buildErrorState(context, state.message);
            }
            if (state is ClientOrdersLoaded) {
              return state.orders.isEmpty
                  ? _buildEmptyState(context)
                  : _buildList(context, state.orders);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        AppLocalizations.of(context).myOrders,
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Orders list ────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<AppOrder> orders) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: orders.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, i) => _buildOrderCard(context, orders[i]),
    );
  }

  // ── Order card ─────────────────────────────────────────────────────────────
  Widget _buildOrderCard(BuildContext context, AppOrder order) {
    return GestureDetector(
      onTap: order.serverId == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientOrderDetailsScreen(order: order),
                ),
              ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.ref}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 14.sp, color: _textGray),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    order.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp, color: _textGray),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.calendar_today_outlined,
                    size: 14.sp, color: _textGray),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    order.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp, color: _textGray),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} ${AppLocalizations.of(context).products}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.sp, color: _textGray),
                ),
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

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 60.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp, color: _textGray)),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context
                  .read<OrderBloc>()
                  .add(const ClientOrdersLoadRequested()),
              child: Text(AppLocalizations.of(context).retry,
                  style: GoogleFonts.ibmPlexSans()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
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
                color: Color(0xffEDE9FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 46.sp, color: _primary),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context).noOrdersYet,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context).noOrdersDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: _textGray),
            ),
          ],
        ),
      ),
    );
  }
}
