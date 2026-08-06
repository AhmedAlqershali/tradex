import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── ProductShop ───────────────────────────────────────────────────────────────
//
// Full-width featured product card used in the shopper home.
//
// Fixes:
//   - Was using Image.asset (crashes if asset is missing); now uses ProductImage
//     which handles network URLs and local files with graceful fallback
//   - "أضف للسلة" button now accepts a callback via onAddToCart
//   - Price color uses Tradex primary instead of hardcoded green
// ─────────────────────────────────────────────────────────────────────────────

class ProductShop extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final String? badgeText;
  final VoidCallback? onAddToCart;

  const ProductShop({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    this.badgeText,
    this.onAddToCart,
  });

  /// Convenience factory that accepts a [Product] directly.
  factory ProductShop.fromProduct({
    required Product product,
    VoidCallback? onAddToCart,
    String? badgeText,
  }) {
    return ProductShop(
      imageUrl: product.imageUrl,
      title: product.name,
      description: product.description,
      price: '${product.price.toStringAsFixed(0)} ₪',
      badgeText: badgeText,
      onAddToCart: onAddToCart,
    );
  }

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with optional badge ────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20.r)),
                  child: SizedBox(
                    height: 200.h,
                    width: double.infinity,
                    child: ProductImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        badgeText!,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        price,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      color: const Color(0xff888888),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16.h),

                  // ── Add to cart button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
                      icon: Icon(Icons.shopping_bag_outlined, size: 18.sp),
                      label: Text(
                        'أضف للسلة',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
