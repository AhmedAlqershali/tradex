import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/screens/merchant/widgets/ai_tools/ai_tool_sheet.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiHeroBanner ─────────────────────────────────────────────────────────────
//
// Gradient hero section at the top of the AI Marketing Tools screen.
// ─────────────────────────────────────────────────────────────────────────────

class AiHeroBanner extends StatelessWidget {
  const AiHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B6FFF), Color(0xFF5A4FDF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مساعدك الذكي\nلإدارة متجرك\nباحترافية',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'استخدم أدوات الذكاء الاصطناعي لتوفير وزيادة مبيعاتك بضغطة زر واحدة.',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                GestureDetector(
                  onTap: () => AiToolSheet.show(context, AiToolType.productDescription),
                  child: _HeroButton('ابدأ الآن', AppColors.white, AppColors.purple),
                ),
                SizedBox(width: 12.w),
                _HeroButton(
                  'شاهد الشرح',
                  Colors.transparent,
                  AppColors.white,
                  isOutlined: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  final bool isOutlined;

  const _HeroButton(this.text, this.bg, this.textColor,
      {this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: isOutlined
            ? Border.all(color: AppColors.white, width: 1.5.w)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
