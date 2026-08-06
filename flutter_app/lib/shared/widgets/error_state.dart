import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── ErrorState ───────────────────────────────────────────────────────────────
//
// Generic error / failure state. Mirrors the structure and design language of
// [EmptyState] — same circular icon container, same typography, same button.
//
// Usage:
//   ErrorState(
//     onRetry: () => controller.reload(),
//   )
//
// Show when a network or server error prevents data from loading.
// For connectivity-specific errors prefer [NetworkError].
// ─────────────────────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'حدث خطأ ما',
    this.subtitle = 'تعذّر تحميل البيانات. حاول مجدداً.',
    this.retryLabel = 'إعادة المحاولة',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
    this.iconBgColor,
  });

  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;

  static const Color _red      = Color(0xffEF4444);
  static const Color _redSoft  = Color(0xffFEE2E2);
  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);
  static const Color _primary  = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: iconBgColor ?? _redSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48.sp,
              color: iconColor ?? _red,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.sp,
                color: _textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: 28.h),
            SizedBox(
              width: 160.w,
              height: 46.h,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  retryLabel,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
