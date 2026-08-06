import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── EmptyState ───────────────────────────────────────────────────────────────
//
// Generic empty-list / zero-data state used across cart, orders, products etc.
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBgColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBgColor,
  });

  static const Color _primary = Color(0xff4D41DF);

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
              color: iconBgColor ?? const Color(0xffEDE9FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48.sp,
              color: iconColor ?? _primary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.sp,
                color: const Color(0xff888888),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 28.h),
            SizedBox(
              width: 160.w,
              height: 46.h,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  actionLabel!,
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
