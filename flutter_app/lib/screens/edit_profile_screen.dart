import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:ai_saas/shared/users/avatar_diagnostics.dart';
import 'package:ai_saas/core/api/app_config.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/core/services/location_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _currentSelectedLocation;
  File? _pickedPhoto;
  bool _isSaving = false;
  bool _isLocating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = UserController.instance.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentSelectedLocation = user?.region;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        AvatarDiagnostics.begin();
        await AvatarDiagnostics.logSelectedFile(
          path: file.path,
          name: file.name,
          size: await file.length(),
          mimeType: file.mimeType,
          readBytes: file.readAsBytes,
        );
        if (mounted) setState(() => _pickedPhoto = File(file.path));
      }
    } catch (e) {
      debugPrint('Photo pick error: $e');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() => _isSaving = true);

    try {
      await UserController.instance.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        region: _currentSelectedLocation,
        photoPath: _pickedPhoto?.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ التغييرات', style: GoogleFonts.ibmPlexSans()),
          backgroundColor: const Color(0xff623ce7),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.ibmPlexSans()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ التغييرات. حاول مرة أخرى.',
              style: GoogleFonts.ibmPlexSans()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xff623ce7);
    const Color textColor = Color(0xff0d1e3d);
    const Color inputFillColor = Color(0xfff4f6fa);
    const Color scaffoldBgColor = Color(0xfffafdff);

    // Show saved photo or newly picked photo
    final savedPhotoPath = UserController.instance.currentUser?.photoPath;
    ImageProvider? photoImage;
    if (_pickedPhoto != null) {
      photoImage = FileImage(_pickedPhoto!);
    } else if (savedPhotoPath != null && savedPhotoPath.isNotEmpty) {
      if (AppUser.isServerPhotoPath(savedPhotoPath)) {
        photoImage = NetworkImage(AppConfig.resolveMediaUrl(savedPhotoPath));
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.profileInfo,
            style: GoogleFonts.ibmPlexSans(
                color: textColor, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    12.h,
                    20.w,
                    16.h + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. قسم الصورة الشخصية
                        Center(
                          child: GestureDetector(
                            onTap: _pickProfilePhoto,
                            child: Stack(
                              alignment: Alignment.bottomLeft,
                              children: [
                                Container(
                                  width: 110.w,
                                  height: 110.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            primaryColor.withValues(alpha: 0.2),
                                        width: 3.w),
                                    image: photoImage != null
                                        ? DecorationImage(
                                            image: photoImage,
                                            fit: BoxFit.cover)
                                        : const DecorationImage(
                                            image: AssetImage(
                                                'assets/images/client.png'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5.h,
                                  left: 5.w,
                                  child: Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: const BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.camera_alt_rounded,
                                        size: 16.sp, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // 2. حقل الاسم
                        _buildFieldLabel(l10n.fullName),
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.ibmPlexSans(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                          decoration: _inputDecoration(
                            hint: l10n.enterFullName,
                            fillColor: inputFillColor,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // 3. حقل البريد
                        _buildFieldLabel(l10n.email),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.ibmPlexSans(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                          decoration: _inputDecoration(
                            hint: 'example@gmail.com',
                            fillColor: inputFillColor,
                            prefixIcon: Icons.email_outlined,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // 4. حقل الهاتف
                        _buildFieldLabel(l10n.phoneNumber),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.ibmPlexSans(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                          decoration: _inputDecoration(
                            hint: 'أدخل رقم هاتفك',
                            fillColor: inputFillColor,
                            prefixIcon: Icons.phone_outlined,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // 5. حقل الموقع
                        _buildFieldLabel(l10n.currentLocation),
                        DropdownButtonFormField<String>(
                          value: LocationService.supportedRegions
                                  .contains(_currentSelectedLocation)
                              ? _currentSelectedLocation
                              : null,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey, size: 20.sp),
                          dropdownColor: Colors.white,
                          style: GoogleFonts.ibmPlexSans(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                          decoration: _inputDecoration(
                            hint: 'اختر موقعك الحالي',
                            fillColor: inputFillColor,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          items: LocationService.supportedRegions
                              .map((String value) {
                            return DropdownMenuItem<String>(
                                value: value, child: Text(value));
                          }).toList(),
                          onChanged: (newValue) => setState(
                              () => _currentSelectedLocation = newValue),
                        ),
                        SizedBox(height: 24.h),

                        // 5. زر جلب الموقع
                        InkWell(
                          onTap: _isLocating ? null : _useCurrentLocation,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            width: double.infinity,
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  width: 1.w),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isLocating
                                    ? SizedBox(
                                        width: 18.sp,
                                        height: 18.sp,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      )
                                    : Icon(Icons.my_location_rounded,
                                        color: primaryColor, size: 18.sp),
                                SizedBox(width: 10.w),
                                Text(l10n.useCurrentLocation,
                                    style: GoogleFonts.ibmPlexSans(
                                        color: primaryColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. زر حفظ التغييرات
              Padding(
                padding: EdgeInsets.all(24.r),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(l10n.saveChanges,
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      if (result.region == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تم تحديد موقعك، لكن تعذر مطابقة المنطقة تلقائياً. اخترها من القائمة.'),
          ),
        );
        return;
      }
      setState(() => _currentSelectedLocation = result.region);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديد الموقع: ${result.region}')),
      );
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على موقعك الحالي.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Text(label,
          style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff0d1e3d),
              fontWeight: FontWeight.bold,
              fontSize: 14.sp)),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint,
      required Color fillColor,
      required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.ibmPlexSans(color: Colors.black38, fontSize: 13.sp),
      filled: true,
      fillColor: fillColor,
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      prefixIcon: Icon(prefixIcon, color: Colors.black45, size: 20.sp),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xff623ce7), width: 1.5)),
    );
  }
}
