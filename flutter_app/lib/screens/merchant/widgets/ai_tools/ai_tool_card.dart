import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/screens/merchant/widgets/ai_tools/ai_tool_sheet.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiToolCard ───────────────────────────────────────────────────────────────
//
// Feature card for one AI tool (description / instagram / hashtags / reply).
// ─────────────────────────────────────────────────────────────────────────────

class AiToolCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color buttonColor;
  final AiToolType tool;
  final String? tag;

  const AiToolCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonColor,
    required this.tool,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 22.sp),
                ),
                if (tag != null) ...[
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => AiToolSheet.show(context, tool),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: buttonColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
