import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── AppTextField ─────────────────────────────────────────────────────────────
//
// Standardized text field for Add/Edit Product screens.
//
// Fixes over the original:
//   - Class renamed to AppTextField (PascalCase)
//   - Border radius corrected to 12.r (was 24.r — too pill-shaped for a form field)
//   - Focus border now uses the brand primary color directly
//   - Added keyboardType and maxLines parameters
//   - Added textDirection parameter (defaults to RTL for Arabic input)
// ─────────────────────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String name;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int maxLines;
  final TextDirection textDirection;

  const AppTextField({
    required this.name,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.textDirection = TextDirection.rtl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textDirection: textDirection,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 14.sp,
        color: const Color(0xff1A1A1A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffF2F3F6),
        hintText: name,
        hintStyle: GoogleFonts.ibmPlexSans(
          fontSize: 13.sp,
          color: const Color(0xffBBBBBB),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffEFEFEF)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xff4D41DF), width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffEFEFEF)),
        ),
      ),
    );
  }
}

// Backward-compatible alias so existing files keep compiling unchanged.
// ignore: camel_case_types
typedef add_product_textfield = AppTextField;

// ─── AddProductTextField ──────────────────────────────────────────────────────
//
// Labelled text field with a leading icon, used in the Add/Edit Product screen.
// ─────────────────────────────────────────────────────────────────────────────

class AddProductTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const AddProductTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    super.key,
  });

  static const Color _primary    = Color(0xff4D41DF);
  static const Color _fieldFill  = Color(0xffF2F3F6);
  static const Color _border     = Color(0xffEFEFEF);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textHint   = Color(0xff666666);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xff555555),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.ibmPlexSans(fontSize: 14.sp, color: _textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldFill,
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              color: _textHint,
            ),
            prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xff9E9E9E)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: _border),
            ),
          ),
        ),
      ],
    );
  }
}
