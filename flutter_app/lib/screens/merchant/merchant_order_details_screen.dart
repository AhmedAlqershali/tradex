import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/whatsapp_support_service.dart';
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
  final String orderId;

  const MerchantOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<MerchantOrderDetailsScreen> createState() =>
      _MerchantOrderDetailsScreenState();
}

class _MerchantOrderDetailsScreenState
    extends State<MerchantOrderDetailsScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);
  AppOrder? _displayedOrder;

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderByIdRequested(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listenWhen: (previous, current) =>
          (current is OrderFailure && current.orderId == widget.orderId) ||
          (current is OrderStatusUpdated && current.orderId == widget.orderId),
      listener: (context, state) {
        if (state is OrderFailure) {
          _showMessage(context, state.message);
        } else if (state is OrderStatusUpdated) {
          _showMessage(context, state.order.status.label);
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading &&
              state.order == null &&
              _displayedOrder == null) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          AppOrder? order;
          if (state is OrderLoading &&
              (state.orderId == widget.orderId ||
                  state.order?.serverId == widget.orderId)) {
            order = state.order;
          }
          if (state is OrderDetailLoaded &&
              state.order.serverId == widget.orderId) {
            order = state.order;
          }
          if (state is OrderStatusUpdated &&
              (state.orderId == widget.orderId ||
                  state.order.serverId == widget.orderId)) {
            order = state.order;
          }
          if (state is OrderFailure &&
              (state.orderId == widget.orderId ||
                  state.order?.serverId == widget.orderId)) {
            order = state.order;
          }

          if (order != null) {
            _displayedOrder = order;
          } else if (state is! OrderFailure ||
              state.orderId != widget.orderId) {
            order = _displayedOrder;
          }

          if (state is OrderFailure && order == null) {
            return _buildFailureScaffold(context, state);
          }

          // The shared OrderBloc may still contain the merchant list state for
          // one frame before this screen's request emits OrderLoading. That is
          // not a missing order; keep showing a loading state until the detail
          // request resolves.
          if (order == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildScaffold(context, order);
        },
      ),
    );
  }

  Widget _buildFailureScaffold(BuildContext context, OrderFailure state) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            l10n.orderDetails,
            style: GoogleFonts.ibmPlexSans(
              color: _textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _errorIcon(state.error),
                  size: 56.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16.h),
                Text(
                  _errorTitle(state.error),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    color: _textGray,
                  ),
                ),
                SizedBox(height: 20.h),
                OutlinedButton(
                  onPressed: () => context.read<OrderBloc>().add(
                        OrderByIdRequested(widget.orderId),
                      ),
                  child: Text(
                    l10n.retry,
                    style: GoogleFonts.ibmPlexSans(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _errorIcon(ApiException? error) {
    if (error is NetworkException || error is TimeoutException) {
      return Icons.wifi_off_rounded;
    }
    if (error is AuthException || error is ForbiddenException) {
      return Icons.lock_outline_rounded;
    }
    if (error is ServerException && error.statusCode == 404) {
      return Icons.receipt_long_outlined;
    }
    if (error is ServerException && error.statusCode >= 500) {
      return Icons.cloud_off_rounded;
    }
    return Icons.error_outline_rounded;
  }

  String _errorTitle(ApiException? error) {
    if (error is NetworkException) return AppLocalizations.of(context).networkError;
    if (error is TimeoutException) return AppLocalizations.of(context).timeoutError;
    if (error is AuthException) return AppLocalizations.of(context).sessionExpired;
    if (error is ForbiddenException) return AppLocalizations.of(context).forbidden;
    if (error is ValidationException) return AppLocalizations.of(context).invalidOrderId;
    if (error is ServerException && error.statusCode == 404) {
      return AppLocalizations.of(context).orderNotFound;
    }
    if (error is ServerException && error.statusCode >= 500) {
      return AppLocalizations.of(context).serverError;
    }
    return AppLocalizations.of(context).unableLoadOrderDetails;
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
              if (_getActions(order).isNotEmpty)
                _buildActionButtons(context, order),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppOrder order) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        '${l10n.orderNumber} #${order.ref}',
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
                  Text(l10n.orderNumber,
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
              label: l10n.store,
              value: o.storeName),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.orderDate,
              value: o.formattedDate),
          SizedBox(height: 10.h),
          InfoRow(
              icon: Icons.shopping_bag_outlined,
              label: l10n.productCount,
              value: '${o.itemCount} ${l10n.products}'),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppOrder order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.orderTimeline,
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
              Text(l10n.products,
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
        final isUpdating = _isUpdating(order);
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (action.isContact) {
                        await _contactCustomer(context, order);
                        return;
                      }
                      final nextStatus = action.nextStatus;
                      if (nextStatus != null) {
                        _updateOrderStatus(context, order, nextStatus);
                      }
                    },
              icon: Icon(action.icon, size: 18.sp),
              label: isUpdating
                  ? SizedBox(
                      width: 18.sp,
                      height: 18.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(action.label,
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

  Widget _buildConversationButton(BuildContext context, AppOrder order) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: OutlinedButton.icon(
          onPressed: () => _contactCustomer(context, order),
          icon: Icon(Icons.phone_in_talk_outlined, size: 18.sp),
          label: Text(
            l10n.contactCustomer,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: BorderSide(color: _primary.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  bool _isUpdating(AppOrder order) {
    final state = context.read<OrderBloc>().state;
    return state is OrderLoading && state.orderId == order.serverId;
  }

  void _updateOrderStatus(
    BuildContext context,
    AppOrder order,
    OrderStatus status,
  ) {
    final serverId = order.serverId;
    if (serverId == null || int.tryParse(serverId) == null) {
      _showMessage(context, 'معرف الطلب غير صالح');
      return;
    }
    context.read<OrderBloc>().add(
          OrderStatusUpdateRequested(
            id: serverId,
            status: status.name,
          ),
        );
  }

  List<MerchantOrderAction> _getActions(AppOrder order) {
    return merchantOrderActionsFor(order.status);
  }

  Future<void> _contactCustomer(BuildContext context, AppOrder order) async {
    if (order.serverId == null || int.tryParse(order.serverId!) == null) {
      _showMessage(context, 'معرف الطلب غير صالح');
      return;
    }
    if (WhatsAppSupportService.normalizePhone(order.customerPhone) == null) {
      _showMessage(context, AppLocalizations.of(context).invalidCustomerPhone);
      return;
    }
    final opened = await WhatsAppSupportService.openCustomerChat(
      order.customerPhone,
    );
    if (!context.mounted) return;
    _showMessage(
      context,
      opened ? AppLocalizations.of(context).customerChatOpened : AppLocalizations.of(context).unableOpenCustomerWhatsApp,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class MerchantOrderAction {
  final String label;
  final IconData icon;
  final Color color;
  final OrderStatus? nextStatus;
  final bool isContact;

  const MerchantOrderAction({
    required this.label,
    required this.icon,
    required this.color,
    this.nextStatus,
    this.isContact = false,
  });
}

List<MerchantOrderAction> merchantOrderActionsFor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingReview:
      return [
        MerchantOrderAction(
          label: AppLocalizations.of(context).contactCustomer,
          icon: Icons.phone_in_talk_outlined,
          color: const Color(0xff4D41DF),
          isContact: true,
        ),
        MerchantOrderAction(
          label: AppLocalizations.of(context).confirmOrder,
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xff0891B2),
          nextStatus: OrderStatus.confirmed,
        ),
        MerchantOrderAction(
          label: AppLocalizations.of(context).cancelOrder,
          icon: Icons.cancel_outlined,
          color: const Color(0xffE53E3E),
          nextStatus: OrderStatus.cancelled,
        ),
      ];
    case OrderStatus.confirmed:
      return [
        MerchantOrderAction(
          label: AppLocalizations.of(context).contactCustomer,
          icon: Icons.phone_in_talk_outlined,
          color: const Color(0xff4D41DF),
          isContact: true,
        ),
        MerchantOrderAction(
          label: AppLocalizations.of(context).confirmDelivery,
          icon: Icons.done_all_rounded,
          color: const Color(0xff00C896),
          nextStatus: OrderStatus.completed,
        ),
        MerchantOrderAction(
          label: AppLocalizations.of(context).cancelOrder,
          icon: Icons.cancel_outlined,
          color: const Color(0xffE53E3E),
          nextStatus: OrderStatus.cancelled,
        ),
      ];
    case OrderStatus.completed:
    case OrderStatus.cancelled:
      return [];
  }
}
