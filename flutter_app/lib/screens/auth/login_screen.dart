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

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال البريد الإلكتروني وكلمة المرور',
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
        if (state is AuthAuthenticated) {
          // Load cart and favorites for the new session.
          context.read<CartBloc>().add(const CartLoadRequested());
          context.read<FavoriteBloc>().add(const FavoritesLoadRequested());
          final type = state.user.role;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BnScreen(type: type)),
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
        final isLoading = state is AuthLoading;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xffF8F9FD),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
                                  'Tradex',
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
                              'مرحباً بعودتك 👋',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.type == AppType.merchant
                                  ? 'سجل دخولك لإدارة متجرك'
                                  : 'سجل دخولك للتسوق الذكي',
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
                      Text('البريد الإلكتروني',
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
                      Text('كلمة المرور',
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
                              Text('تذكرني',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13.sp,
                                      color: const Color(0xff555555))),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to forgot password
                            },
                            child: Text(
                              'نسيت كلمة المرور؟',
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
                        title:
                            isLoading ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول',
                        onTap: isLoading ? null : () => _handleLogin(context),
                      ),

                      SizedBox(height: 20.h),
                      _buildDivider(),
                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          Expanded(
                            child: socialButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: socialButton(
                              label: 'Apple',
                              icon: Icons.apple_rounded,
                            ),
                          ),
                        ],
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

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFEFEFEF))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text('أو المتابعة عبر',
              style: GoogleFonts.ibmPlexSans(
                  color: Colors.black38, fontSize: 12.sp)),
        ),
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFEFEFEF))),
      ],
    );
  }

  Widget _buildFooter(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟ ',
          style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff707070), fontSize: 13.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'أنشئ حساباً جديداً',
            style: GoogleFonts.ibmPlexSans(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp),
          ),
        ),
      ],
    );
  }

  Widget socialButton({required String label, required IconData icon}) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تسجيل الدخول عبر $label غير متاح حالياً.')),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24.sp, color: Colors.black87),
            SizedBox(width: 6.w),
            Text(label,
                style: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
