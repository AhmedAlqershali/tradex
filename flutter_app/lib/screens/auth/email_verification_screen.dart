import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/code_register.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailVerificationScreen extends StatefulWidget {
  final AppType type;

  const EmailVerificationScreen({super.key, required this.type});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يرجى إدخال البريد الإلكتروني',
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserController.instance.forgotPassword(email: email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CodeRegister(type: widget.type, email: email),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            e is NetworkException
                ? 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.'
                : (UserController.instance.authErrorNotifier.value ??
                    'حدث خطأ. حاول مرة أخرى.'),
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ غير متوقع. حاول مرة أخرى.',
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xff4D41DF);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),

                          // أيقونة توضيحية علوية
                          CircleAvatar(
                            radius: 45.r,
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.lock_open_rounded, color: primaryColor, size: 40.sp),
                          ),
                          SizedBox(height: 32.h),

                          // النصوص الرئيسية
                          Text(
                            'نسيت كلمة المرور؟',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1A1A1A),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'أدخل بريدك الإلكتروني المسجل وسنقوم بإرسال رمز استعادة الحساب إليك.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14.sp,
                              color: const Color(0xff707070),
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 40.h),

                          // حقل إدخال البريد الإلكتروني
                          _buildInputLabel("البريد الإلكتروني"),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                            decoration: InputDecoration(
                              hintText: 'example@domain.com',
                              hintStyle: TextStyle(color: Colors.black26, fontSize: 13.sp),
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.black38, size: 22.sp),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(color: Color(0xffEFEFEF)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(color: Color(0xffEFEFEF)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(color: primaryColor, width: 1.5),
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),

                          // زر إرسال الرمز
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor:
                                    const Color(0xffE0E0E0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 22.w,
                                      height: 22.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'إرسال الرمز',
                                          style: GoogleFonts.ibmPlexSans(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Icon(Icons.send_rounded,
                                            color: Colors.white,
                                            size: 18.sp),
                                      ],
                                    ),
                            ),
                          ),

                          const Spacer(),

                          // زر العودة لتسجيل الدخول
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'العودة لتسجيل الدخول',
                                  style: GoogleFonts.ibmPlexSans(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: primaryColor),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            color: const Color(0xff707070),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}