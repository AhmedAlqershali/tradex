import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── HomeCategoriesRow ────────────────────────────────────────────────────────
//
// Horizontal row of category icon buttons on the shopper home page.
// ─────────────────────────────────────────────────────────────────────────────

class HomeCategoriesRow extends StatelessWidget {
  const HomeCategoriesRow({super.key});

  static const _categories = [
    (Icons.checkroom_rounded, 'ملابس'),
    (Icons.ice_skating_rounded, 'أحذية'),
    (Icons.face_retouching_natural_rounded, 'كوزمتكس'),
    (Icons.restaurant_rounded, 'طعام'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _categories.map((cat) {
          return _CategoryItem(icon: cat.$1, label: cat.$2);
        }).toList(),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryItem({required this.icon, required this.label});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 65.w,
          height: 65.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
            ],
          ),
          child: Icon(icon, color: _primary, size: 26.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
              fontSize: 12.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
