import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── NetworkError ─────────────────────────────────────────────────────────────
//
// Specialised no-connection error state. Used when the device is offline or
// the server is unreachable (catches [NetworkException] and [TimeoutException]).
//
// Usage:
//   NetworkError(onRetry: () => controller.reload())
//
// For generic server errors (5xx, unexpected) use [ErrorState] instead.
// ─────────────────────────────────────────────────────────────────────────────

class NetworkError extends StatelessWidget {
  const NetworkError({
    super.key,
    this.title = 'لا يوجد اتصال بالإنترنت',
    this.subtitle = 'تحقق من اتصالك بالشبكة وأعد المحاولة.',
    this.retryLabel = 'إعادة المحاولة',
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback? onRetry;

  static const Color _orange     = Color(0xffF59E0B);
  static const Color _orangeSoft = Color(0xffFEF3C7);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);
  static const Color _primary    = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: const BoxDecoration(
              color: _orangeSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 48.sp,
              color: _orange,
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
