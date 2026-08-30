import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:ai_saas/shared/widgets/info_row.dart';
import 'package:ai_saas/shared/widgets/order_customer_info_card.dart';
import 'package:ai_saas/shared/widgets/order_product_line.dart';
import 'package:ai_saas/shared/widgets/order_status_badge.dart';
import 'package:ai_saas/shared/widgets/order_status_timeline.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientOrderDetailsScreen extends StatefulWidget {
  final AppOrder order;

  const ClientOrderDetailsScreen({super.key, required this.order});

  @override
  State<ClientOrderDetailsScreen> createState() =>
      _ClientOrderDetailsScreenState();
}

class _ClientOrderDetailsScreenState extends State<ClientOrderDetailsScreen> {

  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadOrder() {
    final orderId = widget.order.serverId;
    if (orderId == null || orderId.isEmpty) return;
    context.read<OrderBloc>().add(
          OrderByIdRequested(orderId, asMerchant: false),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is OrderFailure) {
          return _buildErrorScaffold(state);
        }

        AppOrder? current;
        if (state is OrderDetailLoaded) current = state.order;
        if (state is OrderStatusUpdated) current = state.order;
        if (current == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(context, current);
      },
    );
  }

  Widget _buildErrorScaffold(OrderFailure state) {
    final error = state.error;
    final title = error is AuthException
        ? AppLocalizations.of(context).sessionExpired
        : error is ForbiddenException
            ? AppLocalizations.of(context).forbidden
            : error is ServerException && error.statusCode == 404
                ? AppLocalizations.of(context).serverError
                : error is NetworkException
                    ? AppLocalizations.of(context).networkError
                    : error is TimeoutException
                        ? AppLocalizations.of(context).timeoutError
                        : AppLocalizations.of(context).unexpectedError;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).orderDetails),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _loadOrder,
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      ),
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
              OrderStatusTimeline(order: o, title: AppLocalizations.of(context).orderTrackingTitle),
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
                  Text(AppLocalizations.of(context).orderNumber,
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
              label: AppLocalizations.of(context).store,
              value: o.storeName),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.calendar_today_outlined,
              label: AppLocalizations.of(context).orderDate,
              value: o.formattedDate),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.shopping_bag_outlined,
              label: AppLocalizations.of(context).productCountLabel,
              value: '${o.itemCount} ${AppLocalizations.of(context).products}'),
        ],
      ),
    );
  }
}
