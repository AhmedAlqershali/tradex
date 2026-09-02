import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/auth/complete_profile_client_screen.dart';
import 'package:ai_saas/screens/auth/complete_registration_merchant_screen.dart';
import 'package:ai_saas/screens/auth/email_verification_screen.dart';
import 'package:ai_saas/screens/auth/login_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  final AppType type;

  const RegisterScreen({
    super.key,
    required this.type,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color primary = Color(0xff4D41DF);
  static const Color background = Color(0xffF8F9FD);
  static const Color textDark = Color(0xff1A1A1A);
  static const Color textGrey = Color(0xff707070);
  static const Color borderColor = Color(0xffEFEFEF);

  bool _obscureText = true;
  bool _agreeToTerms = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError(l10n.enterEmailPassword);
      return;
    }

    if (password.length < 6) {
      _showError(l10n.passwordMinLength);
      return;
    }

    if (!_agreeToTerms) {
      _showError(l10n.termsAgreementText);
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: name,
            email: email,
            phone: phone,
            password: password,
            role: widget.type,
          ),
        );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
          ),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    TextDirection hintDirection = TextDirection.rtl,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: hintDirection,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: const Color(0xffAAAAAA),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      color: textDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAwaitingEmailVerification) {
          // After registration, show email verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                user: state.user,
                role: state.role,
                onVerificationSuccess: (verifiedUser) async {
                  await UserController.instance.loginPendingVerification(
                    email: verifiedUser.email,
                    role: state.role,
                  );
                  // After verification, navigate to profile completion
                  if (state.role == AppType.merchant) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompleteProfileMerchantScreen(
                          type: AppType.merchant,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompleteProfileClientScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          if (widget.type == AppType.merchant) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompleteProfileMerchantScreen(
                  type: AppType.merchant,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompleteProfileClientScreen(),
              ),
            );
          }
        }

        if (state is AuthFailure) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final bool isLoading = state is AuthLoading;
        final l10n = AppLocalizations.of(context);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: textDark,
                ),
                onPressed: () {
                  Navigator.maybePop(context);
                },
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),

// TITLE
                          Text(
                            l10n.registerNewAccount,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),

                          const SizedBox(height: 7),

// SUBTITLE
                          Text(
                            widget.type == AppType.merchant
                                ? l10n.registerMerchantSubtitle
                                : l10n.registerClientSubtitle,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: textGrey,
                            ),
                          ),

                          const SizedBox(height: 28),

// NAME
                          _buildLabel(l10n.fullName),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _nameCtrl,

// مهم جدًا للعربي
                            keyboardType: TextInputType.text,

                            textInputAction: TextInputAction.next,

                            textDirection: TextDirection.rtl,

                            textAlign: TextAlign.right,

                            autocorrect: true,

                            enableSuggestions: true,

                            style: _inputTextStyle(),

                            decoration: _inputDecoration(
                              hint: l10n.fullNameExample,
                              icon: Icons.person_outline,
                            ),
                          ),

                          const SizedBox(height: 17),

// EMAIL
                          _buildLabel(
                            l10n.email,
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: _inputTextStyle(),
                            decoration: _inputDecoration(
                              hint: 'example@email.com',
                              hintDirection: TextDirection.ltr,
                              icon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 17),

// PHONE
                          _buildLabel(
                            l10n.phoneNumber,
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: _inputTextStyle(),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(
                                  r'[0-9+\-\s]',
                                ),
                              ),
                            ],
                            decoration: _inputDecoration(
                              hint: l10n.phoneNumberExample,
                              hintDirection: TextDirection.ltr,
                              icon: Icons.phone_outlined,
                            ),
                          ),

                          const SizedBox(height: 17),

// PASSWORD
                          _buildLabel(
                            l10n.password,
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscureText,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: _inputTextStyle(),
                            decoration: _inputDecoration(
                              hint: 'abcdef',
                              hintDirection: TextDirection.ltr,
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: const Color(
                                    0xffAAAAAA,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              l10n.passwordMinLength,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                          ),

                          const SizedBox(height: 11),

// TERMS
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    activeColor: primary,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.agreeTermsAndPrivacy,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: const Color(
                                        0xff555555,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

// REGISTER
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: SizeButton(
                              title: isLoading
                                  ? l10n.creatingAccount
                                  : l10n.createAccountAction,
                              onTap: isLoading
                                  ? null
                                  : () => _handleRegister(
                                        context,
                                      ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          const SizedBox(height: 25),

// LOGIN
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${l10n.alreadyHaveAccount} ',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.ibmPlexSans(
                                    color: textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(
                                          type: widget.type,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    l10n.loginNow,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.ibmPlexSans(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

}
