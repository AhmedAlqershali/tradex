import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/services/password_reset_link_service.dart';
import 'package:ai_saas/core/services/firebase_email_verification_service.dart';
import 'package:ai_saas/core/services/auth_service.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/users/user_model.dart';

class EmailVerificationScreen extends StatefulWidget {
  /// The user that needs email verification
  final AppUser user;

  /// The role (client or merchant) — used to navigate to appropriate profile screen
  final AppType role;

  /// Callback when verification is successful
  /// Should navigate to the appropriate profile completion screen
  final void Function(AppUser)? onVerificationSuccess;

  const EmailVerificationScreen({
    super.key,
    required this.user,
    required this.role,
    this.onVerificationSuccess,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _isVerifying = false;
  bool _isResending = false;
  String? _verificationError;
  bool _verificationComplete = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _checkFirebaseVerification();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for deep link verification
    DeepLinkService.instance.onEmailVerificationLink = _handleVerificationLink;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up the callback
    if (DeepLinkService.instance.onEmailVerificationLink == _handleVerificationLink) {
      DeepLinkService.instance.onEmailVerificationLink = null;
    }
    super.dispose();
  }

  Future<void> _handleVerificationLink(
    String userId,
    String hash,
    String signature,
    String expires,
  ) async {
    if (!mounted) return;

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      // Call the verification endpoint with the parameters from the deep link
      // The backend validates the signed URL and updates email_verified_at
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/v1/auth/email/verify/$userId/$hash?signature=$signature&expires=$expires',
      );

      if (!mounted) return;

      // Check response
      final data = response.data;
      if (data == null || data['data'] == null) {
        throw ServerException(
          'Invalid response from verification endpoint',
          statusCode: 500,
        );
      }

      final verified = data['data']['email_verified'] == true;
      if (!verified) {
        throw ServerException(
          'Verification failed',
          statusCode: 422,
        );
      }

      // Verification successful
      setState(() {
        _isVerifying = false;
        _verificationComplete = true;
        _verificationError = null;
      });

      // Wait a moment for visual feedback, then proceed
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Backend has verified the email. Call success callback with current user.
      // The user can now proceed to profile completion and login.
      widget.onVerificationSuccess?.call(widget.user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationError = _getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationError = 'حدث خطأ. حاول مجدداً.';
      });
    }
  }

  Future<void> _handleResendClick() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _verificationError = null;
    });

    try {
      await FirebaseEmailVerificationService.instance.resend();

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال رابط التحقق. تحقق من بريدك الإلكتروني.',
              style: GoogleFonts.ibmPlexSans(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _verificationError = _getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _verificationError = 'فشل إعادة الإرسال. حاول مجدداً.';
      });
    }
  }

  Future<void> _checkFirebaseVerification() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      final idToken = await FirebaseEmailVerificationService.instance
          .refreshAndGetIdToken();
      if (idToken == null) {
        throw ServerException(
          'Email is not verified yet.',
          statusCode: 422,
        );
      }

      await AuthService.instance.syncFirebaseVerification(idToken);
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _verificationComplete = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) widget.onVerificationSuccess?.call(widget.user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationError = _getErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationError = 'لم يتم تأكيد البريد بعد. تحقق من الرسالة ثم حاول مجدداً.';
      });
    }
  }

  String _getErrorMessage(ApiException e) {
    if (e is ServerException) {
      if (e.statusCode == 404) {
        return 'حساب غير موجود.';
      } else if (e.statusCode == 403) {
        return 'رابط التحقق غير صحيح أو انتهت صلاحيته.';
      } else if (e.statusCode == 422) {
        return 'لا يمكن التحقق من البريد الإلكتروني.';
      }
    } else if (e is NetworkException) {
      return 'خطأ في الاتصال. تحقق من الإنترنت.';
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'التحقق من البريد',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1A1A1A),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),

                // Icon
                if (!_verificationComplete)
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor:
                        const Color(0xff4D41DF).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      size: 40.sp,
                      color: const Color(0xff4D41DF),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor:
                        Colors.green.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40.sp,
                      color: Colors.green,
                    ),
                  ),
                SizedBox(height: 24.h),

                // Title
                Text(
                  _verificationComplete ? 'تم التحقق! ✓' : 'تحقق من بريدك الإلكتروني',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1A1A1A),
                  ),
                ),
                SizedBox(height: 16.h),

                // Email display
                if (!_verificationComplete)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xffEFEFEF)),
                    ),
                    child: Text(
                      widget.user.email,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        color: const Color(0xff4D41DF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!_verificationComplete) SizedBox(height: 20.h),

                // Description
                if (!_verificationComplete)
                  Text(
                    'أرسلنا رابط تحقق إلى بريدك الإلكتروني. '
                    'انقر على الرابط لتأكيد حسابك والمتابعة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15.sp,
                      color: const Color(0xff707070),
                      height: 1.5,
                    ),
                  ),
                if (!_verificationComplete) SizedBox(height: 32.h),

                // Loading or success message
                if (_isVerifying)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff4D41DF)),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'جاري التحقق...',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: const Color(0xff707070),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  )
                else if (_verificationComplete)
                  Column(
                    children: [
                      Text(
                        'تم تأكيد بريدك الإلكتروني بنجاح. '
                        'جاري المتابعة...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 15.sp,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),

                // Error message
                if (_verificationError != null && !_verificationComplete)
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _verificationError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                if (_verificationError != null && !_verificationComplete)
                  SizedBox(height: 24.h),

                // Resend button
                if (!_verificationComplete)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isVerifying ? null : _checkFirebaseVerification,
                        child: const Text('تحققت من بريدي'),
                      ),
                      SizedBox(height: 12.h),
                      ElevatedButton(
                        onPressed: _isResending ? null : _handleResendClick,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4D41DF),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 14.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          disabledBackgroundColor: const Color(0xffDDD),
                        ),
                        child: _isResending
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'إعادة إرسال رابط التحقق',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),

                SizedBox(height: 24.h),

                // Help text
                if (!_verificationComplete)
                  Text(
                    'لم تستقبل البريد؟ تحقق من مجلد الرسائل غير المرغوبة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      color: const Color(0xff999999),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
