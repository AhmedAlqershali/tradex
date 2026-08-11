import 'dart:io';

import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/widgets/add_product_textfield.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ─── Store Settings Screen ───────────────────────────────────────────────────
//
// Lets a merchant view and edit their store profile: name, description, and
// logo. Saves via StoreBloc → PUT /merchant/stores/:id and
// POST /merchant/stores/:id/logo (both already implemented in StoreService —
// this screen was the missing UI layer on top of them).
// ─────────────────────────────────────────────────────────────────────────────

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _pickedLogo;
  String? _currentLogoUrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    context.read<StoreBloc>().add(const MyStoreLoadRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefill(StoreModel store) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = store.title;
    _descriptionController.text = store.subTitle;
    _phoneController.text = store.phone ?? '';
    _currentLogoUrl = store.imageUrl;
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null && mounted) {
        setState(() => _pickedLogo = File(picked.path));
        // Upload immediately — the logo endpoint is separate from the
        // name/description update endpoint.
        if (!mounted) return;
        context.read<StoreBloc>().add(StoreLogoUploadRequested(picked.path));
      }
    } catch (e) {
      debugPrint('StoreSettings logo picker error: $e');
    }
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('يرجى إدخال اسم المتجر');
      return;
    }
    context.read<StoreBloc>().add(
          MyStoreUpdateRequested(
            name: name,
            description: _descriptionController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
  }

  void _showSnack(String msg, {Color color = _primary}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.ibmPlexSans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xff1A1A1A)),
          title: Text(
            'إعدادات المتجر',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xff1A1A1A),
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<StoreBloc, StoreState>(
          listener: (context, state) {
            if (state is MyStoreLoaded) {
              _prefill(state.store);
            } else if (state is StoreUpdated) {
              _showSnack('تم حفظ إعدادات المتجر ✅', color: const Color(0xff22C55E));
            } else if (state is StoreFailure) {
              _showSnack(state.message, color: Colors.redAccent);
            }
          },
          builder: (context, state) {
            final isLoading = state is StoreLoading && !_initialized;
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final isSaving = state is StoreLoading;

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildLogoPicker()),
                  SizedBox(height: 28.h),
                  Text(
                    'اسم المتجر',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff555555),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AppTextField(name: 'اسم المتجر', controller: _nameController),
                  SizedBox(height: 18.h),
                  Text(
                    'وصف المتجر',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff555555),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  AppTextField(
                    name: 'اكتب وصفاً مختصراً لمتجرك',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  SizedBox(height: 28.h),
                  SizeButton(
                    title: isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                    onTap: isSaving ? null : () => _save(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Stack(
        children: [
          Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primary.withValues(alpha: 0.08),
              image: _pickedLogo != null
                  ? DecorationImage(
                      image: FileImage(_pickedLogo!), fit: BoxFit.cover)
                  : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(_currentLogoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: (_pickedLogo == null &&
                    (_currentLogoUrl == null || _currentLogoUrl!.isEmpty))
                ? Icon(Icons.storefront_outlined, size: 36.sp, color: _primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
              ),
              child: Icon(Icons.camera_alt, size: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
