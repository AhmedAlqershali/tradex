import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreDetailsScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final storeId = widget.store.id;
    if (storeId != null && storeId.isNotEmpty) {
      context
          .read<StoreBloc>()
          .add(StoreProductsLoadRequested(storeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xff4D41DF);
    const Color textColor    = Color(0xff1A1A1A);
    const Color subTextColor = Color(0xff718096);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAF1).withValues(alpha: 0.97),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            'تفاصيل المتجر',
            style: GoogleFonts.ibmPlexSans(
              color: textColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 18.sp),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Store hero image ───
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(
                    widget.store.imageUrl,
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180.h,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // ─── Store name + rating ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.store.title,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.store.rating != null)
                          _buildRatingBadge(widget.store.rating!,
                              primaryColor),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      widget.store.subTitle,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.sp,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),

                    if (widget.store.location != null) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14.sp, color: subTextColor),
                          SizedBox(width: 4.w),
                          Text(
                            widget.store.location!,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 13.sp, color: subTextColor),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // ─── Products section ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'منتجات المتجر',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),

              // ─── Products grid ───
              BlocBuilder<StoreBloc, StoreState>(
                builder: (context, state) {
                  if (state is StoreLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  List<Product> products = [];
                  if (state is StoreProductsLoaded &&
                      state.storeId == widget.store.id) {
                    products = state.products;
                  }

                  if (products.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 24.h),
                      child: Center(
                        child: Text('لا توجد منتجات في هذا المتجر',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 14.sp,
                                color: const Color(0xff888888))),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(context, products[index],
                              primaryColor, textColor),
                    ),
                  );
                },
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xffFFF8E7),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded,
              size: 14.sp, color: const Color(0xffF59E0B)),
          SizedBox(width: 3.w),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.ibmPlexSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xffF59E0B)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product,
      Color primaryColor, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(14.r)),
                child: ProductImage(
                  url: product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff2D3748),
                        height: 1.2),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₪${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r)),
                        child: Icon(Icons.add_rounded,
                            size: 16.sp, color: primaryColor),
                      ),
                    ],
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
