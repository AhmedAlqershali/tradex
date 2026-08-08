import 'dart:async';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_merchants/admin_merchants_bloc.dart';
import 'package:ai_saas/shared/models/admin_merchant_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMerchantsScreen extends StatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  State<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends State<AdminMerchantsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<AdminMerchantsBloc>().add(const AdminMerchantsLoadRequested());
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
        context.read<AdminMerchantsBloc>().add(
              AdminMerchantsSearchChanged(value),
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
            'إدارة التجار',
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
                  .read<AdminMerchantsBloc>()
                  .add(const AdminMerchantsLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<AdminMerchantsBloc, AdminMerchantsState>(
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminMerchantsFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminMerchantsBloc>()
                      .add(const AdminMerchantsLoadRequested()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }

            return _MerchantsContent(
              page: page,
              loading: state is AdminMerchantsLoading,
              searchController: _searchController,
              onSearchChanged: _searchChanged,
              onStatusChanged: (value) => context
                  .read<AdminMerchantsBloc>()
                  .add(AdminMerchantsStatusFilterChanged(value)),
              onPageChanged: (value) => context
                  .read<AdminMerchantsBloc>()
                  .add(AdminMerchantsPageRequested(value)),
            );
          },
        ),
      ),
    );
  }

  AdminMerchantPage? _pageFrom(AdminMerchantsState state) {
    if (state is AdminMerchantsLoaded) return state.page;
    if (state is AdminMerchantsLoading) return state.previousPage;
    if (state is AdminMerchantsFailure) return state.previousPage;
    return null;
  }
}

class _MerchantsContent extends StatelessWidget {
  const _MerchantsContent({
    required this.page,
    required this.loading,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPageChanged,
  });

  final AdminMerchantPage page;
  final bool loading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged;

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
              hintText: 'ابحث باسم المتجر أو الوصف',
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
          child: _StatusDropdown(onChanged: onStatusChanged),
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: page.isEmpty
              ? const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'لا يوجد تجار',
                  subtitle: 'جرّب تغيير البحث أو الفلاتر.',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  itemCount: page.merchants.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final merchant = page.merchants[index];
                    return _MerchantCard(
                      merchant: merchant,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AdminMerchantDetailsScreen(
                            merchantId: merchant.id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (page.pagination.lastPage > 1)
          _Pagination(
            pagination: page.pagination,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.onChanged});

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'حالة المتجر'),
      hint: Text('الكل', style: GoogleFonts.ibmPlexSans(fontSize: 13.sp)),
      items: const [
        DropdownMenuItem<String>(value: '', child: Text('الكل')),
        DropdownMenuItem<String>(value: 'active', child: Text('نشط')),
        DropdownMenuItem<String>(value: 'inactive', child: Text('غير نشط')),
        DropdownMenuItem<String>(value: 'suspended', child: Text('موقوف')),
      ],
      onChanged: (selected) => onChanged(
        selected == null || selected.isEmpty ? null : selected,
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant, required this.onTap});

  final AdminMerchant merchant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primarySoft,
              backgroundImage:
                  merchant.logo == null ? null : NetworkImage(merchant.logo!),
              child: merchant.logo == null
                  ? const Icon(Icons.storefront_outlined,
                      color: AppColors.primary)
                  : null,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textDark,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    merchant.owner?.displayName ?? merchant.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textGray,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${merchant.productsCount} منتجات • ${merchant.ordersCount} طلبات',
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.textLight,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            _Badge(
              label: _statusLabel(merchant.status),
              color: _statusColor(merchant.status),
            ),
            SizedBox(width: 4.w),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.pagination, required this.onPageChanged});

  final AdminMerchantPagination pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
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
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
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

class AdminMerchantDetailsScreen extends StatefulWidget {
  const AdminMerchantDetailsScreen({super.key, required this.merchantId});

  final String merchantId;

  @override
  State<AdminMerchantDetailsScreen> createState() =>
      _AdminMerchantDetailsScreenState();
}

