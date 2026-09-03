import 'dart:io';

import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/widgets/add_product_textfield.dart';
import 'package:ai_saas/screens/widgets/size_button.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key, this.product});

  final Product? product;

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  bool isEnabled1 = true;
  bool isEnabled2 = false;

  final List<File> _attachedImages = [];
  final List<String> _existingImageUrls = [];
  bool _clearExistingImages = false;
  final int _maxImages = 3;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController       = TextEditingController();
  final TextEditingController _priceController      = TextEditingController();
  final TextEditingController _quantityController   = TextEditingController();
  final TextEditingController _categoryController   = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryListRequested());
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(2);
      _quantityController.text = product.quantity.toString();
      _categoryController.text = product.category;
      _descriptionController.text = product.description;
      isEnabled1 = product.isVisible;
      _existingImageUrls.addAll(product.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _publishProduct(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name        = _nameController.text.trim();
    final priceText   = _priceController.text.trim();
    final category    = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showSnackBar(context, l10n.productNameRequired);
      return;
    }
    final price = double.tryParse(priceText) ?? 0.0;
    if (price <= 0) {
      _showSnackBar(context, l10n.productPriceRequired);
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      _showSnackBar(context, l10n.quantityRequired);
      return;
    }

    final imagePaths = _attachedImages.map((f) => f.path).toList();
    if (widget.product == null) {
      context.read<ProductBloc>().add(ProductCreateRequested(
            name: name,
            category: category.isNotEmpty ? category : l10n.generalCategory,
            price: price,
            description: description,
            quantity: quantity,
            isVisible: isEnabled1,
            isFeatured: isEnabled2,
            imagePaths: imagePaths,
          ));
    } else {
      context.read<ProductBloc>().add(ProductUpdateRequested(
            widget.product!.id,
            name: name,
            category: category.isNotEmpty ? category : l10n.generalCategory,
            price: price,
            description: description,
            quantity: quantity,
            isVisible: isEnabled1,
            isFeatured: isEnabled2,
            imagePaths: imagePaths,
            clearImages: _clearExistingImages && imagePaths.isEmpty,
          ));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 70);
       if (pickedFile != null &&
           _existingImageUrls.length + _attachedImages.length < _maxImages) {
        setState(() => _attachedImages.add(File(pickedFile.path)));
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.camera, style: GoogleFonts.ibmPlexSans()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery, style: GoogleFonts.ibmPlexSans()),
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
        if (state is ProductCreated || state is ProductUpdated) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(
               widget.product == null
                   ? l10n.productPublished
                   : l10n.productUpdated,
                style: GoogleFonts.ibmPlexSans(color: Colors.white)),
            backgroundColor: const Color(0xff22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ));
          Navigator.maybePop(context);
        } else if (state is ProductFailure) {
          _showSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final isLoading = state is ProductLoading;

        return Directionality(
          textDirection: l10n.textDirection,
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
               title: Text(widget.product == null ? l10n.addProductNew : l10n.editProduct,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1A1A1A))),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16.w,
                16.h,
                16.w,
                20.h + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Images section ──
                  _buildImagesSection(),
                  SizedBox(height: 20.h),

                  // ── Form fields ──
                  AddProductTextField(
                    controller: _nameController,
                    label: l10n.productNameLabel,
                    hint: l10n.productExample,
                    icon: Icons.inventory_2_outlined,
                  ),
                  SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _priceController,
                    label: l10n.productPriceLabel,
                    hint: l10n.priceExample,
                    icon: Icons.attach_money_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 14.h),

                   AddProductTextField(
                     controller: _quantityController,
                     label: l10n.productQuantityLabel,
                     hint: l10n.quantityExample,
                     icon: Icons.inventory_outlined,
                     keyboardType: TextInputType.number,
                   ),
                   SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _categoryController,
                    label: l10n.categoryLabel,
                    hint: l10n.categoryExample,
                    icon: Icons.category_outlined,
                  ),
                  SizedBox(height: 8.h),
                  _buildCategoryChips(),
                  SizedBox(height: 14.h),

                  AddProductTextField(
                    controller: _descriptionController,
                    label: l10n.descriptionLabel,
                    hint: l10n.productDescriptionExample,
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
                     title: isLoading
                         ? (widget.product == null
                             ? 'جارٍ النشر...'
                             : 'جارٍ التحديث...')
                         : (widget.product == null ? 'نشر المنتج' : 'حفظ التعديلات'),
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
        Text(
          'صور المنتج (${_existingImageUrls.length + _attachedImages.length}/$_maxImages)',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1A1A1A),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 72.w,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            reverse: AppLocalizations.of(context).isArabic,
            children: [
              ..._existingImageUrls.map(
                (url) => Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.network(
                      url,
                      width: 72.w,
                      height: 72.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72.w,
                        height: 72.w,
                        color: const Color(0xffF0F1F5),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
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
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _attachedImages.remove(file)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_existingImageUrls.length + _attachedImages.length < _maxImages)
                _buildAddImageButton(),
            ],
          ),
        ),
        if (_existingImageUrls.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() {
                _existingImageUrls.clear();
                _clearExistingImages = true;
              }),
              child: Text(
                'حذف الصور الحالية',
                style: GoogleFonts.ibmPlexSans(
                    color: Colors.redAccent, fontSize: 11.sp),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xffDDDDDD)),
        ),
        child: Icon(Icons.add_photo_alternate_outlined,
            size: 28.sp, color: const Color(0xffAAAAAA)),
      ),
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
