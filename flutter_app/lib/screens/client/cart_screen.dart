import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/client/checkout_screen.dart';
import 'package:ai_saas/shared/cart/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message, style: GoogleFonts.ibmPlexSans()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        final List<CartItem> items;
        final bool isLoading;

        if (state is CartLoading) {
          items = CartController.instance.items;
          isLoading = true;
        } else if (state is CartLoaded) {
          items = state.items;
          isLoading = false;
        } else if (state is CartUpdating) {
          items = state.items;
          isLoading = false;
        } else if (state is CartFailure) {
          items = state.items;
          isLoading = false;
        } else {
          items = CartController.instance.items;
          isLoading = false;
        }

        final showRetry = state is CartFailure;
        final total = state is CartLoaded
          ? state.total
          : CartController.instance.total;
        final itemCount = state is CartLoaded
          ? state.itemCount
          : CartController.instance.itemCount;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: _scaffoldBg,
            appBar: _buildAppBar(context, items),
            body: isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (showRetry)
                        _buildRetryBanner(
                            context, (state as CartFailure).message),
                      Expanded(
                        child: items.isEmpty
                            ? _buildEmptyState(context)
                          : _buildBody(context, items, total, itemCount),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, List<CartItem> items) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _textDark, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        AppLocalizations.of(context).shoppingCart,
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
      actions: [
        if (items.isNotEmpty)
          TextButton(
            onPressed: () =>
                context.read<CartBloc>().add(const CartCleared()),
            child: Text(
              AppLocalizations.of(context).clearAll,
              style: GoogleFonts.ibmPlexSans(
                color: Colors.redAccent,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    List<CartItem> items,
    double total,
    int itemCount,
  ) {

    return Column(
      children: [
        // Item count header
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).itemsInCart.replaceFirst('{count}', '$itemCount'),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  color: _textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) =>
                _buildCartItemCard(context, items[index]),
          ),
        ),

        // Order summary + checkout
        _buildOrderSummary(context, total),
      ],
    );
  }

  Widget _buildRetryBanner(BuildContext context, String message) {
    return MaterialBanner(
      content: Text(message, style: GoogleFonts.ibmPlexSans()),
      leading: const Icon(Icons.error_outline, color: Colors.redAccent),
      actions: [
        TextButton(
          onPressed: () => context
              .read<CartBloc>()
              .add(const CartLoadRequested()),
          child: Text(AppLocalizations.of(context).retry, style: GoogleFonts.ibmPlexSans()),
        ),
      ],
    );
  }

  // ── Cart Item Card ─────────────────────────────────────────────────────────
  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Container(
      padding: EdgeInsets.all(12.r),
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
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 70.w,
                    height: 70.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  )
                : _imageFallback(),
          ),

          SizedBox(width: 12.w),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  item.storeName,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11.sp, color: _textGray),
                ),
                SizedBox(height: 6.h),
                Text(
                  '₪${item.lineTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Column(
            children: [
              // Remove button
              GestureDetector(
                onTap: () {
                  if (item.serverItemId == null) return;
                  context
                      .read<CartBloc>()
                      .add(CartItemRemoved(item.serverItemId!));
                },
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16.sp, color: Colors.redAccent),
                ),
              ),
              SizedBox(height: 8.h),
              // Quantity row
              Row(
                children: [
                  _qtyButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _updateQuantity(context, item, item.quantity - 1),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '${item.quantity}',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10.w),
                  _qtyButton(
                    icon: Icons.add_rounded,
                    onTap: () => _updateQuantity(context, item, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateQuantity(BuildContext context, CartItem item, int quantity) {
    if (item.serverItemId == null) return;
    if (quantity < 1) {
      context.read<CartBloc>().add(CartItemRemoved(item.serverItemId!));
    } else {
      context.read<CartBloc>().add(CartItemQuantityUpdated(
            itemId: item.serverItemId!,
            quantity: quantity,
          ));
    }
  }

  Widget _qtyButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: const Color(0xffEDE9FF),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 14.sp, color: _primary),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 70.w,
      height: 70.w,
      color: const Color(0xffF0F1F5),
      child: Icon(Icons.shopping_bag_outlined,
          color: Colors.grey.shade400, size: 28.sp),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary(BuildContext context, double total) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).total,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              Text('₪${total.toStringAsFixed(0)}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                AppLocalizations.of(context).continueOrder,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48.sp,
              color: const Color(0xff4D41DF),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppLocalizations.of(context).emptyCart,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف منتجات من المتاجر المجاورة',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              color: const Color(0xff888888),
            ),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: 160.w,
            height: 46.h,
            child: ElevatedButton(
              onPressed: () => Navigator.maybePop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4D41DF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(
                'تصفح المتاجر',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
