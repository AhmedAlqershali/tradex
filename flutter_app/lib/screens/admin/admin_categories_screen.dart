import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_categories/admin_categories_bloc.dart';
import 'package:ai_saas/shared/models/admin_category_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminCategoriesBloc>().add(
          const AdminCategoriesLoadRequested(),
        );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<AdminCategoriesBloc>().add(
              AdminCategoriesSearchChanged(value),
            );
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
            'إدارة التصنيفات',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => context.read<AdminCategoriesBloc>().add(
                    const AdminCategoriesLoadRequested(),
                  ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCategoryForm(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('تصنيف جديد'),
        ),
        body: BlocConsumer<AdminCategoriesBloc, AdminCategoriesState>(
          listener: (context, state) {
            if (state is AdminCategoriesFailure && state.previousPage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminCategoriesFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context.read<AdminCategoriesBloc>().add(
                        const AdminCategoriesLoadRequested(),
                      ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }

            return _CategoriesContent(
              page: page,
              loading: state is AdminCategoriesLoading,
              searchController: _searchController,
              onSearchChanged: _searchChanged,
              onStatusChanged: (status) => context
                  .read<AdminCategoriesBloc>()
                  .add(AdminCategoriesStatusFilterChanged(status)),
              onPageChanged: (pageNumber) => context
                  .read<AdminCategoriesBloc>()
                  .add(AdminCategoriesPageRequested(pageNumber)),
              onCategoryTap: (category) => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AdminCategoryDetailsScreen(
                    categoryId: category.id,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AdminCategoryPage? _pageFrom(AdminCategoriesState state) {
    if (state is AdminCategoriesLoaded) return state.page;
    if (state is AdminCategoriesLoading) return state.previousPage;
    if (state is AdminCategoriesFailure) return state.previousPage;
    return null;
  }

  Future<void> _showCategoryForm(
    BuildContext context, {
    AdminCategory? category,
  }) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    var status = category?.status ?? 'active';
    String? imagePath;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'إضافة تصنيف' : 'تعديل التصنيف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم التصنيف'),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setDialogState(() => imagePath = picked.path);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    imagePath == null
                        ? 'اختيار صورة (اختياري)'
                        : 'تم اختيار صورة',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                if (category == null) {
                  context.read<AdminCategoriesBloc>().add(
                        AdminCategoryCreateRequested(
                          name: name,
                          status: status,
                          imagePath: imagePath,
                        ),
                      );
                } else {
                  context.read<AdminCategoriesBloc>().add(
                        AdminCategoryUpdateRequested(
                          categoryId: category.id,
                          name: name,
                          status: status,
                          imagePath: imagePath,
                        ),
                      );
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(category == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result != true || !mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(category == null
            ? 'تم إنشاء التصنيف بنجاح'
            : 'تم تحديث التصنيف بنجاح'),
      ),
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({
    required this.page,
    required this.loading,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPageChanged,
    required this.onCategoryTap,
  });

  final AdminCategoryPage page;
  final bool loading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث باسم التصنيف',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: DropdownButtonFormField<String?>(
            value: null,
            decoration: const InputDecoration(labelText: 'تصفية حسب الحالة'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('كل الحالات')),
              DropdownMenuItem(value: 'active', child: Text('نشط')),
              DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: page.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'لا يوجد تصنيفات',
                  subtitle: 'جرّب تغيير البحث أو الفلاتر.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  itemCount: page.categories.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final category = page.categories[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () => onCategoryTap(category),
                    );
                  },
                ),
        ),
        if (page.pagination.lastPage > 1)
          _CategoryPagination(
            pagination: page.pagination,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final AdminCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: ProductImage(
                  url: category.image ?? '',
                  width: 54.w,
                  height: 54.w,
                  fallback: Container(
                    width: 54.w,
                    height: 54.w,
                    color: AppColors.primarySoft,
                    child: const Icon(
                      Icons.category_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.textDark,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${category.productsCount} منتجات',
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.textGray,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: category.status),
              SizedBox(width: 4.w),
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: active
            ? AppColors.green.withValues(alpha: .12)
            : AppColors.red.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        active ? 'نشط' : 'غير نشط',
        style: GoogleFonts.ibmPlexSans(
          color: active ? AppColors.green : AppColors.red,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CategoryPagination extends StatelessWidget {
  const _CategoryPagination({
    required this.pagination,
    required this.onPageChanged,
  });

  final AdminCategoryPagination pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 84.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: pagination.hasPrevious
                ? () => onPageChanged(pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text(
            '${pagination.currentPage} / ${pagination.lastPage}',
            style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: pagination.hasNext
                ? () => onPageChanged(pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class AdminCategoryDetailsScreen extends StatefulWidget {
  const AdminCategoryDetailsScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  State<AdminCategoryDetailsScreen> createState() =>
      _AdminCategoryDetailsScreenState();
}

class _AdminCategoryDetailsScreenState
    extends State<AdminCategoryDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCategoriesBloc>().add(
          AdminCategoryDetailsRequested(widget.categoryId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل التصنيف')),
        body: BlocConsumer<AdminCategoriesBloc, AdminCategoriesState>(
          listener: (context, state) {
            if (state is AdminCategoriesFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is AdminCategoriesLoaded &&
                state.selectedCategory == null &&
                mounted) {
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            final category = _selectedFrom(state);
            if (category == null) {
              if (state is AdminCategoriesFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context.read<AdminCategoriesBloc>().add(
                        AdminCategoryDetailsRequested(widget.categoryId),
                      ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final loading = state is AdminCategoriesLoading;
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: ProductImage(
                      url: category.image ?? '',
                      width: 140.w,
                      height: 140.w,
                      fallback: Container(
                        width: 140.w,
                        height: 140.w,
                        color: AppColors.primarySoft,
                        child: const Icon(
                          Icons.category_outlined,
                          size: 58,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.textDark,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Center(child: _StatusBadge(status: category.status)),
                SizedBox(height: 20.h),
                _InfoCard(
                  label: 'المنتجات المرتبطة',
                  value: '${category.productsCount}',
                  icon: Icons.inventory_2_outlined,
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () => _showCategoryForm(context, category),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل التصنيف'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed:
                      loading ? null : () => _confirmDelete(context, category),
                  icon: const Icon(Icons.delete_outline, color: AppColors.red),
                  label: const Text(
                    'حذف التصنيف',
                    style: TextStyle(color: AppColors.red),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AdminCategory? _selectedFrom(AdminCategoriesState state) {
    if (state is AdminCategoriesLoaded) return state.selectedCategory;
    if (state is AdminCategoriesLoading) return state.selectedCategory;
    if (state is AdminCategoriesFailure) return state.selectedCategory;
    return null;
  }

  Future<void> _showCategoryForm(
    BuildContext context,
    AdminCategory category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    var status = category.status;
    String? imagePath;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل التصنيف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم التصنيف'),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setDialogState(() => imagePath = picked.path);
                  }
                },
                icon: const Icon(Icons.image_outlined),
                label:
                    Text(imagePath == null ? 'تغيير الصورة' : 'تم اختيار صورة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                context.read<AdminCategoriesBloc>().add(
                      AdminCategoryUpdateRequested(
                        categoryId: category.id,
                        name: name,
                        status: status,
                        imagePath: imagePath,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التصنيف؟'),
        content: Text('سيتم حذف «${category.name}» نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminCategoriesBloc>().add(
            AdminCategoryDeleteRequested(category.id),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الحذف')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading:
            const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
