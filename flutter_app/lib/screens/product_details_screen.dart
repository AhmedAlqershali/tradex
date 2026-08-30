import 'package:ai_saas/core/localization/app_localizations.dart';
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
  late Product _product;
  bool _loading = true;
  String? _error;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductBloc>().add(ProductByIdRequested(_product.id));
      }
    });
  }

  void _increment() {
    if (_quantity < _product.quantity) setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart(BuildContext context) {
    if (!_product.isAvailable || _quantity > _product.quantity) return;
    // CartItemAdded calls POST /cart/items on the server so the item is
    // persisted before the user navigates to the cart screen.
    context.read<CartBloc>().add(CartItemAdded(
          productId: _product.id,
          quantity: _quantity,
        ));
  }

  void _toggleFavorite(BuildContext context) {
    context.read<FavoriteBloc>().add(FavoriteToggleRequested(_product));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductDetailLoaded &&
                state.product.id == _product.id) {
              setState(() {
                _product = state.product;
                _quantity = _product.quantity > 0 ? 1 : 0;
                _loading = false;
                _error = null;
              });
            } else if (state is ProductFailure && _loading) {
              setState(() {
                _loading = false;
                _error = state.message;
              });
            }
          },
        ),
        BlocListener<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(state.message, style: GoogleFonts.ibmPlexSans()),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xffF8F9FD),
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
              SizedBox(height: 12.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(fontSize: 15.sp),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  context
                      .read<ProductBloc>()
                      .add(ProductByIdRequested(_product.id));
                },
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
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
                      decoration: const BoxDecoration(color: Colors.white),
                      child: ProductImage(
                          url: _product.imageUrl, fit: BoxFit.cover),
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
                            isFav = favState.isFavorite(_product.id);
                          } else if (favState is FavoriteFailure) {
                            isFav = favState.products
                                .any((p) => p.id == _product.id);
                          }
                          return _buildCircularButton(
                            icon: isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            iconColor:
                                isFav ? Colors.redAccent : Colors.black54,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _product.name,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff1A1A1A),
                              ),
                            ),
                          ),
                          Text(
                            '₪${_product.price.toStringAsFixed(0)}',
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
                              size: 14.sp, color: const Color(0xff888888)),
                          SizedBox(width: 4.w),
                          Text(
                            _product.storeName,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13.sp,
                              color: const Color(0xff888888),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      if (_product.description.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context).description,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1A1A1A),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _product.description,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.sp,
                            color: const Color(0xff555555),
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      if (!_product.isAvailable)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Text(
                            AppLocalizations.of(context).productUnavailable,
                            style: GoogleFonts.ibmPlexSans(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Quantity selector
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context).quantityLabel,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          _buildQtyButton(
                            Icons.remove_rounded,
                            _decrement,
                            enabled: _product.isAvailable,
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            '$_quantity',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          _buildQtyButton(
                            Icons.add_rounded,
                            _increment,
                            enabled: _product.isAvailable &&
                                _quantity < _product.quantity,
                          ),
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
              onPressed: _product.isAvailable && _quantity > 0
                  ? () => _addToCart(context)
                  : null,
              icon: Icon(Icons.shopping_cart_outlined, size: 20.sp),
              label: Text(
                _product.isAvailable
                    ? 'إضافة إلى السلة • ₪${(_product.price * _quantity).toStringAsFixed(0)}'
                    : 'غير متوفر حالياً',
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

  Widget _buildQtyButton(
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xffEDE9FF) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: enabled ? const Color(0xff4D41DF) : Colors.grey,
        ),
      ),
    );
  }
}
