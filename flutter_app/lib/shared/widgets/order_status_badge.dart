import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── OrderStatusBadge ─────────────────────────────────────────────────────────
//
// Colored pill badge showing the current order status.
// Used in both MerchantOrderDetailsScreen and ClientOrderDetailsScreen.
// ─────────────────────────────────────────────────────────────────────────────

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12.sp, color: status.color),
          SizedBox(width: 4.w),
          Text(
            status.label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
