import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:ai_saas/shared/widgets/info_row.dart';
import 'package:ai_saas/shared/widgets/order_customer_info_card.dart';
import 'package:ai_saas/shared/widgets/order_product_line.dart';
import 'package:ai_saas/shared/widgets/order_status_badge.dart';
import 'package:ai_saas/shared/widgets/order_status_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantOrderDetailsScreen extends StatefulWidget {
  final String orderRef;

  const MerchantOrderDetailsScreen({super.key, required this.orderRef});

  @override
  State<MerchantOrderDetailsScreen> createState() =>
      _MerchantOrderDetailsScreenState();
}

class _MerchantOrderDetailsScreenState
    extends State<MerchantOrderDetailsScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderByRefRequested(widget.orderRef));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        AppOrder? order;
        if (state is OrderDetailLoaded) order = state.order;
        if (state is OrderStatusUpdated) order = state.order;

        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('تفاصيل الطلب',
                  style: GoogleFonts.ibmPlexSans()),
            ),
            body: Center(
              child: Text('الطلب غير موجود',
                  style: GoogleFonts.ibmPlexSans()),
            ),
          );
        }

        return _buildScaffold(context, order);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, AppOrder order) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: _buildAppBar(context, order),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(order),
              SizedBox(height: 16.h),
              _buildTimeline(order),
              SizedBox(height: 16.h),
              _buildProductsCard(order),
              SizedBox(height: 16.h),
              OrderCustomerInfoCard(order: order),
              SizedBox(height: 16.h),
              if (_getActions(order).isNotEmpty) _buildActionButtons(context, order),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppOrder order) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'طلب #${order.ref}',
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
        ),
      ),
      centerTitle: true,
    );
  }

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

  Widget _buildTimeline(AppOrder order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مسار الطلب',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: _textDark)),
          SizedBox(height: 16.h),
          OrderStatusTimeline(order: order),
        ],
      ),
    );
  }

  Widget _buildProductsCard(AppOrder order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المنتجات',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              Text('₪${order.total.toStringAsFixed(0)}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
            ],
          ),
          SizedBox(height: 12.h),
          ...order.products.map((p) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: OrderProductLine(product: p),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppOrder order) {
    final actions = _getActions(order);
    return Column(
      children: actions.map((action) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<OrderBloc>().add(
                      OrderStatusUpdateRequested(
                        ref: order.ref,
                        status: action.nextStatus.name,
                      ),
                    );
              },
              icon: Icon(action.icon, size: 18.sp),
              label: Text(action.label,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14.sp, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_OrderAction> _getActions(AppOrder order) {
    // ignore: exhaustive_cases — default handles any future enum additions
    switch (order.status) {
      case OrderStatus.pendingReview:
        return [
          _OrderAction(
            label: 'تواصل مع العميل',
            icon: Icons.phone_in_talk_outlined,
            color: _primary,
            nextStatus: OrderStatus.merchantContacted,
          ),
          _OrderAction(
            label: 'إلغاء الطلب',
            icon: Icons.cancel_outlined,
            color: const Color(0xffE53E3E),
            nextStatus: OrderStatus.cancelled,
          ),
        ];
      case OrderStatus.merchantContacted:
      case OrderStatus.orderConfirmed:
        return [
          _OrderAction(
            label: 'بدء التحضير',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xffEA580C),
            nextStatus: OrderStatus.preparing,
          ),
          _OrderAction(
            label: 'إلغاء الطلب',
            icon: Icons.cancel_outlined,
            color: const Color(0xffE53E3E),
            nextStatus: OrderStatus.cancelled,
          ),
        ];
      case OrderStatus.preparing:
        return [
          _OrderAction(
            label: 'تم التسليم',
            icon: Icons.done_all_rounded,
            color: const Color(0xff00C896),
            nextStatus: OrderStatus.completed,
          ),
        ];
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return [];
    }
  }
}

class _OrderAction {
  final String label;
  final IconData icon;
  final Color color;
  final OrderStatus nextStatus;

  const _OrderAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.nextStatus,
  });
}
