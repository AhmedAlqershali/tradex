import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/success_password_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NewPasswordScreen extends StatefulWidget {
  final AppType type;

  /// The email address used in the forgot-password flow.
  /// Optional when navigating from the profile screen (already logged in).
  final String email;

  /// The reset token from the emailed password-reset link.
  final String token;

  /// Backward-compatible OTP field used by older flows.
  final String otp;

  const NewPasswordScreen({
    super.key,
    this.type = AppType.client,
    this.email = '',
    this.token = '',
    this.otp = '',
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool _obscureText1 = true;
  bool _obscureText2 = true;
  bool _isLoading = false;

  final _newPasswordCtrl    = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context);
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    final resetToken = widget.token.isNotEmpty ? widget.token : widget.otp;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError(l10n.passwordResetRequired);
      return;
    }
    if (newPassword.length < 6) {
      _showError(l10n.passwordMinLength);
      return;
    }
    if (newPassword != confirmPassword) {
      _showError(l10n.passwordMismatch);
      return;
    }
    if (widget.email.isEmpty || resetToken.isEmpty) {
      _showError(l10n.resetLinkInvalidOrExpired);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserController.instance.resetPassword(
        email: widget.email,
        otp: resetToken,
        newPassword: newPassword,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPasswordScreen(type: widget.type),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e is NetworkException
          ? l10n.networkCheck
          : (UserController.instance.authErrorNotifier.value ??
              l10n.genericRetryMessage));
    } catch (_) {
      if (!mounted) return;
      _showError(l10n.genericRetryMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.ibmPlexSans()),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xff4D41DF);
    const Color textColor = Color(0xff1A1A1A);
    const Color subTextColor = Color(0xff707070);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                16.h + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 6.h),

                    // أيقونة القفل
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      child: Icon(Icons.lock_reset_rounded,
                          color: primaryColor, size: 40.sp),
                    ),
                    SizedBox(height: 16.h),

                    // العنوان
                    Text(
                      l10n.passwordResetTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // النص التوضيحي
                    Text(
                      l10n.passwordResetDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.sp,
                        color: subTextColor,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // حقل كلمة المرور الجديدة
                    _buildPasswordField(
                      controller: _newPasswordCtrl,
                      hint: l10n.passwordNewHint,
                      isObscured: _obscureText1,
                      onToggle: () =>
                          setState(() => _obscureText1 = !_obscureText1),
                    ),
                    SizedBox(height: 6.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.passwordRuleHint,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.sp,
                          color: const Color(0xff707070),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // حقل تأكيد كلمة المرور
                    _buildPasswordField(
                      controller: _confirmPasswordCtrl,
                      hint: l10n.passwordConfirmHint,
                      isObscured: _obscureText2,
                      onToggle: () =>
                          setState(() => _obscureText2 = !_obscureText2),
                    ),
                    SizedBox(height: 20.h),

                    // زر التحديث
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.updatePasswordAction,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Icon(Icons.check_circle_outline_rounded,
                                      color: Colors.white, size: 20.sp),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      textAlign: TextAlign.right,
      style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.ibmPlexSans(fontSize: 13.sp, color: Colors.black38),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.black38,
            size: 20.sp,
          ),
          onPressed: onToggle,
        ),
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: Colors.black26),
        filled: true,
        fillColor: const Color(0xffF2F3F6),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: Color(0xff4D41DF), width: 1.5),
        ),
      ),
    );
  }
}
