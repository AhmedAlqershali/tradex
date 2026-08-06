import 'package:ai_saas/screens/recently_arrived_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── WeekendPromoBanner ───────────────────────────────────────────────────────
//
// Dark promotional banner at the bottom of the shopper home scroll.
// ─────────────────────────────────────────────────────────────────────────────

class WeekendPromoBanner extends StatelessWidget {
  const WeekendPromoBanner({super.key});

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'عروض نهاية الأسبوع 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  'خصومات تصل إلى 40%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                  ),
                ),

              ],
            ),
          ),

          SizedBox(width: 12.w),

          SizedBox(
            width: 95.w,
            height: 42.h,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecentlyArrivedScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'احصل عليه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}