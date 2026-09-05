import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// RecentlyArrivedScreen
// ==========================================
class RecentlyArrivedScreen extends StatefulWidget {
  const RecentlyArrivedScreen({super.key});

  @override
  State<RecentlyArrivedScreen> createState() => _RecentlyArrivedScreenState();
}

class _RecentlyArrivedScreenState extends State<RecentlyArrivedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: const Color(0xff1a1a1a), size: 20.sp),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            l10n.newArrivals,
            style: GoogleFonts.ibmPlexSans(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 60.sp, color: Colors.grey.shade400),
                      SizedBox(height: 16.h),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13.sp, color: const Color(0xff707070)),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: () => context
                            .read<ProductBloc>()
                            .add(const ProductsLoadRequested()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            List<Product> products = [];
            if (state is ProductsLoaded) {
              products = List.of(state.products)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 60.sp, color: Colors.black12),
                    SizedBox(height: 12.h),
                    Text(l10n.noRecentProducts,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.sp, color: Colors.black38)),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: EdgeInsets.all(16.r),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  ProductGridCard(product: products[index]),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// ProductGridCard
// ==========================================
class ProductGridCard extends StatelessWidget {
  final Product product;

  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.r)),
                    child: ProductImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xff4D41DF),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(l10n.featured,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 9.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
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
                            color: const Color(0xff4D41DF)),
                      ),
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                            color: const Color(0xff4D41DF)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r)),
                        child: Icon(Icons.add_rounded,
                            size: 16.sp,
                            color: const Color(0xff4D41DF)),
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
