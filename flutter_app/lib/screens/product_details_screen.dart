import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart(BuildContext context) {
    // CartItemAdded calls POST /cart/items on the server so the item is
    // persisted before the user navigates to the cart screen.
    context.read<CartBloc>().add(CartItemAdded(
          productId: widget.product.id,
          quantity: _quantity,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Text(
              'تمت الإضافة إلى السلة',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xff4D41DF),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(BuildContext context) {
    context
        .read<FavoriteBloc>()
        .add(FavoriteToggleRequested(widget.product));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Product image + floating buttons ──
                    Stack(
                      children: [
                        Container(
                          height: 380.h,
                          width: double.infinity,
                          decoration:
                              const BoxDecoration(color: Colors.white),
                          child: ProductImage(
                              url: widget.product.imageUrl,
                              fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 40.h,
                          right: 16.w,
                          child: _buildCircularButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.maybePop(context),
                          ),
                        ),
                        Positioned(
                          top: 40.h,
                          left: 16.w,
                          child: BlocBuilder<FavoriteBloc, FavoriteState>(
                            builder: (context, favState) {
                              bool isFav = false;
                              if (favState is FavoriteLoaded) {
                                isFav = favState.isFavorite(widget.product.id);
                              } else if (favState is FavoriteFailure) {
                                isFav = favState.products
                                    .any((p) => p.id == widget.product.id);
                              }
                              return _buildCircularButton(
                                icon: isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: isFav
                                    ? Colors.redAccent
                                    : Colors.black54,
                                onTap: () => _toggleFavorite(context),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── Product details ──
                    Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product.name,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff1A1A1A),
                                  ),
                                ),
                              ),
                              Text(
                                '₪${widget.product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff4D41DF),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          Row(
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 14.sp,
                                  color: const Color(0xff888888)),
                              SizedBox(width: 4.w),
                              Text(
                                widget.product.storeName,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13.sp,
                                  color: const Color(0xff888888),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          if (widget.product.description.isNotEmpty) ...[
                            Text(
                              'الوصف',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff1A1A1A),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              widget.product.description,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14.sp,
                                color: const Color(0xff555555),
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],

                          // Quantity selector
                          Row(
                            children: [
                              Text(
                                'الكمية',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff1A1A1A),
                                ),
                              ),
                              const Spacer(),
                              _buildQtyButton(
                                  Icons.remove_rounded, _decrement),
                              SizedBox(width: 16.w),
                              Text(
                                '$_quantity',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              _buildQtyButton(Icons.add_rounded, _increment),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Add to cart button ──
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: Icon(Icons.shopping_cart_outlined, size: 20.sp),
                  label: Text(
                    'إضافة إلى السلة • ₪${(widget.product.price * _quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 15.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4D41DF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    Color iconColor = Colors.black54,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18.sp, color: iconColor),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xffEDE9FF),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 18.sp, color: const Color(0xff4D41DF)),
      ),
    );
  }
}
