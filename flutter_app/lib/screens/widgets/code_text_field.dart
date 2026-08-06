import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── CodeTextField ─────────────────────────────────────────────────────────
//
// Single-digit OTP input cell used in CodeRegister screen.
//
// Fixes:
//   - Focus border now uses brand primary (was Colors.blue)
//   - Font changed to IBM Plex Sans (was GoogleFonts.nunito — inconsistent)
// ─────────────────────────────────────────────────────────────────────────────

class CodeTextField extends StatelessWidget {
  const CodeTextField({
    super.key,
    required this.editingController,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController editingController;
  final FocusNode focusNode;
  final void Function(String value) onChanged;

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 56.h,
        child: TextField(
          controller: editingController,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1A1A1A),
          ),
          maxLength: 1,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '·',
            hintStyle: GoogleFonts.ibmPlexSans(
              fontSize: 24.sp,
              color: const Color(0xffCCCCCC),
            ),
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: const Color(0xffF8F9FD),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xffEFEFEF), width: 1.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _primary, width: 2),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}
