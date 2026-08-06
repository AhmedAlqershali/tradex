import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── InfoRow ──────────────────────────────────────────────────────────────────
//
// A single labeled data row: icon · "Label:" · value
// Used inside order header cards, profile sections, etc.
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff888888);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: _textGray),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: _textGray),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
