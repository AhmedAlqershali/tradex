import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/core/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _fieldErrors = <String, String>{};

  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _apiError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _fieldErrors.clear();
    setState(() => _apiError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await UserService.instance.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    } on ValidationException catch (error) {
      if (!mounted) return;
      final errors = error.errors;
      setState(() {
        _isSubmitting = false;
        _apiError = errors.isEmpty ? error.message : null;
        for (final entry in errors.entries) {
          final key = entry.key == 'new_password_confirmation'
              ? 'new_password'
              : entry.key;
          if (entry.value.isNotEmpty) _fieldErrors[key] = entry.value.first;
        }
      });
      _formKey.currentState?.validate();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _apiError = _localizedApiError(error, AppLocalizations.of(context));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _apiError = AppLocalizations.of(context).unexpectedError;
      });
    }
  }

  String _localizedApiError(ApiException error, AppLocalizations l10n) {
    if (error is AuthException) return l10n.sessionExpired;
    if (error is ForbiddenException) return l10n.forbidden;
    if (error is NetworkException) return l10n.networkError;
    if (error is TimeoutException) return l10n.timeoutError;
    if (error is ServerException) return l10n.serverError;
    return error.message;
  }

  String? _errorFor(String key) => _fieldErrors[key];

  String? _required(String? value, AppLocalizations l10n, String key) {
    final serverError = _errorFor(key);
    if (serverError != null) return serverError;
    if (value == null || value.isEmpty) return l10n.passwordRequired;
    return null;
  }

  String? _newPasswordValidator(String? value, AppLocalizations l10n) {
    final required = _required(value, l10n, 'new_password');
    if (required != null) return required;
    if (value!.length < 6) return l10n.passwordMinLength;
    return null;
  }

  String? _confirmValidator(String? value, AppLocalizations l10n) {
    final required = _required(value, l10n, 'new_password_confirmation');
    if (required != null) return required;
    if (value != _newController.text) return l10n.passwordMismatch;
    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool visible,
    required VoidCallback toggle,
    required AppLocalizations l10n,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        tooltip: visible ? l10n.hidePassword : l10n.showPassword,
        onPressed: toggle,
        icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.changePassword),
          leading: IconButton(
            tooltip: l10n.passwordCancel,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: _isSuccess
              ? _buildSuccess(l10n)
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    16.h,
                    20.w,
                    16.h + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.changePassword,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0d1e3d),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.passwordDescription,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14.sp,
                            color: const Color(0xff707070),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        _passwordField(
                          controller: _currentController,
                          label: l10n.passwordCurrent,
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_showCurrent,
                          visible: _showCurrent,
                          toggle: () =>
                              setState(() => _showCurrent = !_showCurrent),
                          l10n: l10n,
                          validator: (value) =>
                              _required(value, l10n, 'current_password'),
                        ),
                        SizedBox(height: 12.h),
                        _passwordField(
                          controller: _newController,
                          label: l10n.passwordNew,
                          icon: Icons.lock_reset_outlined,
                          obscureText: !_showNew,
                          visible: _showNew,
                          toggle: () => setState(() => _showNew = !_showNew),
                          l10n: l10n,
                          validator: (value) =>
                              _newPasswordValidator(value, l10n),
                        ),
                        SizedBox(height: 12.h),
                        _passwordField(
                          controller: _confirmController,
                          label: l10n.passwordConfirm,
                          icon: Icons.verified_user_outlined,
                          obscureText: !_showConfirm,
                          visible: _showConfirm,
                          toggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          l10n: l10n,
                          validator: (value) => _confirmValidator(value, l10n),
                        ),
                        if (_apiError != null) ...[
                          SizedBox(height: 18.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              _apiError!,
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.redAccent,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 28.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.passwordSave),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required bool visible,
    required VoidCallback toggle,
    required AppLocalizations l10n,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      decoration: _decoration(
        label: label,
        icon: icon,
        visible: visible,
        toggle: toggle,
        l10n: l10n,
      ),
      validator: validator,
      onChanged: (_) {
        if (_apiError != null || _fieldErrors.isNotEmpty) {
          setState(() {
            _apiError = null;
            _fieldErrors.clear();
          });
        }
      },
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.check_rounded, color: Colors.green, size: 52.sp),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.passwordChanged,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0d1e3d),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.passwordSuccessDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                color: const Color(0xff707070),
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.passwordBackToProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
