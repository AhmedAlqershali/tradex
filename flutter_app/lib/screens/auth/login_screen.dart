import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/navigation/nav_shell.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final AppType type;
  const LoginScreen({super.key, required this.type});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _rememberMe = false;
  bool _isForgotPasswordSubmitting = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _forgotPasswordEmailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _forgotPasswordEmailCtrl.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.enterEmailPassword,
            style: GoogleFonts.ibmPlexSans(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthLoginRequested(
          email: email,
          password: password,
          role: widget.type,
        ));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4D41DF);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state is AuthAuthenticated) {
          // Load cart and favorites for the new session.
          context.read<CartBloc>().add(const CartLoadRequested());
          context.read<FavoriteBloc>().add(const FavoritesLoadRequested());
          final type = state.user.role;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BnScreen(type: type)),
          );
        } else if (state is AuthOtpSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.otpSent,
                style: GoogleFonts.ibmPlexSans(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.ibmPlexSans()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final isLoading = state is AuthLoading;

        return Directionality(
          textDirection: l10n.textDirection,
          child: Scaffold(
            backgroundColor: const Color(0xffF8F9FD),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    10.h,
                    20.w,
                    16.h + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ======= كارت الترحيب الذكي =======
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryColor, Color(0xFF3127A5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(Icons.flash_on_rounded,
                                      color: Colors.white, size: 20.sp),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  l10n.appName,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              l10n.welcomeBack,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.type == AppType.merchant
                                  ? l10n.welcomeBackMerchant
                                  : l10n.welcomeBackClient,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14.sp,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // ── Email ──
                      Text(l10n.email,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1A1A1A))),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              size: 18.sp, color: const Color(0xffAAAAAA)),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      // ── Password ──
                      Text(l10n.password,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1A1A1A))),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscureText,
                        style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline,
                              size: 18.sp, color: const Color(0xffAAAAAA)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18.sp,
                              color: const Color(0xffAAAAAA),
                            ),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(l10n.rememberMe,
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13.sp,
                                      color: const Color(0xff555555))),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: Text(
                              l10n.forgotPassword,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13.sp,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      SizeButton(
                        title: isLoading ? l10n.loginLoading : l10n.login,
                        onTap: isLoading ? null : () => _handleLogin(context),
                      ),

                      SizedBox(height: 24.h),
                      Center(child: _buildFooter(primaryColor)),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            l10n.resetPassword,
            style: GoogleFonts.ibmPlexSans(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.otpSent,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    color: const Color(0xff555555),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _forgotPasswordEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      size: 18.sp,
                      color: const Color(0xffAAAAAA),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.ibmPlexSans(),
              ),
            ),
            FilledButton(
              onPressed: _isForgotPasswordSubmitting ? null : () {
                final email = _forgotPasswordEmailCtrl.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.enterEmailPlease,
                        style: GoogleFonts.ibmPlexSans(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (!emailRegExp.hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.enterValidEmail,
                        style: GoogleFonts.ibmPlexSans(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                setState(() => _isForgotPasswordSubmitting = true);
                _forgotPasswordEmailCtrl.clear();
                context.read<AuthBloc>().add(
                  AuthForgotPasswordRequested(email: email),
                );

                Future.microtask(() {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                });
              },
              child: _isForgotPasswordSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.sendResetLink,
                      style: GoogleFonts.ibmPlexSans(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(Color primaryColor) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.noAccount,
          style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff707070), fontSize: 13.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            l10n.createAccount,
            style: GoogleFonts.ibmPlexSans(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp),
          ),
        ),
      ],
    );
  }

}
