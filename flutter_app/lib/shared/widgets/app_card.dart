import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── AppCard ──────────────────────────────────────────────────────────────────
//
// Standard white card container with soft shadow.
// Used in order screens, checkout, profile, etc.
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── AppCardTitle ─────────────────────────────────────────────────────────────
//
// Icon + label row used as a section heading inside AppCard.
// ─────────────────────────────────────────────────────────────────────────────

class AppCardTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const AppCardTitle({
    super.key,
    required this.text,
    required this.icon,
    this.color,
  });

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    final c = color ?? _primary;
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: c),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1A1A1A),
          ),
        ),
      ],
    );
  }
}
