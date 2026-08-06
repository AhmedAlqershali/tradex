import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/shared/ai/ai_controller.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiRecentOperations ───────────────────────────────────────────────────────
//
// Section listing the last 5 generated results from AiController.historyNotifier.
// ─────────────────────────────────────────────────────────────────────────────

class AiRecentOperations extends StatelessWidget {
  const AiRecentOperations({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر العمليات',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'عرض السجل',
                    style: TextStyle(color: AppColors.purple, fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ValueListenableBuilder<List<AiResult>>(
              valueListenable: AiController.instance.historyNotifier,
              builder: (context, history, _) {
                if (history.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      'لا توجد عمليات بعد. استخدم إحدى أدوات الذكاء الاصطناعي لبدء التوليد.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGray,
                      ),
                    ),
                  );
                }
                return Column(
                  children: history.take(5).map((result) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _OperationRow(
                        icon: _iconForTool(result.tool),
                        iconColor: _colorForTool(result.tool),
                        title: '${result.tool.label}: ${result.prompt.split(' | ').first}',
                        time: _formatTime(result.generatedAt),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForTool(AiToolType tool) {
    switch (tool) {
      case AiToolType.productDescription: return Icons.description_outlined;
      case AiToolType.instagramPost:      return Icons.camera_alt_outlined;
      case AiToolType.hashtags:           return Icons.tag;
      case AiToolType.customerReply:      return Icons.chat_bubble_outline;
    }
  }

  static Color _colorForTool(AiToolType tool) {
    switch (tool) {
      case AiToolType.productDescription: return AppColors.purple;
      case AiToolType.instagramPost:      return AppColors.orange;
      case AiToolType.hashtags:           return AppColors.teal;
      case AiToolType.customerReply:      return AppColors.pink;
    }
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24)   return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }
}

// ─── _OperationRow ────────────────────────────────────────────────────────────

class _OperationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const _OperationRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(
                  time,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
