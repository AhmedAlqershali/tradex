import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── FeaturedProductCard ──────────────────────────────────────────────────────
//
// Large "hero" product card shown at the top of the products section.
// ─────────────────────────────────────────────────────────────────────────────

class FeaturedProductCard extends StatelessWidget {
  final Product product;

  const FeaturedProductCard({super.key, required this.product});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✨ ${product.name}',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product.storeName,
                          style: TextStyle(
                              color: Colors.black45, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₪',
                    style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140.h,
              width: double.infinity,
              child: ProductImage(url: product.imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: SizedBox(
                width: double.infinity,
                height: 45.h,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(CartItemAdded(
                          productId: product.id,
                          quantity: 1,
                        ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).cartAdded),
                        backgroundColor: _primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r))),
                  child: Text(
                    AppLocalizations.of(context).addToCart,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SmallProductCard ─────────────────────────────────────────────────────────
//
// Compact product card shown in a 2-column grid below the featured card.
// ─────────────────────────────────────────────────────────────────────────────

class SmallProductCard extends StatelessWidget {
  final Product product;

  const SmallProductCard({super.key, required this.product});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFEFEFEF))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 90.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child:
                    ProductImage(url: product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              '${product.price.toStringAsFixed(0)} ₪',
              style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}
