import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/admin_subscription_requests/admin_subscription_requests_bloc.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';
import 'package:ai_saas/shared/widgets/empty_state.dart';
import 'package:ai_saas/shared/widgets/error_state.dart';

class AdminSubscriptionRequestsScreen extends StatefulWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  @override
  State<AdminSubscriptionRequestsScreen> createState() =>
      _AdminSubscriptionRequestsScreenState();
}

class _AdminSubscriptionRequestsScreenState
    extends State<AdminSubscriptionRequestsScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    context
        .read<AdminSubscriptionRequestsBloc>()
        .add(const AdminSubscriptionRequestsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'طلبات الاشتراك',
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
                  .read<AdminSubscriptionRequestsBloc>()
                  .add(const AdminSubscriptionRequestsLoadRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<AdminSubscriptionRequestsBloc,
            AdminSubscriptionRequestsState>(
          listener: (context, state) {
            if (state is AdminSubscriptionRequestsFailure &&
                state.previousPage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final page = _pageFrom(state);
            if (page == null) {
              if (state is AdminSubscriptionRequestsFailure) {
                return ErrorState(
                  subtitle: state.message,
                  onRetry: () => context
                      .read<AdminSubscriptionRequestsBloc>()
                      .add(const AdminSubscriptionRequestsLoadRequested()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }

            return _RequestsBody(
              page: page,
              loading: state is AdminSubscriptionRequestsLoading,
              status: _status,
              onStatusChanged: (status) {
                setState(() => _status = status);
                context.read<AdminSubscriptionRequestsBloc>().add(
                      AdminSubscriptionRequestsStatusChanged(status),
                    );
              },
              onPageChanged: (pageNumber) => context
                  .read<AdminSubscriptionRequestsBloc>()
                  .add(AdminSubscriptionRequestsPageRequested(pageNumber)),
              onRequestTap: _showDetails,
            );
          },
        ),
      ),
    );
  }

  AdminSubscriptionRequestPage? _pageFrom(
    AdminSubscriptionRequestsState state,
  ) {
    if (state is AdminSubscriptionRequestsLoaded) return state.page;
    if (state is AdminSubscriptionRequestsLoading) return state.previousPage;
    if (state is AdminSubscriptionRequestsFailure) return state.previousPage;
    return null;
  }

  void _showDetails(AdminSubscriptionRequest request) {
    final bloc = context.read<AdminSubscriptionRequestsBloc>();
    bloc.add(AdminSubscriptionRequestDetailsRequested(request.id));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _RequestDetailsSheet(requestId: request.id),
      ),
    );
  }
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody({
    required this.page,
    required this.loading,
    required this.status,
    required this.onStatusChanged,
    required this.onPageChanged,
    required this.onRequestTap,
  });

  final AdminSubscriptionRequestPage page;
  final bool loading;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminSubscriptionRequest> onRequestTap;

  @override
  Widget build(BuildContext context) {
    if (page.isEmpty && !loading) {
      return Column(
        children: [
          _StatusFilter(value: status, onChanged: onStatusChanged),
          const Expanded(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد طلبات اشتراك',
              subtitle: 'لم يتم العثور على طلبات بالحالة المحددة.',
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: [
            _StatusFilter(value: status, onChanged: onStatusChanged),
            SizedBox(height: 10.h),
            Text(
              '${page.pagination.total} طلب',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            ...page.requests.map(
              (request) => _RequestCard(
                request: request,
                onTap: () => onRequestTap(request),
              ),
            ),
            _Pagination(
              pagination: page.pagination,
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

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'تصفية حسب الحالة',
        prefixIcon: Icon(Icons.filter_list_rounded),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('كل الطلبات')),
        DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
        DropdownMenuItem(value: 'approved', child: Text('مقبولة')),
        DropdownMenuItem(value: 'rejected', child: Text('مرفوضة')),
      ],
      onChanged: onChanged,
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final AdminSubscriptionRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.fullName.isEmpty
                          ? request.merchant?.name ?? 'طلب اشتراك'
                          : request.fullName,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _StatusChip(status: request.status),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                request.plan?.displayName.isNotEmpty == true
                    ? request.plan!.displayName
                    : 'خطة غير محددة',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                '${request.billingCycle} • ${request.paymentMethod}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              if (request.createdAt != null)
                Padding(
                  padding: EdgeInsets.only(top: 5.h),
                  child: Text(
                    _formatDate(request.createdAt!),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  const _RequestDetailsSheet({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .95,
        builder: (context, controller) {
          return Material(
            color: AppColors.scaffold,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BlocBuilder<AdminSubscriptionRequestsBloc,
                AdminSubscriptionRequestsState>(
              builder: (context, state) {
                final request = _selectedRequest(state);
                if (request == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final loading = state is AdminSubscriptionRequestsLoading;
                return ListView(
                  controller: controller,
                  padding: EdgeInsets.all(20.w),
                  children: [
                    Center(
                      child: Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تفاصيل طلب الاشتراك',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        _StatusChip(status: request.status),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    _DetailLine('التاجر', request.merchant?.name ?? request.fullName),
                    _DetailLine('البريد الإلكتروني', request.merchant?.email ?? '—'),
                    _DetailLine('الهاتف', request.phone),
                    _DetailLine(
                      'الخطة',
                      request.plan?.displayName.isNotEmpty == true
                          ? request.plan!.displayName
                          : '—',
                    ),
                    _DetailLine('دورة الفوترة', request.billingCycle),
                    _DetailLine('طريقة الدفع', request.paymentMethod),
                    if (request.notes?.isNotEmpty == true)
                      _DetailLine('ملاحظات', request.notes!),
                    if (request.rejectionReason?.isNotEmpty == true)
                      _DetailLine('سبب الرفض', request.rejectionReason!),
                    SizedBox(height: 12.h),
                    if (request.paymentProofUrl != null)
                      _ProofSection(
                        requestId: requestId,
                        proofBytes: state is AdminSubscriptionRequestsLoaded
                            ? state.proofBytes
                            : null,
                        loading: loading,
                      ),
                    if (request.isPending) ...[
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: loading
                                  ? null
                                  : () => _reject(context, request),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('رفض الطلب'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: loading
                                  ? null
                                  : () => _approve(context, request),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('قبول الطلب'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  AdminSubscriptionRequest? _selectedRequest(
    AdminSubscriptionRequestsState state,
  ) {
    if (state is AdminSubscriptionRequestsLoaded) return state.selectedRequest;
    if (state is AdminSubscriptionRequestsLoading) return state.selectedRequest;
    if (state is AdminSubscriptionRequestsFailure) return state.selectedRequest;
    return null;
  }

  Future<void> _approve(
    BuildContext context,
    AdminSubscriptionRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('قبول طلب الاشتراك؟'),
        content: const Text('سيتم تفعيل اشتراك التاجر بعد قبول الطلب.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminSubscriptionRequestsBloc>().add(
            AdminSubscriptionRequestApproveRequested(request.id),
          );
    }
  }

  Future<void> _reject(
    BuildContext context,
    AdminSubscriptionRequest request,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض طلب الاشتراك'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض',
            hintText: 'اكتب سبباً واضحاً للتاجر',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && context.mounted) {
      context.read<AdminSubscriptionRequestsBloc>().add(
            AdminSubscriptionRequestRejectRequested(request.id, reason),
          );
    }
  }
}

class _ProofSection extends StatelessWidget {
  const _ProofSection({
    required this.requestId,
    required this.proofBytes,
    required this.loading,
  });

  final String requestId;
  final Uint8List? proofBytes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إثبات الدفع',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        if (proofBytes != null && proofBytes!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              proofBytes!,
              fit: BoxFit.contain,
              height: 220.h,
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () => context.read<AdminSubscriptionRequestsBloc>().add(
                      AdminSubscriptionRequestProofRequested(requestId),
                    ),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(loading ? 'جارِ التحميل...' : 'عرض إثبات الدفع'),
          ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105.w,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.sp,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('مقبول', Colors.green),
      'rejected' => ('مرفوض', Colors.red),
      _ => ('قيد المراجعة', Colors.orange),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color.shade800, fontSize: 11)),
      backgroundColor: color.shade50,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pagination,
    required this.onPageChanged,
  });

  final AdminSubscriptionRequestPagination pagination;
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

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}