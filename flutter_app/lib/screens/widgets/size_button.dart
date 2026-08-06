import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SizeButton ───────────────────────────────────────────────────────────────
//
// Full-width primary action button used across auth and product screens.
// ─────────────────────────────────────────────────────────────────────────────

class SizeButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SizeButton({
    required this.title,
    required this.onTap,
    super.key,
  });

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    final bool active = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: active ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? _primary : const Color(0xffE0E0E0),
          foregroundColor: active ? Colors.white : const Color(0xff9E9E9E),
          disabledBackgroundColor: const Color(0xffE0E0E0),
          disabledForegroundColor: const Color(0xff9E9E9E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── PrimaryButton ────────────────────────────────────────────────────────────
//
// Legacy button kept for backward compatibility.
// New screens should use AppButton from app_button.dart instead.
//
// Improvements over the original:
//   - fontSize corrected to 16.sp (was 18.sp — too large)
//   - Added isLoading parameter for async actions
//   - Added isDisabled parameter
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String name;
  final VoidCallback? onPressed;
  final Color color;
  final Color colorname;
  final Size size;
  final bool isLoading;
  final bool isDisabled;

  const PrimaryButton({
    required this.name,
    required this.onPressed,
    required this.color,
    required this.colorname,
    required this.size,
    this.isLoading = false,
    this.isDisabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = !isLoading && !isDisabled && onPressed != null;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? const Color(0xffE0E0E0) : color,
        foregroundColor: isDisabled ? const Color(0xff9E9E9E) : colorname,
        disabledBackgroundColor: const Color(0xffE0E0E0),
        disabledForegroundColor: const Color(0xff9E9E9E),
        minimumSize: size,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
      onPressed: active ? onPressed : null,
      child: isLoading
          ? SizedBox(
              width: 22.w,
              height: 22.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorname,
              ),
            )
          : Text(
              name,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 16.sp,       // was 18.sp
                fontWeight: FontWeight.bold,
                color: isDisabled ? const Color(0xff9E9E9E) : colorname,
              ),
            ),
    );
  }
}
