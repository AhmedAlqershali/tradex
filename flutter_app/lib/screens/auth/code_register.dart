import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/new_password_screen.dart';
import 'package:ai_saas/screens/widgets/code_text_field.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeRegister extends StatefulWidget {
  final AppType type;

  /// The email address that the OTP was sent to.
  /// Passed from the forgot-password flow and forwarded to [NewPasswordScreen].
  final String email;

  const CodeRegister({
    super.key,
    required this.type,
    required this.email,
  });

  @override
  State<CodeRegister> createState() => _CodeRegisterState();
}

class _CodeRegisterState extends State<CodeRegister> {
  late TextEditingController _firstCodeTextController;
  late TextEditingController _secondCodeTextController;
  late TextEditingController _thirdCodeTextController;
  late TextEditingController _fourthCodeTextController;

  late FocusNode _firstFocusNode;
  late FocusNode _secondFocusNode;
  late FocusNode _thirdFocusNode;
  late FocusNode _fourthFocusNode;

  late TextEditingController _passwordTextController;
  late TextEditingController _passwordConfirmationTextController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstCodeTextController = TextEditingController();
    _secondCodeTextController = TextEditingController();
    _thirdCodeTextController = TextEditingController();
    _fourthCodeTextController = TextEditingController();

    _firstFocusNode = FocusNode();
    _secondFocusNode = FocusNode();
    _thirdFocusNode = FocusNode();
    _fourthFocusNode = FocusNode();

    _passwordTextController = TextEditingController();
    _passwordConfirmationTextController = TextEditingController();
  }

  @override
  void dispose() {
    _firstCodeTextController.dispose();
    _secondCodeTextController.dispose();
    _thirdCodeTextController.dispose();
    _fourthCodeTextController.dispose();

    _firstFocusNode.dispose();
    _secondFocusNode.dispose();
    _thirdFocusNode.dispose();
    _fourthFocusNode.dispose();

    _passwordTextController.dispose();
    _passwordConfirmationTextController.dispose();
    super.dispose();
  }

  String get _otp =>
      _firstCodeTextController.text +
      _secondCodeTextController.text +
      _thirdCodeTextController.text +
      _fourthCodeTextController.text;

  Future<void> _handleVerifyOtp() async {
    final otp = _otp;
    final l10n = AppLocalizations.of(context);
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.verificationCodeInputMessage,
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserController.instance
          .verifyOtp(email: widget.email, otp: otp);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(
            type: widget.type,
            email: widget.email,
            otp: otp,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            e is NetworkException
                ? l10n.otpNetworkRetry
                : (UserController.instance.authErrorNotifier.value ??
                    l10n.otpInvalid),
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.genericRetryMessage,
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await UserController.instance.forgotPassword(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l10n.otpResendSuccess} ${widget.email}',
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.green,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.otpResendFailed,
            style: GoogleFonts.ibmPlexSans()),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black87)),
          title: Text(
            l10n.appName,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff4D41DF),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  // أيقونة الحماية والأمان
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor:
                        const Color(0xff4D41DF).withValues(alpha: 0.1),
                    child: Icon(Icons.security_rounded,
                        size: 36.sp, color: const Color(0xff4D41DF)),
                  ),
                  SizedBox(height: 24.h),

                  // العنوان الرئيسي
                  Text(
                    l10n.verificationTitle,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1A1A1A),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // نصوص التوجيه
                  Text(
                    l10n.verificationIntro,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14.sp,
                      color: const Color(0xff707070),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.email,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1A1A1A),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // حقول إدخال الرمز
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CodeTextField(
                        editingController: _firstCodeTextController,
                        focusNode: _firstFocusNode,
                        onChanged: (String value) {
                          if (value.isNotEmpty) {
                            _secondFocusNode.requestFocus();
                          }
                        },
                      ),
                      SizedBox(width: 12.w),
                      CodeTextField(
                        editingController: _secondCodeTextController,
                        focusNode: _secondFocusNode,
                        onChanged: (String value) {
                          value.isNotEmpty
                              ? _thirdFocusNode.requestFocus()
                              : _firstFocusNode.requestFocus();
                        },
                      ),
                      SizedBox(width: 12.w),
                      CodeTextField(
                        editingController: _thirdCodeTextController,
                        focusNode: _thirdFocusNode,
                        onChanged: (String value) {
                          value.isNotEmpty
                              ? _fourthFocusNode.requestFocus()
                              : _secondFocusNode.requestFocus();
                        },
                      ),
                      SizedBox(width: 12.w),
                      CodeTextField(
                        editingController: _fourthCodeTextController,
                        focusNode: _fourthFocusNode,
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            _thirdFocusNode.requestFocus();
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // قسم العداد المؤقتي للرمز
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.didNotReceiveCode,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: const Color(0xff707070),
                        ),
                      ),
                      Text(
                        '0:59',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: const Color(0xff4D41DF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // زر إعادة الإرسال
                  TextButton(
                    onPressed: _isLoading ? null : _handleResendOtp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    child: Text(
                      l10n.resendCode,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                        color: const Color(0xff4D41DF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // زر تأكيد الرمز
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4D41DF),
                        disabledBackgroundColor: const Color(0xffE0E0E0),
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
                          : Text(
                              l10n.confirmCode,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
