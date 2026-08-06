import 'dart:io';

import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/navigation/nav_shell.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfilePhotoScreen extends StatefulWidget {
  const CompleteProfilePhotoScreen({super.key});

  @override
  State<CompleteProfilePhotoScreen> createState() =>
      _CompleteProfilePhotoScreenState();
}

class _CompleteProfilePhotoScreenState
    extends State<CompleteProfilePhotoScreen> {
  static const Color _primary = Color(0xFF4D41DF);
  static const Color _background = Color(0xFFF8F9FD);
  static const Color _darkText = Color(0xFF1A1A1A);
  static const Color _grayText = Color(0xFF888888);

  final TextEditingController _aiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked == null || !mounted) return;

      setState(() {
        _imageFile = File(picked.path);
      });
    } catch (e) {
      debugPrint('Photo picker error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر اختيار الصورة'),
        ),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                12.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'اختر مصدر الصورة',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.photo_library_outlined,
                      color: _primary,
                      size: 24.sp,
                    ),
                    title: Text(
                      'معرض الصور',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.camera_alt_outlined,
                      color: _primary,
                      size: 24.sp,
                    ),
                    title: Text(
                      'الكاميرا',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14.sp,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadAndProceed() async {
    if (_imageFile == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserController.instance.updateProfile(
        photoPath: _imageFile!.path,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          const BnScreen(
            type: AppType.client,
          ),
        ),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Profile photo upload error: $e');

      if (!mounted) return;

      final message =
          UserController.instance.authErrorNotifier.value ??
              'فشل رفع الصورة. يمكنك المتابعة والتغيير لاحقاً.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skip() async {
    if (_isLoading) return;

    try {
      await UserController.instance.ensureClientUser();
    } catch (e) {
      debugPrint('Ensure client user error: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const BnScreen(
          type: AppType.client,
        ),
      ),
          (route) => false,
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 140.r,
        height: 140.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF2F3F6),
          border: Border.all(
            color: _primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: _imageFile != null
              ? Image.file(
            _imageFile!,
            width: 140.r,
            height: 140.r,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.broken_image_outlined,
                size: 36.r,
                color: _primary,
              );
            },
          )
              : Icon(
            Icons.add_a_photo_outlined,
            size: 36.r,
            color: _primary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: (_imageFile == null || _isLoading)
                  ? null
                  : _uploadAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
                  : Text(
                'رفع صورة',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: SizedBox(
            height: 50.h,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _skip,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _primary.withValues(alpha: 0.15),
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'تخطي',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB1BFFF),
            Color(0xFF86FAFF),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: _primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'لا تملك صورة؟ اصنع واحدة تشبهك',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'كيف تود أن تبدو صورتك؟',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12.sp,
              color: _primary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 12.h),

// استخدام Wrap بدلاً من Row يمنع مشاكل overflow
// على الشاشات الصغيرة.
          LayoutBuilder(
            builder: (context, constraints) {
              final double buttonWidth = 72.w;
              final double gap = 8.w;
              final double fieldWidth =
                  constraints.maxWidth - buttonWidth - gap;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: fieldWidth > 0 ? fieldWidth : 1,
                    height: 44.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: TextField(
                        controller: _aiController,
                        maxLines: 1,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: 'وصف تفصيلي للصورة...',
                          hintStyle: GoogleFonts.ibmPlexSans(
                            color: const Color(0xFFBBBBBB),
                            fontSize: 12.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: buttonWidth,
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () {
                        final prompt = _aiController.text.trim();

                        if (prompt.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'اكتب وصفاً للصورة أولاً',
                              ),
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ميزة إنشاء الصورة بالذكاء الاصطناعي قيد التجهيز',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _primary.withValues(alpha: 0.15),
                        foregroundColor: _primary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        'إنشاء',
                        style: GoogleFonts.ibmPlexSans(
                          color: _primary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'رفع صورة شخصية',
            style: GoogleFonts.ibmPlexSans(
              color: _grayText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

// مهم:
// يوجد Scaffold واحد فقط.
// لا يوجد Scaffold أو MaterialApp داخل الـ ScrollView.
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 20.h,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      _buildAvatarPicker(),

                      SizedBox(height: 24.h),

                      Text(
                        'أضف صورتك الشخصية لتكتمل هويتك',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        'يمكنك تغيير الصورة لاحقاً من إعدادات الحساب.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13.sp,
                          color: _grayText,
                        ),
                      ),

                      SizedBox(height: 40.h),

                      _buildActionButtons(),

                      SizedBox(height: 36.h),

                      _buildAiCard(),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
