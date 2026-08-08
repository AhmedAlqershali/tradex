import 'dart:async';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_products/admin_products_bloc.dart';
import 'package:ai_saas/shared/models/admin_product_model.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminProductsBloc>().add(const AdminProductsLoadRequested());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context
            .read<AdminProductsBloc>()
            .add(AdminProductsSearchChanged(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'مراقبة المنتجات',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => context
                  .read<AdminProductsBloc>()
                  .add(const AdminProductsLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<AdminProductsBloc, AdminProductsState>(
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminProductsFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminProductsBloc>()
                      .add(const AdminProductsLoadRequested()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (page.isEmpty && state is! AdminProductsLoading) {
              return Column(
                children: [
                  _Filters(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    status: null,
                    onStatusChanged: (status) => context
                        .read<AdminProductsBloc>()
                        .add(AdminProductsStatusChanged(status)),
                  ),
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'لا توجد منتجات',
                      subtitle: 'ستظهر المنتجات عند توفرها في المتاجر.',
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _Filters(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  status: null,
                  onStatusChanged: (status) => context
                      .read<AdminProductsBloc>()
                      .add(AdminProductsStatusChanged(status)),
                ),
                if (state is AdminProductsLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    itemCount: page.products.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final product = page.products[index];
                      return _ProductTile(
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => AdminProductDetailsScreen(
                              productId: product.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _Pagination(
                  currentPage: page.pagination.currentPage,
                  lastPage: page.pagination.lastPage,
                  onPageChanged: (value) => context
                      .read<AdminProductsBloc>()
                      .add(AdminProductsPageRequested(value)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AdminProductPage? _pageFrom(AdminProductsState state) {
    if (state is AdminProductsLoaded) return state.page;
    if (state is AdminProductsLoading) return state.previousPage;
    if (state is AdminProductsFailure) return state.previousPage;
    return null;
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.onChanged,
    required this.status,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? status;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                labelText: 'بحث',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 118.w,
            child: DropdownButtonFormField<String>(
              value: status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: '', child: Text('الكل')),
                DropdownMenuItem(value: 'active', child: Text('نشط')),
                DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                DropdownMenuItem(
                  value: 'out_of_stock',
                  child: Text('نفد المخزون'),
                ),
              ],
              onChanged: (value) => onStatusChanged(
                  value == null || value.isEmpty ? null : value),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: product.imageUrl.isEmpty
            ? const CircleAvatar(child: Icon(Icons.inventory_2_outlined))
            : CircleAvatar(backgroundImage: NetworkImage(product.imageUrl)),
        title: Text(
          product.name.isEmpty ? 'منتج بدون اسم' : product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (product.storeName.isNotEmpty) product.storeName,
            if (product.category.isNotEmpty) product.category,
            product.isVisible ? 'نشط' : 'غير نشط',
          ].join(' • '),
        ),
        trailing: Text(
          product.price.toStringAsFixed(2),
          style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text('$currentPage / $lastPage'),
          IconButton(
            onPressed: currentPage < lastPage
                ? () => onPageChanged(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class AdminProductDetailsScreen extends StatefulWidget {
  const AdminProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  State<AdminProductDetailsScreen> createState() =>
      _AdminProductDetailsScreenState();
}

class _AdminProductDetailsScreenState extends State<AdminProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<AdminProductsBloc>()
        .add(AdminProductDetailsRequested(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: BlocBuilder<AdminProductsBloc, AdminProductsState>(
          builder: (context, state) {
            Product? product;
            if (state is AdminProductsLoaded) product = state.selectedProduct;
            if (state is AdminProductsLoading) product = state.selectedProduct;
            if (state is AdminProductsFailure) product = state.selectedProduct;
            if (product == null) {
              if (state is AdminProductsFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context.read<AdminProductsBloc>().add(
                        AdminProductDetailsRequested(widget.productId),
                      ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _ProductTile(product: product, onTap: () {}),
                SizedBox(height: 12.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.description.isEmpty
                              ? 'لا يوجد وصف'
                              : product.description,
                        ),
                        SizedBox(height: 12.h),
                        Text('المعرف: ${product.id}'),
                        if (product.category.isNotEmpty)
                          Text('التصنيف: ${product.category}'),
                        Text(
                          'تاريخ الإضافة: ${product.createdAt.toLocal().toString().split(' ').first}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
