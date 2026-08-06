import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiAccuracyCard ───────────────────────────────────────────────────────────
//
// Dark card showing the AI generation accuracy metric.
// ─────────────────────────────────────────────────────────────────────────────

class AiAccuracyCard extends StatelessWidget {
  const AiAccuracyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Text(
            '98%',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 52.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'دقة المحتوى المولود بواسطة AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'بناءً على أكثر من 10,000 محتوى تم إنشاؤه',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.45),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
