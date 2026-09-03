import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessPasswordScreen extends StatelessWidget {
  final AppType type;
  const SuccessPasswordScreen({super.key, this.type = AppType.client});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD), // لون الخلفية الهادئ المائل للبياض في واجهاتك
        body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ليأخذ الكارت مساحة المحتوى فقط مثل الصورة
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 16.h),

                  // أيقونة النجاح الدائرية (علامة الصح المعتمدة في تصميمك)
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: const Color(0xff4D41DF).withValues(alpha: 0.1),
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundColor: const Color(0xff4D41DF),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // عنوان النجاح الرئيسي
                  Text(
                    AppLocalizations.of(context).passwordChanged,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1A1A1A),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // النص الفرعي التوضيحي
                  Text(
                    AppLocalizations.of(context).passwordSuccessDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14.sp,
                      color: const Color(0xff707070),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // زر تسجيل الدخول الرئيسي بنقفس لون ثيم Tradex الموحد
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(type: type),
                          ),
                              (route) => false,
                        );                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4D41DF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context).loginNow,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}