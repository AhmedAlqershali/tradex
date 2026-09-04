import 'package:ai_saas/core/localization/app_localizations.dart';
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
  StoreModel? _serverStore;
  List<Product> _products = const [];
  String? _storeError;
  String? _productsError;
  bool _storeLoading = true;
  bool _productsLoading = false;

  String? get _storeId => widget.store.id;

  @override
  void initState() {
    super.initState();
    final storeId = _storeId;
    if (storeId == null || storeId.isEmpty) {
      _storeLoading = false;
      _storeError = AppLocalizations.of(context).storeSelectionRequired;
      return;
    }

    // The list item is only the navigation input. Reload the selected store so
    // this screen always reflects Laravel's current record.
    context.read<StoreBloc>().add(StoreByIdRequested(storeId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xff4D41DF);
    const Color textColor = Color(0xff1A1A1A);
    const Color subTextColor = Color(0xff718096);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAF1).withValues(alpha: 0.97),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            l10n.store,
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
        body: BlocListener<StoreBloc, StoreState>(
          listener: _handleStoreState,
          child: _buildBody(primaryColor, textColor, subTextColor),
        ),
      ),
    );
  }

  void _handleStoreState(BuildContext context, StoreState state) {
    if (state is StoreDetailLoaded && state.store.id == _storeId) {
      setState(() {
        _serverStore = state.store;
        _storeLoading = false;
        _storeError = null;
        _productsLoading = true;
        _productsError = null;
      });
      context.read<StoreBloc>().add(StoreProductsLoadRequested(_storeId!));
      return;
    }

    if (state is StoreProductsLoaded && state.storeId == _storeId) {
      setState(() {
        _products = state.products;
        _productsLoading = false;
        _productsError = null;
      });
      return;
    }

    if (state is StoreFailure) {
      setState(() {
        if (_serverStore == null) {
          _storeLoading = false;
          _storeError = state.message;
        } else {
          _productsLoading = false;
          _productsError = state.message;
        }
      });
    }
  }

  Widget _buildBody(Color primaryColor, Color textColor, Color subTextColor) {
    if (_storeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_storeError != null) {
      return _buildErrorState(
        _storeError!,
        () {
          final storeId = _storeId;
          if (storeId == null || storeId.isEmpty) return;
          setState(() {
            _storeLoading = true;
            _storeError = null;
          });
          context.read<StoreBloc>().add(StoreByIdRequested(storeId));
        },
      );
    }

    final store = _serverStore;
    if (store == null) {
      return _buildErrorState(AppLocalizations.of(context).unableLoadStoreData, () {
        context.read<StoreBloc>().add(StoreByIdRequested(_storeId!));
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Store hero image ───
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: store.imageUrl.isEmpty
                  ? _storeImagePlaceholder(180.h)
                  : Image.network(
                      store.imageUrl,
                      height: 180.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _storeImagePlaceholder(180.h),
                    ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),

                // ─── Store name + rating ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        store.title,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (store.rating != null)
                      _buildRatingBadge(store.rating!, primaryColor),
                  ],
                ),

                SizedBox(height: 8.h),

                Text(
                  store.subTitle,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    color: subTextColor,
                    height: 1.5,
                  ),
                ),

                if (store.location != null && store.location!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14.sp, color: subTextColor),
                      SizedBox(width: 4.w),
                      Text(
                        store.location!,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13.sp, color: subTextColor),
                      ),
                    ],
                  ),
                ],

                if (store.phone != null && store.phone!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 14.sp, color: subTextColor),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          store.phone!,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 13.sp, color: subTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 16.h),

                // ─── Products section ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).storeProducts,
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
          if (_productsLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_productsError != null)
            _buildProductsError()
          else if (_products.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Center(
                child: Text(AppLocalizations.of(context).noProductsInStore,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp, color: const Color(0xff888888))),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) => _buildProductCard(
                    context, _products[index], primaryColor, textColor),
              ),
            ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56.sp, color: Colors.grey.shade400),
            SizedBox(height: 14.h),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp, color: const Color(0xff888888))),
            SizedBox(height: 18.h),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry, style: GoogleFonts.ibmPlexSans()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsError() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      child: Column(
        children: [
          Text(_productsError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: const Color(0xff888888))),
          SizedBox(height: 10.h),
          TextButton(
            onPressed: () {
              setState(() {
                _productsLoading = true;
                _productsError = null;
              });
              context
                  .read<StoreBloc>()
                  .add(StoreProductsLoadRequested(_storeId!));
            },
            child: Text('إعادة المحاولة', style: GoogleFonts.ibmPlexSans()),
          ),
        ],
      ),
    );
  }

  Widget _storeImagePlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.storefront_outlined, color: Colors.grey),
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
          Icon(Icons.star_rounded, size: 14.sp, color: const Color(0xffF59E0B)),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
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
