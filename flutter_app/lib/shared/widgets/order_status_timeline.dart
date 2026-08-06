import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart' show AppOrder;
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── OrderStatusTimeline ──────────────────────────────────────────────────────
//
// Vertical step timeline showing order progress.
// Identical between MerchantOrderDetailsScreen and ClientOrderDetailsScreen —
// extracted here to eliminate the duplication (~90 lines × 2).
//
// Usage:
//   OrderStatusTimeline(order: order, title: 'مسار الطلب')
// ─────────────────────────────────────────────────────────────────────────────

class OrderStatusTimeline extends StatelessWidget {
  final AppOrder order;
  final String title;

  const OrderStatusTimeline({
    super.key,
    required this.order,
    this.title = 'مسار الطلب',
  });


  static const List<String> _labels = [
    'قيد المراجعة',
    'تم التواصل',
    'تم تأكيد الطلب',
    'جاري تجهيز الطلب',
    'مكتمل',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardTitle(text: title, icon: Icons.timeline_rounded),
          SizedBox(height: 20.h),
          if (order.status == OrderStatus.cancelled)
            const _CancelledTimeline(labels: _labels)
          else
            ..._labels.asMap().entries.map((e) {
              final active = order.status.timelineStep;
              return _TimelineStep(
                label: e.value,
                isDone: e.key < active,
                isCurrent: e.key == active,
                isLast: e.key == _labels.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

// ─── _TimelineStep ────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  static const Color _primary  = Color(0xff4D41DF);
  static const Color _green    = Color(0xff00C896);
  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);

  @override
  Widget build(BuildContext context) {
    final circleColor = isDone
        ? _green
        : isCurrent
            ? _primary
            : const Color(0xffE0E0E0);
    final lineColor  = isDone ? _green : const Color(0xffE0E0E0);
    final labelColor = isCurrent ? _primary : isDone ? _textDark : _textGray;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28.w,
          child: Column(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: _primary.withValues(alpha: 0.3), width: 3)
                      : null,
                ),
                child: Icon(
                  isDone
                      ? Icons.check_rounded
                      : isCurrent
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: isDone ? 15.sp : isCurrent ? 14.sp : 12.sp,
                ),
              ),
              if (!isLast)
                Container(width: 2.w, height: 32.h, color: lineColor),
            ],
          ),
        ),
        SizedBox(width: 14.w),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _CancelledTimeline ───────────────────────────────────────────────────────

class _CancelledTimeline extends StatelessWidget {
  final List<String> labels;

  const _CancelledTimeline({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...labels.asMap().entries.map((e) => _TimelineStep(
              label: e.value,
              isDone: false,
              isCurrent: false,
              isLast: e.key == labels.length - 1,
            )),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xffFEF2F2),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xffFECACA)),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined,
                  color: const Color(0xffE53E3E), size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'تم إلغاء هذا الطلب',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xffE53E3E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
