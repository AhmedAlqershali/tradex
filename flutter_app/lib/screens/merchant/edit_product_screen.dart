import 'dart:io';

import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/widgets/add_product_textfield.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:ai_saas/shared/ai/ai_controller.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ─── Edit Product Screen ──────────────────────────────────────────────────────
//
// Receives an existing [Product] and allows the merchant to update its fields.
// Saves via [ProductBloc] → PUT /products/:id.
//
// Mirrors AddProduct's UX so the experience is consistent.
// ─────────────────────────────────────────────────────────────────────────────

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  static const Color _primary = Color(0xff4D41DF);

  // Form controllers — pre-filled in initState
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  late bool _isVisible;
  late bool _isFeatured;
  bool _aiLoading = false;

  // Images: existing network/file URLs kept as strings; new picks stored as File
  late List<String> _existingImageUrls;
  final List<File> _newImages = [];
  final int _maxImages = 3;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _priceController = TextEditingController(text: p.price.toStringAsFixed(0));
    _categoryController = TextEditingController(text: p.category);
    _descriptionController = TextEditingController(text: p.description);
    _isVisible = p.isVisible;
    _isFeatured = p.isFeatured;
    _existingImageUrls = List.from(p.imageUrls);
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

  // ── Total image count (existing + new) ────────────────────────────────────
  int get _totalImages => _existingImageUrls.length + _newImages.length;

  // ── Save ──────────────────────────────────────────────────────────────────
  void _saveProduct() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showSnack('يرجى إدخال اسم المنتج');
      return;
    }

    final price = double.tryParse(priceText) ?? 0.0;
    if (price <= 0) {
      _showSnack('يرجى إدخال سعر صحيح');
      return;
    }

    // Note: the backend has no per-image add/delete endpoint — uploading any
    // new image replaces the *entire* gallery, and existing (remote) images
    // can't be re-sent since we only have their URLs, not local files. So:
    //   - new images picked → send them, replacing the gallery entirely.
    //   - no new images, but all existing ones were removed → clear gallery.
    //   - otherwise → leave the gallery untouched.
    final newImagePaths = _newImages.map((f) => f.path).toList();
    final shouldClearImages =
        newImagePaths.isEmpty && _existingImageUrls.isEmpty && widget.product.imageUrls.isNotEmpty;

    // Dispatch update event to ProductBloc → PUT /products/:id
    context.read<ProductBloc>().add(
          ProductUpdateRequested(
            widget.product.id,
            name: name,
            price: price,
            category: category.isNotEmpty ? category : 'عام',
            description: description,
            isVisible: _isVisible,
            isFeatured: _isFeatured,
            imagePaths: newImagePaths,
            clearImages: shouldClearImages,
          ),
        );
  }

  // ── AI description ─────────────────────────────────────────────────────────
  Future<void> _generateAIDescription() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty) {
      _showSnack('أدخل اسم المنتج أولاً لتوليد الوصف');
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final result = await AiController.instance.generateProductDescription(
        name: name,
        category: category,
      );
      if (mounted) _descriptionController.text = result.output;
    } catch (e) {
      if (mounted) {
        _showSnack('فشل توليد الوصف. تحقق من اتصالك وحاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_totalImages >= _maxImages) {
      _showSnack('تم الوصول للحد الأقصى (3 صور)');
      return;
    }
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null && mounted) {
        setState(() => _newImages.add(File(picked.path)));
      }
    } catch (e) {
      debugPrint('EditProduct image picker error: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إضافة صورة',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              ListTile(
                leading: Icon(Icons.photo_library, color: _primary),
                title: Text('معرض الصور',
                    style: GoogleFonts.ibmPlexSans(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: _primary),
                title: Text('الكاميرا',
                    style: GoogleFonts.ibmPlexSans(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {Color color = _primary}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductUpdated) {
          _showSnack('تم حفظ التعديلات ✅');
          // Capture navigator before the async gap to avoid
          // use_build_context_synchronously lint warning.
          final nav = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) nav.pop();
          });
        } else if (state is ProductFailure) {
          _showSnack(state.message, color: Colors.redAccent);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xffF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, size: 22.sp, color: Colors.black),
            ),
            title: Text(
              'تعديل المنتج',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            centerTitle: true,
          ),
          body: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              final isLoading = state is ProductLoading;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(Icons.edit_outlined, 'بيانات المنتج'),
                    SizedBox(height: 20.h),

                    _buildLabel('اسم المنتج'),
                    add_product_textfield(
                        name: 'مثال: سماعات لاسلكية',
                        controller: _nameController),
                    SizedBox(height: 16.h),

                    _buildLabel('السعر (₪)'),
                    add_product_textfield(
                        name: '0.00', controller: _priceController),
                    SizedBox(height: 16.h),

                    _buildLabel('الفئة'),
                    add_product_textfield(
                        name: 'مثال: ملابس، كوزمتكس، أحذية',
                        controller: _categoryController),
                    SizedBox(height: 8.h),
                    _buildCategoryChips(),
                    SizedBox(height: 24.h),

                    // AI description card
                    _buildAIDescriptionCard(),
                    SizedBox(height: 24.h),

                    // Image management
                    _buildImageSection(),
                    SizedBox(height: 24.h),

                    // Toggles
                    _buildLabel('الحالة والظهور'),
                    SizedBox(height: 10.h),
                    _buildSwitchTile(
                      Icons.remove_red_eye,
                      'مرئي للجميع',
                      _isVisible,
                      (v) => setState(() => _isVisible = v),
                      const Color(0xff006B5C),
                    ),
                    SizedBox(height: 12.h),
                    _buildSwitchTile(
                      Icons.local_fire_department_rounded,
                      'منتج مميز',
                      _isFeatured,
                      (v) => setState(() => _isFeatured = v),
                      const Color(0xff914800),
                    ),
                    SizedBox(height: 32.h),

                    PrimaryButton(
                      onPressed: isLoading ? null : _saveProduct,
                      name: isLoading ? 'جارٍ الحفظ...' : 'حفظ التعديلات',
                      color: isLoading ? Colors.grey : _primary,
                      size: Size(double.infinity, 54.h),
                      colorname: Colors.white,
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Category picker chips ───────────────────────────────────────────────────
  /// Real backend category names as tappable chips, so the merchant picks a
  /// value that actually resolves to a category_id.
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

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 22.sp),
        SizedBox(width: 8.w),
        Text(title,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff464555))),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text,
          style: GoogleFonts.ibmPlexSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xff464555))),
    );
  }

  // ── AI description card ───────────────────────────────────────────────────
  Widget _buildAIDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('وصف المنتج',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _aiLoading ? null : _generateAIDescription,
                      child: _buildAIButton(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xffF2F3F6),
                    hintText: 'اكتب وصفاً جذاباً لمنتجك...',
                    hintStyle: TextStyle(fontSize: 12.sp),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.05),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16.r))),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _primary, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                    child: Text('نصيحة: الوصف الدقيق يزيد المبيعات بنسبة 40%',
                        style: TextStyle(fontSize: 11.sp, color: _primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: _aiLoading ? _primary.withValues(alpha: 0.6) : _primary,
          borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_aiLoading)
            SizedBox(
              width: 14.w,
              height: 14.h,
              child: const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 1.5),
            )
          else
            Icon(Icons.auto_awesome, color: Colors.white, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            _aiLoading ? 'جارٍ التوليد...' : 'توليد ذكي',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Image management section ───────────────────────────────────────────────
  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('صور المنتج (بحد أقصى 3)'),
          if (_existingImageUrls.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'إضافة صور جديدة ستستبدل جميع صور المنتج الحالية عند الحفظ',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11.sp,
                color: Colors.orange.shade800,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Existing images
                ..._existingImageUrls
                    .asMap()
                    .entries
                    .map((e) => _existingImageSlot(e.key, e.value)),
                // Newly picked images
                ..._newImages
                    .asMap()
                    .entries
                    .map((e) => _newImageSlot(e.key, e.value)),
                // Add button (if slots remain)
                if (_totalImages < _maxImages) _addImageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _existingImageSlot(int index, String url) {
    final bool isNetwork =
        url.startsWith('http://') || url.startsWith('https://');
    return Container(
      margin: EdgeInsets.only(left: 10.w),
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
          image: isNetwork
              ? NetworkImage(url) as ImageProvider
              : FileImage(File(url)),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => _removeExistingImage(index),
          child: CircleAvatar(
              radius: 10.r,
              backgroundColor: Colors.red,
              child: const Icon(Icons.close, size: 12, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _newImageSlot(int index, File file) {
    return Container(
      margin: EdgeInsets.only(left: 10.w),
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => _removeNewImage(index),
          child: CircleAvatar(
              radius: 10.r,
              backgroundColor: Colors.red,
              child: const Icon(Icons.close, size: 12, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _addImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        margin: EdgeInsets.only(left: 10.w),
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          color: const Color(0xffF2F3F6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _primary),
        ),
        child: Icon(Icons.add_a_photo_rounded, color: _primary, size: 26.sp),
      ),
    );
  }

  // ── Switch tile ───────────────────────────────────────────────────────────
  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Text(title,
              style:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          const Spacer(),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}
