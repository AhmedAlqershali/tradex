import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiTopBar ─────────────────────────────────────────────────────────────────
//
// Top bar for the AI Marketing Tools screen.
// ─────────────────────────────────────────────────────────────────────────────

class AiTopBar extends StatelessWidget {
  const AiTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38.w,
            height: 38.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.person, color: AppColors.purple, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            'Tradex AI',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              Icon(Icons.notifications_none, size: 26.sp, color: AppColors.textDark),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          Icon(Icons.menu, size: 26.sp, color: AppColors.textDark),
        ],
      ),
    );
  }
}
