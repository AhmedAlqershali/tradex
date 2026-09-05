import 'dart:io';

import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/merchant/add_product.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantProductsScreen extends StatefulWidget {
  const MerchantProductsScreen({super.key});

  @override
  State<MerchantProductsScreen> createState() =>
      _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends State<MerchantProductsScreen> {
  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const MerchantProductsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: _buildAppBar(context),
        body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.productDeleted,
                    style: GoogleFonts.ibmPlexSans(color: Colors.white)),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ));
              // Reload products after deletion.
              context.read<ProductBloc>().add(
                    const MerchantProductsLoadRequested(),
                  );
            } else if (state is ProductCreated || state is ProductUpdated) {
              context.read<ProductBloc>().add(
                    const MerchantProductsLoadRequested(),
                  );
            }
          },
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductFailure) {
              return _buildErrorState(context, state.message);
            }
            if (state is ProductsLoaded) {
              return state.products.isEmpty
                  ? _buildEmptyState(context)
                  : _buildList(context, state.products);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProduct()),
          ),
          backgroundColor: _primary,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: Text(
        l10n.myProducts,
        style: GoogleFonts.ibmPlexSans(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
       actions: [
         PopupMenuButton<String>(
           tooltip: l10n.filterStatus,
           icon: const Icon(Icons.filter_list_rounded, color: _textDark),
           onSelected: (value) {
             context.read<ProductBloc>().add(
                   MerchantProductsLoadRequested(
                     status: value == 'all' ? null : value,
                   ),
                 );
           },
           itemBuilder: (_) => [
             PopupMenuItem(value: 'all', child: Text(l10n.allProducts)),
             PopupMenuItem(value: 'active', child: Text(l10n.active)),
             PopupMenuItem(value: 'inactive', child: Text(l10n.inactive)),
             PopupMenuItem(value: 'out_of_stock', child: Text(l10n.outOfStock)),
           ],
         ),
       ],
    );
  }

  Widget _buildList(BuildContext context, List<Product> products) {
    return RefreshIndicator(
      onRefresh: () async => context
          .read<ProductBloc>()
          .add(const MerchantProductsLoadRequested()),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, i) => _buildProductCard(context, products[i]),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: _ProductThumb(url: product.imageUrl),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4.h),
                Text(product.category,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11.sp, color: const Color(0xff888888))),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    Text('₪${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: _primary)),
                    _buildVisibilityBadge(product.isVisible),
                    _buildStockBadge(product.quantity, product.status),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
               _iconBtn(
                 icon: Icons.edit_outlined,
                 color: _primary,
                 semanticLabel: l10n.editProduct,
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => AddProduct(product: product),
                   ),
                 ),
               ),
               SizedBox(height: 8.h),
              _iconBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                semanticLabel: l10n.deleteProduct,
                onTap: () => _confirmDelete(context, product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge(bool isVisible) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isVisible
            ? const Color(0xff22C55E).withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isVisible ? l10n.visible : l10n.hidden,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: isVisible ? const Color(0xff22C55E) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStockBadge(int quantity, String status) {
    final l10n = AppLocalizations.of(context);
    final isOutOfStock = status == 'out_of_stock' || quantity <= 0;
    final color = isOutOfStock
        ? Colors.redAccent
        : quantity <= 10
            ? Colors.orange
            : const Color(0xff64748B);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isOutOfStock ? l10n.outOfStock : '${l10n.stock}: $quantity',
        style: GoogleFonts.ibmPlexSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: l10n.textDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          title: Text(l10n.deleteProduct,
              style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.bold)),
          content: Text(
            l10n.deleteProductConfirm.replaceFirst('{name}', product.name),
            style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp, color: const Color(0xff4A4A4A)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: GoogleFonts.ibmPlexSans(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context
                    .read<ProductBloc>()
                    .add(ProductDeleteRequested(product.id));
              },
              child: Text(l10n.delete,
                  style: GoogleFonts.ibmPlexSans(
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 60.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: const Color(0xff888888))),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => context
                .read<ProductBloc>()
                .add(const MerchantProductsLoadRequested()),
            child: Text(l10n.retry, style: GoogleFonts.ibmPlexSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: const BoxDecoration(
                  color: Color(0xffEDE9FF), shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_outlined,
                  size: 46.sp, color: _primary),
            ),
            SizedBox(height: 20.h),
            Text(l10n.noProductsYet,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
            SizedBox(height: 8.h),
            Text(l10n.publishFirstProduct,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp, color: Colors.grey)),
            SizedBox(height: 28.h),
            SizedBox(
              width: 200.w,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProduct()),
                ),
                icon: Icon(Icons.add_rounded, size: 20.sp),
                label: Text(l10n.addNewProduct,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String url;
  const _ProductThumb({required this.url});

  bool get _isNetwork =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 72.w,
      height: 72.w,
      color: const Color(0xffF0F1F5),
      child: Center(
          child: Icon(Icons.shopping_bag_outlined,
              color: Colors.grey.shade400, size: 28.sp)),
    );

    if (url.isEmpty) return fallback;

    if (_isNetwork) {
      return Image.network(url,
          width: 72.w,
          height: 72.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    }

    try {
      return Image.file(File(url),
          width: 72.w,
          height: 72.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    } catch (_) {
      return fallback;
    }
  }
}
