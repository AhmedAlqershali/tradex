import 'dart:async';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/onboarding_screen.dart';
import 'package:ai_saas/shared/navigation/nav_shell.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          progress += 0.05;
        });
      }

      if (progress >= 1) {
        timer.cancel();
        _checkSessionAndNavigate();
      }
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;

    // Check for a saved user session.
    final savedUser = await UserController.instance.loadSession();

    if (!mounted) return;

    if (savedUser != null) {
      // Session exists — restore the correct home screen.
      final type = savedUser.role == AppType.merchant
          ? AppType.merchant
          : AppType.client;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BnScreen(type: type)),
      );
    } else {
      // No session — start from onboarding.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingAIPage()),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FD),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            children: [
              const Spacer(flex: 3),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tradex',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 50.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff4D41DF),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _buildLogoIcon(),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Text(
                      'سوقك الذكي مدعوماً بالذكاء الاصطناعي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1A1A1A),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'التجارة الإلكترونية المعززة بالذكاء الاصطناعي في متناول يدك',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        color: const Color(0xff707070),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 4),

              _buildProgressBar(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Transform.rotate(
      angle: 0.12,
      child: Container(
        height: 55.h,
        width: 55.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: const Color(0xff4D41DF),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff4D41DF).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.flash_on,
          size: 30.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: SizedBox(
            height: 5.h,
            width: 200.w,
            child: LinearProgressIndicator(
              value: progress,
              color: const Color(0xff4D41DF),
              backgroundColor: const Color(0xff4D41DF).withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}