class _AdminMerchantDetailsScreenState
    extends State<AdminMerchantDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminMerchantsBloc>().add(
          AdminMerchantDetailsRequested(widget.merchantId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(title: const Text('تفاصيل التاجر')),
        body: BlocConsumer<AdminMerchantsBloc, AdminMerchantsState>(
          listener: (context, state) {
            if (state is AdminMerchantsFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final merchant = _selectedMerchant(state);
            if (merchant == null) {
              if (state is AdminMerchantsFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminMerchantsBloc>()
                      .add(AdminMerchantDetailsRequested(widget.merchantId)),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _DetailsContent(
              merchant: merchant,
              loading: state is AdminMerchantsLoading,
              onStatus: () => _chooseStatus(context, merchant),
            );
          },
        ),
      ),
    );
  }

  AdminMerchant? _selectedMerchant(AdminMerchantsState state) {
    if (state is AdminMerchantsLoaded) return state.selectedMerchant;
    if (state is AdminMerchantsLoading) return state.selectedMerchant;
    if (state is AdminMerchantsFailure) return state.selectedMerchant;
    return null;
  }

  Future<void> _chooseStatus(
    BuildContext context,
    AdminMerchant merchant,
  ) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('تغيير حالة المتجر'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'active'),
            child: const Text('نشط'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'inactive'),
            child: const Text('غير نشط'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'suspended'),
            child: const Text('موقوف'),
          ),
        ],
      ),
    );
    if (status != null && status != merchant.status && context.mounted) {
      context.read<AdminMerchantsBloc>().add(
            AdminMerchantStatusUpdateRequested(
              merchantId: merchant.id,
              status: status,
            ),
          );
    }
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.merchant,
    required this.loading,
    required this.onStatus,
  });

  final AdminMerchant merchant;
  final bool loading;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Center(
          child: CircleAvatar(
            radius: 42.r,
            backgroundColor: AppColors.primarySoft,
            backgroundImage:
                merchant.logo == null ? null : NetworkImage(merchant.logo!),
            child: merchant.logo == null
                ? const Icon(Icons.storefront_outlined,
                    size: 36, color: AppColors.primary)
                : null,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          merchant.displayName,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSans(
            color: AppColors.textDark,
            fontSize: 21.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          merchant.description.isEmpty
              ? 'لا يوجد وصف للمتجر.'
              : merchant.description,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSans(
            color: AppColors.textGray,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Badge(
              label: _statusLabel(merchant.status),
              color: _statusColor(merchant.status),
            ),
            SizedBox(width: 8.w),
            OutlinedButton.icon(
              onPressed: loading ? null : onStatus,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('تغيير الحالة'),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _SectionCard(
          title: 'بيانات التاجر',
          child: merchant.owner == null
              ? const Text('لا تتوفر بيانات مالك المتجر.')
              : Column(
                  children: [
                    _InfoRow(
                        label: 'الاسم', value: merchant.owner!.displayName),
                    _InfoRow(label: 'البريد', value: merchant.owner!.email),
                    _InfoRow(label: 'الهاتف', value: merchant.owner!.phone),
                    _InfoRow(
                      label: 'حالة الحساب',
                      value: _statusLabel(merchant.owner!.status),
                    ),
                  ],
                ),
        ),
        SizedBox(height: 12.h),
        _SectionCard(
          title: 'إحصائيات المتجر',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'المنتجات', value: '${merchant.productsCount}'),
              _Stat(label: 'الطلبات', value: '${merchant.ordersCount}'),
            ],
          ),
        ),
        if (merchant.owner != null) ...[
          SizedBox(height: 12.h),
          _SubscriptionCard(owner: merchant.owner!),
        ],
        if (merchant.products.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _SectionCard(
            title: 'منتجات المتجر',
            child: Column(
              children: merchant.products
                  .map(
                    (product) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.price.toStringAsFixed(2)} • ${_statusLabel(product.status)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.owner});

  final AdminMerchantOwner owner;

  @override
  Widget build(BuildContext context) {
    final current = owner.currentSubscription;
    return _SectionCard(
      title: 'الاشتراك الحالي والسجل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current == null)
            const Text('لا يوجد اشتراك حالي أو تجربة مجانية.')
          else ...[
            _InfoRow(label: 'الخطة', value: current.planName),
            _InfoRow(
              label: 'النوع',
              value: current.isTrial ? 'تجربة مجانية' : current.type,
            ),
            _InfoRow(label: 'الحالة', value: _statusLabel(current.status)),
            _InfoRow(
              label: 'الاستحقاق',
              value: current.isEntitled ? 'مستحق' : 'منتهي',
            ),
            if (current.endsAt != null)
              _InfoRow(
                label: 'ينتهي في',
                value: _formatDate(current.endsAt!),
              ),
          ],
          if (owner.subscriptionHistory.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'سجل الاشتراكات',
              style: GoogleFonts.ibmPlexSans(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...owner.subscriptionHistory.map(
              (subscription) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(subscription.planName),
                subtitle: Text(
                  '${subscription.isTrial ? 'تجربة' : subscription.type} • '
                  '${_statusLabel(subscription.status)}',
                ),
                trailing: subscription.endsAt == null
                    ? null
                    : Text(_formatDate(subscription.endsAt!)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              color: AppColors.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 82.w,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(color: AppColors.textGray),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.ibmPlexSans(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexSans(
            color: AppColors.primary,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: GoogleFonts.ibmPlexSans(color: AppColors.textGray)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'active':
      return 'نشط';
    case 'suspended':
      return 'موقوف';
    case 'inactive':
      return 'غير نشط';
    case 'banned':
      return 'محظور';
    default:
      return status.isEmpty ? 'غير معروف' : status;
  }
}

String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/'
    '${date.day.toString().padLeft(2, '0')}';

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.green;
    case 'suspended':
    case 'banned':
      return AppColors.red;
    case 'inactive':
      return AppColors.orange;
    default:
      return AppColors.textGray;
  }
}
