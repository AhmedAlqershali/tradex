import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/client/client_orders_screen.dart';
import 'package:ai_saas/shared/navigation/nav_shell.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final List<AppOrder> orders;
  const OrderConfirmationScreen({super.key, required this.orders});

  static const Color _primary    = Color(0xff4D41DF);
  static const Color _scaffoldBg = Color(0xffF8F9FD);
  static const Color _textDark   = Color(0xff1A1A1A);
  static const Color _textGray   = Color(0xff888888);
  static const Color _green      = Color(0xff00C896);

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Text(
            AppLocalizations.of(context).orderSubmitted,
            style: GoogleFonts.ibmPlexSans(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Success icon ─────────────────────────────────────────
                Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 58.sp,
                    color: _green,
                  ),
                ),
                SizedBox(height: 24.h),

                // ── Heading ──────────────────────────────────────────────
                Text(
                  AppLocalizations.of(context).orderSubmittedMessage,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Business message ─────────────────────────────────────
                Text(
                  AppLocalizations.of(context).orderApprovedMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp,
                    color: _textGray,
                    height: 1.7,
                  ),
                ),
                SizedBox(height: 24.h),

                // ── Order reference ──────────────────────────────────────
                ...orders.map(_buildOrderReference),
                SizedBox(height: 48.h),

                // ── Back to home ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BnScreen(type: AppType.client),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).backToHome,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // ── View orders ──────────────────────────────────────────
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientOrdersScreen(),
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context).viewMyOrders,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14.sp,
                      color: _primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderReference(AppOrder order) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        AppLocalizations.of(context).orderReference.replaceFirst('{ref}', order.ref),
        style: GoogleFonts.ibmPlexSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: _primary,
        ),
      ),
    );
  }
}
