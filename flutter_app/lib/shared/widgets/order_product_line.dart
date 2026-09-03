import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── OrderProductLine ─────────────────────────────────────────────────────────
//
// A single product row used inside order detail cards.
// Identical between MerchantOrderDetailsScreen, ClientOrderDetailsScreen,
// and CheckoutScreen — extracted here to eliminate the triplication.
// ─────────────────────────────────────────────────────────────────────────────

class OrderProductLine extends StatelessWidget {
  final AppOrderProduct product;

  const OrderProductLine({super.key, required this.product});

  static const Color _primary  = Color(0xff4D41DF);
  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 44.w,
                    height: 44.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
          SizedBox(width: 12.w),

          // Name + store
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.storeName,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11.sp, color: _textGray),
                ),
              ],
            ),
          ),

          // Price + qty
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.lineTotal.toStringAsFixed(0)} ₪',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              Text(
                '${product.quantity} × ${product.price.toStringAsFixed(0)}',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 10.sp, color: _textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 44.w,
      height: 44.w,
      color: const Color(0xffEDE9FF),
      child: Icon(Icons.shopping_bag_outlined,
          color: _primary, size: 22.sp),
    );
  }
}

// ─── OrderProductsCard ────────────────────────────────────────────────────────
//
// Full section card: title + list of OrderProductLine rows + divider + total.
// Used in both merchant and client order detail screens.
// ─────────────────────────────────────────────────────────────────────────────

class OrderProductsCard extends StatelessWidget {
  final List<AppOrderProduct> products;
  final double total;

  const OrderProductsCard({
    super.key,
    required this.products,
    required this.total,
  });

  static const Color _primary  = Color(0xff4D41DF);
  static const Color _textDark = Color(0xff1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            children: [
              Icon(Icons.shopping_bag_outlined, size: 16.sp, color: _primary),
              SizedBox(width: 6.w),
              Text(
                'المنتجات',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...products.map((p) => OrderProductLine(product: p)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(height: 1.h, color: const Color(0xffEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ₪',
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
    );
  }
}
