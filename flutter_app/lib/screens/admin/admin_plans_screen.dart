import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_plans/admin_plans_bloc.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminPlansBloc>().add(const AdminPlansLoadRequested());
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
        context.read<AdminPlansBloc>().add(AdminPlansSearchChanged(value));
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
            'إدارة الخطط',
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
                  .read<AdminPlansBloc>()
                  .add(const AdminPlansLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAdminPlanForm(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('خطة جديدة'),
        ),
        body: BlocConsumer<AdminPlansBloc, AdminPlansState>(
          listener: (context, state) {
            if (state is AdminPlansFailure && state.previousPage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminPlansFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminPlansBloc>()
                      .add(const AdminPlansLoadRequested()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _PlansContent(
              page: page,
              loading: state is AdminPlansLoading,
              searchController: _searchController,
              onSearchChanged: _searchChanged,
              onStatusChanged: (status) => context
                  .read<AdminPlansBloc>()
                  .add(AdminPlansStatusFilterChanged(status)),
              onPageChanged: (pageNumber) => context
                  .read<AdminPlansBloc>()
                  .add(AdminPlansPageRequested(pageNumber)),
              onPlanTap: (plan) => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AdminPlanDetailsScreen(planId: plan.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AdminPlanPage? _pageFrom(AdminPlansState state) {
    if (state is AdminPlansLoaded) return state.page;
    if (state is AdminPlansLoading) return state.previousPage;
    if (state is AdminPlansFailure) return state.previousPage;
    return null;
  }
}

Future<void> showAdminPlanForm(
  BuildContext context, {
  AdminPlan? plan,
}) async {
  final nameController = TextEditingController(text: plan?.name ?? '');
  final displayNameController =
      TextEditingController(text: plan?.displayName ?? '');
  final monthlyController =
      TextEditingController(text: plan?.monthlyPrice.toStringAsFixed(2) ?? '');
  final yearlyController =
      TextEditingController(text: plan?.yearlyPrice.toStringAsFixed(2) ?? '');
  final aiLimitController =
      TextEditingController(text: plan?.aiUsageLimit?.toString() ?? '');
  final productLimitController =
      TextEditingController(text: plan?.productLimit?.toString() ?? '');
  final storeLimitController =
      TextEditingController(text: plan?.storeLimit.toString() ?? '1');
  final featuresController =
      TextEditingController(text: plan?.features.join(', ') ?? '');
  var status = plan?.status ?? 'active';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(plan == null ? 'إضافة خطة' : 'تعديل الخطة'),
        content: SizedBox(
          width: 420.w,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: nameController, label: 'المعرف'),
                _FormField(
                  controller: displayNameController,
                  label: 'اسم العرض',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: monthlyController,
                        label: 'السعر الشهري',
                        numeric: true,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _FormField(
                        controller: yearlyController,
                        label: 'السعر السنوي',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: aiLimitController,
                        label: 'حد AI (اختياري)',
                        numeric: true,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _FormField(
                        controller: productLimitController,
                        label: 'حد المنتجات (اختياري)',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                _FormField(
                  controller: storeLimitController,
                  label: 'حد المتاجر',
                  numeric: true,
                ),
                _FormField(
                  controller: featuresController,
                  label: 'المميزات (مفصولة بفاصلة)',
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('نشطة')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('غير نشطة'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final displayName = displayNameController.text.trim();
              final monthly = double.tryParse(monthlyController.text.trim());
              final yearly = double.tryParse(yearlyController.text.trim());
              final storeLimit = int.tryParse(storeLimitController.text.trim());
              if (name.isEmpty ||
                  displayName.isEmpty ||
                  monthly == null ||
                  yearly == null ||
                  storeLimit == null ||
                  storeLimit < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى إدخال القيم المطلوبة بشكل صحيح')),
                );
                return;
              }
              final features = featuresController.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList();
              final aiLimit = int.tryParse(aiLimitController.text.trim());
              final productLimit =
                  int.tryParse(productLimitController.text.trim());
              if (plan == null) {
                context.read<AdminPlansBloc>().add(
                      AdminPlanCreateRequested(
                        name: name,
                        displayName: displayName,
                        monthlyPrice: monthly,
                        yearlyPrice: yearly,
                        aiUsageLimit: aiLimit,
                        productLimit: productLimit,
                        storeLimit: storeLimit,
                        features: features,
                        status: status,
                      ),
                    );
              } else {
                context.read<AdminPlansBloc>().add(
                      AdminPlanUpdateRequested(
                        planId: plan.id,
                        name: name,
                        displayName: displayName,
                        monthlyPrice: monthly,
                        yearlyPrice: yearly,
                        aiUsageLimit: aiLimit,
                        productLimit: productLimit,
                        storeLimit: storeLimit,
                        features: features,
                        status: status,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: Text(plan == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    ),
  );
  for (final controller in [
    nameController,
    displayNameController,
    monthlyController,
    yearlyController,
    aiLimitController,
    productLimitController,
    storeLimitController,
    featuresController,
  ]) {
    controller.dispose();
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String label;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _PlansContent extends StatelessWidget {
  const _PlansContent({
    required this.page,
    required this.loading,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPageChanged,
    required this.onPlanTap,
  });

  final AdminPlanPage page;
  final bool loading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminPlan> onPlanTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الخطة',
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
          child: DropdownButtonFormField<String>(
            value: null,
            decoration: const InputDecoration(labelText: 'تصفية حسب الحالة'),
            items: const [
              DropdownMenuItem<String>(value: '', child: Text('كل الحالات')),
              DropdownMenuItem(value: 'active', child: Text('نشطة')),
              DropdownMenuItem(value: 'inactive', child: Text('غير نشطة')),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: page.isEmpty
              ? const EmptyState(
                  icon: Icons.card_membership_outlined,
                  title: 'لا توجد خطط',
                  subtitle: 'جرّب تغيير البحث أو الفلاتر.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  itemCount: page.plans.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final plan = page.plans[index];
                    return _PlanCard(
                      plan: plan,
                      onTap: () => onPlanTap(plan),
                    );
                  },
                ),
        ),
        if (page.pagination.lastPage > 1)
          _PlansPagination(
            pagination: page.pagination,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});

  final AdminPlan plan;
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
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(
                  Icons.card_membership_outlined,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
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
                      '${plan.monthlyPrice.toStringAsFixed(2)} شهرياً • ${plan.storeLimit} متجر',
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.textGray,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _PlanStatusBadge(status: plan.status),
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

class _PlanStatusBadge extends StatelessWidget {
  const _PlanStatusBadge({required this.status});

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
        active ? 'نشطة' : 'غير نشطة',
        style: GoogleFonts.ibmPlexSans(
          color: active ? AppColors.green : AppColors.red,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlansPagination extends StatelessWidget {
  const _PlansPagination({
    required this.pagination,
    required this.onPageChanged,
  });

  final AdminPlanPagination pagination;
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

class AdminPlanDetailsScreen extends StatefulWidget {
  const AdminPlanDetailsScreen({required this.planId, super.key});

  final String planId;

  @override
  State<AdminPlanDetailsScreen> createState() => _AdminPlanDetailsScreenState();
}

class _AdminPlanDetailsScreenState extends State<AdminPlanDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminPlansBloc>().add(
          AdminPlanDetailsRequested(widget.planId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الخطة')),
        body: BlocConsumer<AdminPlansBloc, AdminPlansState>(
          listener: (context, state) {
            if (state is AdminPlansFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final plan = _selectedFrom(state);
            if (plan == null) {
              if (state is AdminPlansFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context.read<AdminPlansBloc>().add(
                        AdminPlanDetailsRequested(widget.planId),
                      ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final loading = state is AdminPlansLoading;
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Icon(
                  Icons.card_membership_outlined,
                  size: 72.w,
                  color: AppColors.primary,
                ),
                SizedBox(height: 12.h),
                Text(
                  plan.displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.textDark,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  plan.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(color: AppColors.textGray),
                ),
                SizedBox(height: 10.h),
                Center(child: _PlanStatusBadge(status: plan.status)),
                SizedBox(height: 20.h),
                _PlanInfoCard(
                  title: 'الأسعار',
                  value:
                      '${plan.monthlyPrice.toStringAsFixed(2)} شهرياً • ${plan.yearlyPrice.toStringAsFixed(2)} سنوياً',
                  icon: Icons.payments_outlined,
                ),
                _PlanInfoCard(
                  title: 'الحدود',
                  value:
                      '${plan.storeLimit} متجر • ${plan.productLimit?.toString() ?? 'غير محدود'} منتج • ${plan.aiUsageLimit?.toString() ?? 'غير محدود'} استخدام AI',
                  icon: Icons.tune_rounded,
                ),
                if (plan.features.isNotEmpty)
                  _PlanInfoCard(
                    title: 'المميزات',
                    value: plan.features.join(' • '),
                    icon: Icons.check_circle_outline,
                  ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () => showAdminPlanForm(context, plan: plan),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل الخطة'),
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed:
                      loading ? null : () => _confirmDelete(context, plan),
                  icon: const Icon(Icons.delete_outline, color: AppColors.red),
                  label: const Text(
                    'حذف الخطة',
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

  AdminPlan? _selectedFrom(AdminPlansState state) {
    if (state is AdminPlansLoaded) return state.selectedPlan;
    if (state is AdminPlansLoading) return state.selectedPlan;
    if (state is AdminPlansFailure) return state.selectedPlan;
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, AdminPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الخطة؟'),
        content:
            Text('سيتم حذف «${plan.displayName}» نهائياً إذا لم تكن مستخدمة.'),
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
      context.read<AdminPlansBloc>().add(AdminPlanDeleteRequested(plan.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الحذف')),
      );
      Navigator.pop(context);
    }
  }
}

class _PlanInfoCard extends StatelessWidget {
  const _PlanInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
