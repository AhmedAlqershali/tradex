import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/recently_arrived_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── HomeHeroBanner ───────────────────────────────────────────────────────────
//
// Gradient promotional banner on the shopper home page.
// ─────────────────────────────────────────────────────────────────────────────

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primary, const Color(0xff6A5AE0)]),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).discoverLocalStores,
            style: GoogleFonts.ibmPlexSans(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            AppLocalizations.of(context).bestLocalDeals,
            style: GoogleFonts.ibmPlexSans(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RecentlyArrivedScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
            ),
            child: Text(AppLocalizations.of(context).discoverNow,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
