import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:ai_saas/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── OrderCustomerInfoCard ────────────────────────────────────────────────────
//
// Customer contact details card used in both merchant and client order screens.
// ─────────────────────────────────────────────────────────────────────────────

class OrderCustomerInfoCard extends StatelessWidget {
  final AppOrder order;

  const OrderCustomerInfoCard({super.key, required this.order});

  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardTitle(
              text: 'بيانات العميل',
              icon: Icons.person_outline_rounded),
          SizedBox(height: 12.h),
          _row(Icons.person_outline_rounded, 'الاسم', order.customerName),
          SizedBox(height: 8.h),
          _row(Icons.phone_outlined, 'الجوال', order.customerPhone),
          SizedBox(height: 8.h),
          _row(Icons.location_city_outlined, 'المدينة', order.customerCity),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Divider(height: 1.h, color: const Color(0xffF0F0F0)),
            SizedBox(height: 10.h),
            const AppCardTitle(
                text: 'ملاحظات',
                icon: Icons.sticky_note_2_outlined),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xffF8F9FD),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                order.notes!,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp, color: _textDark, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: _textGray),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: _textGray),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
        ),
      ],
    );
  }
}
