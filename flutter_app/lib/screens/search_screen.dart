import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/services/category_service.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialCategoryId;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.initialCategoryId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // ignore: unused_field — reserved for future region-filter feature
  final String _selectedRegion = 'المنطقة';
  String _selectedStoreCategory = '';
  String? _selectedCategoryId;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryListRequested());
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchQuery = widget.initialQuery!;
      _searchController.text = widget.initialQuery!;
      // Trigger search immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBloc>().add(ProductSearchRequested(_searchQuery));
      });
    } else if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      _selectedStoreCategory = widget.initialCategory ?? '';
      _selectedCategoryId = widget.initialCategoryId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBloc>().add(ProductsLoadRequested(
              category: _selectedStoreCategory,
              categoryId: _selectedCategoryId,
            ));
      });
    } else if (widget.initialCategory != null &&
        widget.initialCategory!.isNotEmpty) {
      _selectedStoreCategory = widget.initialCategory!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBloc>().add(ProductsLoadRequested(
              category: _selectedStoreCategory,
            ));
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBloc>().add(const ProductsLoadRequested());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    if (query.trim().isEmpty) {
      context.read<ProductBloc>().add(ProductsLoadRequested(
            category: _selectedStoreCategory.isNotEmpty
                ? _selectedStoreCategory
                : null,
          ));
    } else {
      context.read<ProductBloc>().add(ProductSearchRequested(query.trim()));
    }
  }

  void _onCategorySelected(String category) {
    final options = context.read<CategoryBloc>().state is CategoriesLoaded
        ? (context.read<CategoryBloc>().state as CategoriesLoaded).options
        : const <CategoryOption>[];
    final selected = options.where((option) => option.name == category);
    setState(() {
      _selectedStoreCategory =
          _selectedStoreCategory == category ? '' : category;
      _selectedCategoryId = _selectedStoreCategory.isEmpty || selected.isEmpty
          ? null
          : selected.first.id;
    });
    context.read<ProductBloc>().add(ProductsLoadRequested(
          category:
              _selectedStoreCategory.isNotEmpty ? _selectedStoreCategory : null,
          categoryId: _selectedCategoryId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        body: SafeArea(
          child: Column(
            children: [
              // ── Search bar ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xffEFEFEF)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منتج أو متجر...',
                            hintStyle: GoogleFonts.ibmPlexSans(
                                fontSize: 13.sp,
                                color: const Color(0xffAAAAAA)),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20.sp, color: const Color(0xffAAAAAA)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h, horizontal: 12.w),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        size: 18.sp,
                                        color: const Color(0xffAAAAAA)),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _buildFilterButton(),
                  ],
                ),
              ),

              // ── Category chips ──
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, categoryState) {
                  if (categoryState is! CategoriesLoaded ||
                      categoryState.options.isEmpty) {
                    return const SizedBox(height: 38);
                  }
                  final options = categoryState.options;
                  return SizedBox(
                    height: 38.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = _selectedCategoryId == option.id;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(option.name),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xff4D41DF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xff4D41DF)
                                    : const Color(0xffEFEFEF),
                              ),
                            ),
                            child: Text(
                              option.name,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12.sp,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xff555555),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: 12.h),

              // ── Results ──
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<Product> products = [];
                    if (state is ProductsLoaded) {
                      products = state.products;
                    } else if (state is ProductSearchResult) {
                      products = state.results;
                    }

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 60.sp, color: Colors.grey.shade300),
                            SizedBox(height: 12.h),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا توجد منتجات'
                                  : 'لا توجد نتائج لـ "$_searchQuery"',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 14.sp,
                                  color: const Color(0xff888888)),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(context, products[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _showMainFilterBottomSheet,
      child: Container(
        width: 46.w,
        height: 46.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xffEFEFEF)),
        ),
        child: Icon(Icons.tune_rounded,
            size: 20.sp, color: const Color(0xff888888)),
      ),
    );
  }

  void _showMainFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xfffcfdff),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              children: [
                Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2.r))),
                SizedBox(height: 12.h),
                Text('اختر فئة المتجر',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0d1e3d))),
                SizedBox(height: 16.h),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 1.2,
                    children: _categoryOptions(context).map((option) {
                      final isSelected = _selectedCategoryId == option.id;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _onCategorySelected(option.name);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff4D41DF)
                                    .withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: isSelected
                                    ? const Color(0xff4D41DF)
                                    : const Color(0xffEFEFEF)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 22.sp,
                                  color: isSelected
                                      ? const Color(0xff4D41DF)
                                      : const Color(0xff888888)),
                              SizedBox(height: 4.h),
                              Text(option.name,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 10.sp,
                                      color: isSelected
                                          ? const Color(0xff4D41DF)
                                          : const Color(0xff555555),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CategoryOption> _categoryOptions(BuildContext context) {
    final state = context.read<CategoryBloc>().state;
    return state is CategoriesLoaded ? state.options : const [];
  }

  Widget _buildProductCard(BuildContext context, Product product) {
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
                  SizedBox(height: 6.h),
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
                            color:
                                const Color(0xff4D41DF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r)),
                        child: Icon(Icons.add_rounded,
                            size: 16.sp, color: const Color(0xff4D41DF)),
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
