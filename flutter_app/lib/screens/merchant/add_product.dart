import 'dart:io';

import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/widgets/add_product_textfield.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  bool isEnabled1 = false;
  bool isEnabled2 = false;

  final List<File> _attachedImages = [];
  final int _maxImages = 3;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController       = TextEditingController();
  final TextEditingController _priceController      = TextEditingController();
  final TextEditingController _categoryController   = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryListRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _publishProduct(BuildContext context) {
    final name        = _nameController.text.trim();
    final priceText   = _priceController.text.trim();
    final category    = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showSnackBar(context, 'يرجى إدخال اسم المنتج');
      return;
    }
    final price = double.tryParse(priceText) ?? 0.0;
    if (price <= 0) {
      _showSnackBar(context, 'يرجى إدخال سعر صحيح');
      return;
    }

    context.read<ProductBloc>().add(ProductCreateRequested(
          name: name,
          category: category.isNotEmpty ? category : 'عام',
          price: price,
          description: description,
          isVisible: isEnabled1,
          isFeatured: isEnabled2,
          imagePaths: _attachedImages.map((f) => f.path).toList(),
        ));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null && _attachedImages.length < _maxImages) {
        setState(() => _attachedImages.add(File(pickedFile.path)));
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('الكاميرا', style: GoogleFonts.ibmPlexSans()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('المعرض', style: GoogleFonts.ibmPlexSans()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.ibmPlexSans(color: Colors.white)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductCreated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم نشر المنتج بنجاح ✅',
                style: GoogleFonts.ibmPlexSans(color: Colors.white)),
            backgroundColor: const Color(0xff22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ));
          _nameController.clear();
          _priceController.clear();
          _categoryController.clear();
          _descriptionController.clear();
          setState(() {
            _attachedImages.clear();
            isEnabled1 = false;
            isEnabled2 = false;
          });
          Navigator.maybePop(context);
        } else if (state is ProductFailure) {
          _showSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ProductLoading;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xffF8F9FD),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xff1A1A1A), size: 20.sp),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text('إضافة منتج جديد',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1A1A1A))),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Images section ──
                  _buildImagesSection(),
                  SizedBox(height: 20.h),

                  // ── Form fields ──
                  AddProductTextField(
                    controller: _nameController,
                    label: 'اسم المنتج',
                    hint: 'مثال: حذاء رياضي نايك',
                    icon: Icons.inventory_2_outlined,
                  ),
                  SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _priceController,
                    label: 'السعر (₪)',
                    hint: 'مثال: 150',
                    icon: Icons.attach_money_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _categoryController,
                    label: 'التصنيف',
                    hint: 'مثال: ملابس، إلكترونيات...',
                    icon: Icons.category_outlined,
                  ),
                  SizedBox(height: 8.h),
                  _buildCategoryChips(),
                  SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    hint: 'اكتب وصفاً للمنتج...',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  SizedBox(height: 20.h),

                  // ── Toggles ──
                  _buildToggleRow(
                    label: 'إظهار المنتج',
                    value: isEnabled1,
                    onChanged: (v) => setState(() => isEnabled1 = v),
                  ),
                  SizedBox(height: 10.h),
                  _buildToggleRow(
                    label: 'منتج مميز',
                    value: isEnabled2,
                    onChanged: (v) => setState(() => isEnabled2 = v),
                  ),
                  SizedBox(height: 28.h),

                  SizeButton(
                    title: isLoading ? 'جارٍ النشر...' : 'نشر المنتج',
                    onTap: isLoading ? null : () => _publishProduct(context),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Real backend category names as tappable chips, so the merchant can pick
  /// a value that actually resolves to a category_id instead of typing an
  /// arbitrary string that the backend won't recognize.
  Widget _buildCategoryChips() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is! CategoriesLoaded || state.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 34.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final name = state.categories[index];
              return ChoiceChip(
                label: Text(
                  name,
                  style: GoogleFonts.ibmPlexSans(fontSize: 12.sp),
                ),
                selected: _categoryController.text.trim() == name,
                onSelected: (_) =>
                    setState(() => _categoryController.text = name),
                selectedColor: const Color(0xff4D41DF),
                labelStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 12.sp,
                  color: _categoryController.text.trim() == name
                      ? Colors.white
                      : const Color(0xff555555),
                ),
                backgroundColor: const Color(0xffF2F3F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('صور المنتج (${_attachedImages.length}/$_maxImages)',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1A1A1A))),
        SizedBox(height: 10.h),
        Row(
          children: [
            ..._attachedImages.map(
              (file) => Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.file(file,
                          width: 72.w,
                          height: 72.w,
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      left: 2,
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _attachedImages.remove(file)),
                        child: Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 12.sp, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_attachedImages.length < _maxImages)
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                        color: const Color(0xffDDDDDD),
                        style: BorderStyle.solid),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      size: 28.sp, color: const Color(0xffAAAAAA)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffEFEFEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 14.sp, color: const Color(0xff1A1A1A))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
