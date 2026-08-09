import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantSubscriptionScreen extends StatefulWidget {
  const MerchantSubscriptionScreen({super.key});

  @override
  State<MerchantSubscriptionScreen> createState() =>
      _MerchantSubscriptionScreenState();
}

class _MerchantSubscriptionScreenState
    extends State<MerchantSubscriptionScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);

  @override
  void initState() {
    super.initState();
    context
        .read<MerchantSubscriptionBloc>()
        .add(const MerchantSubscriptionLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xff1A1A1A)),
          title: Text(
            'حالة الاشتراك',
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<MerchantSubscriptionBloc, MerchantSubscriptionState>(
          builder: (context, state) {
            if (state is MerchantSubscriptionLoading ||
                state is MerchantSubscriptionInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MerchantSubscriptionFailure) {
              return _Message(
                message: state.message,
                onRetry: () => context
                    .read<MerchantSubscriptionBloc>()
                    .add(const MerchantSubscriptionLoadRequested()),
              );
            }
            if (state is MerchantSubscriptionLoaded) {
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<MerchantSubscriptionBloc>()
                    .add(const MerchantSubscriptionLoadRequested()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  children: [
                    _buildStatusCard(state.subscription),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(AdminSubscription? subscription) {
    if (subscription == null) {
      return _Message(
        message: 'لا يوجد اشتراك أو فترة تجريبية حالية.',
        icon: Icons.card_membership_outlined,
      );
    }

    final entitled = subscription.isEntitled;
    final isTrial = subscription.isTrial;
    final endsAt = subscription.endsAt;
    final daysRemaining =
        endsAt?.difference(DateTime.now()).inDays.clamp(0, 9999);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isTrial ? Icons.timelapse_rounded : Icons.verified_outlined,
                  color: _primary,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  subscription.planName,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1A1A1A),
                  ),
                ),
              ),
              _statusPill(
                entitled ? 'نشط' : 'منتهي',
                entitled ? const Color(0xff00A878) : const Color(0xffE53E3E),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          _detailRow('النوع', isTrial ? 'فترة تجريبية' : 'اشتراك مدفوع'),
          _detailRow('الحالة', _statusLabel(subscription.status)),
          if (subscription.billingCycle.isNotEmpty)
            _detailRow(
                'دورة الفوترة', _billingLabel(subscription.billingCycle)),
          if (endsAt != null)
            _detailRow(
              'ينتهي في',
              '${endsAt.day}/${endsAt.month}/${endsAt.year}'
                  '${daysRemaining != null ? ' ($daysRemaining يوم متبقٍ)' : ''}',
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp, color: const Color(0xff888888))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1A1A1A))),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: GoogleFonts.ibmPlexSans(
              color: color, fontSize: 12.sp, fontWeight: FontWeight.bold)),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'expired':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return status.isEmpty ? 'غير معروف' : status;
    }
  }

  String _billingLabel(String cycle) {
    switch (cycle) {
      case 'monthly':
        return 'شهري';
      case 'yearly':
        return 'سنوي';
      default:
        return cycle;
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry, this.icon});

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.error_outline,
                size: 42.sp, color: const Color(0xff888888)),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp, color: const Color(0xff707070))),
            if (onRetry != null) ...[
              SizedBox(height: 8.h),
              TextButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ],
        ),
      ),
    );
  }
}
