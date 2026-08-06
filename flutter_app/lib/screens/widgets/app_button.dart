import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── AppButton ────────────────────────────────────────────────────────────────
//
// The canonical Tradex button. Replaces raw ElevatedButton usage across the app.
//
// Variants:
//   AppButton(...)         → filled primary (default)
//   AppButton.secondary    → light-tinted secondary
//   AppButton.outlined     → outlined with primary border
//
// All variants support:
//   isLoading  → shows a centered CircularProgressIndicator
//   isDisabled → greys out and disables tap
// ─────────────────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? width;
  final IconData? icon;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.width,
    this.icon,
    this.borderRadius,
  });

  /// Light-tinted secondary variant
  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.height,
    this.width,
    this.icon,
    this.borderRadius,
  })  : backgroundColor = AppColors.primarySoft,
        foregroundColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final bool active = !isLoading && !isDisabled && onPressed != null;

    final Color bg = isDisabled
        ? const Color(0xffE0E0E0)
        : (backgroundColor ?? AppColors.primary);
    final Color fg = isDisabled
        ? const Color(0xff9E9E9E)
        : (foregroundColor ?? Colors.white);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54.h,
      child: ElevatedButton(
        onPressed: active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: const Color(0xffE0E0E0),
          disabledForegroundColor: const Color(0xff9E9E9E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(14.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18.sp, color: fg),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
