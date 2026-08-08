import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_reviews/admin_reviews_bloc.dart';
import 'package:ai_saas/shared/models/admin_review_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _productIdController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    super.dispose();
  }

  void _loadReviews() {
    final productId = _productIdController.text.trim();
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم المنتج أولاً')),
      );
      return;
    }
    context.read<AdminReviewsBloc>().add(
          AdminReviewsLoadRequested(productId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'إدارة المراجعات',
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<AdminReviewsBloc, AdminReviewsState>(
          listener: (context, state) {
            if (state is AdminReviewsFailure && state.previousPage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final page = _pageFrom(state);
            return Column(
              children: [
                _ProductSelector(
                  controller: _productIdController,
                  onSubmit: _loadReviews,
                  hasLoadedProduct: page != null,
                ),
                Expanded(
                  child: _ReviewBody(
                    state: state,
                    page: page,
                    onRetry: _loadReviews,
                    onPageChanged: (pageNumber) => context
                        .read<AdminReviewsBloc>()
                        .add(AdminReviewsPageRequested(pageNumber)),
                    onDelete: _confirmDelete,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AdminReviewPage? _pageFrom(AdminReviewsState state) {
    if (state is AdminReviewsLoaded) return state.page;
    if (state is AdminReviewsLoading) return state.previousPage;
    if (state is AdminReviewsFailure) return state.previousPage;
    return null;
  }

  Future<void> _confirmDelete(AdminReview review) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المراجعة؟'),
        content: const Text('سيتم حذف هذه المراجعة نهائياً ولا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      context
          .read<AdminReviewsBloc>()
          .add(AdminReviewDeleteRequested(review.id));
    }
  }
}

class _ProductSelector extends StatelessWidget {
  const _ProductSelector({
    required this.controller,
    required this.onSubmit,
    required this.hasLoadedProduct,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool hasLoadedProduct;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر المنتج',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'المراجعات مرتبطة بمنتج محدد حسب واجهة Laravel الحالية.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رقم المنتج',
                      hintText: 'مثال: 12',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                SizedBox(width: 10.w),
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.search),
                  label: const Text('عرض'),
                ),
              ],
            ),
            if (hasLoadedProduct) ...[
              SizedBox(height: 8.h),
              Text(
                'الإجراءات المتاحة: عرض المراجعات وحذفها فقط.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.state,
    required this.page,
    required this.onRetry,
    required this.onPageChanged,
    required this.onDelete,
  });

  final AdminReviewsState state;
  final AdminReviewPage? page;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminReview> onDelete;

  @override
  Widget build(BuildContext context) {
    if (page == null) {
      if (state is AdminReviewsFailure) {
        return ErrorState(
          subtitle: (state as AdminReviewsFailure).message,
          onRetry: onRetry,
        );
      }
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'ابدأ باختيار منتج',
        subtitle: 'أدخل رقم المنتج لعرض مراجعاته.',
      );
    }

    final loading = state is AdminReviewsLoading;
    if (page!.isEmpty && !loading) {
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'لا توجد مراجعات',
        subtitle: 'لم يتم العثور على مراجعات لهذا المنتج.',
      );
    }

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            Text(
              '${page!.pagination.total} مراجعة',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            ...page!.reviews.map(
              (review) => _ReviewCard(review: review, onDelete: onDelete),
            ),
            _Pagination(
              pagination: page!.pagination,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
        if (loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onDelete});

  final AdminReview review;
  final ValueChanged<AdminReview> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundImage: review.reviewer?.avatar != null
                      ? NetworkImage(review.reviewer!.avatar!)
                      : null,
                  child: review.reviewer?.avatar == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    review.reviewer?.name ?? 'مستخدم غير معروف',
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => onDelete(review),
                  color: Colors.red,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 19.sp,
                    color: Colors.amber.shade700,
                  ),
                ),
                SizedBox(width: 8.w),
                Text('${review.rating}/5'),
              ],
            ),
            if (review.comment != null &&
                review.comment!.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                review.comment!,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14.sp,
                  color: AppColors.textDark,
                ),
              ),
            ],
            if (review.createdAt != null) ...[
              SizedBox(height: 8.h),
              Text(
                _formatDate(review.createdAt!),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pagination,
    required this.onPageChanged,
  });

  final AdminReviewPagination pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'الصفحة السابقة',
          onPressed: pagination.hasPrevious
              ? () => onPageChanged(pagination.currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
        Text('${pagination.currentPage} / ${pagination.lastPage}'),
        IconButton(
          tooltip: 'الصفحة التالية',
          onPressed: pagination.hasNext
              ? () => onPageChanged(pagination.currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}
