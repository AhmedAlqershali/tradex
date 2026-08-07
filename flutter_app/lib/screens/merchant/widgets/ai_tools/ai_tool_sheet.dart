import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/shared/ai/ai_controller.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AiToolSheet ─────────────────────────────────────────────────────────────
//
// Bottom sheet for AI content generation.
// Promoted from private _AiToolSheet so it can be referenced by
// add_product.dart and any future screen.
// ─────────────────────────────────────────────────────────────────────────────

class AiToolSheet extends StatefulWidget {
  final AiToolType tool;
  final String initialName;
  final String initialCategory;

  const AiToolSheet({
    super.key,
    required this.tool,
    this.initialName = '',
    this.initialCategory = '',
  });

  /// Convenience: open the sheet as a modal bottom sheet.
  static void show(
    BuildContext context,
    AiToolType tool, {
    String initialName = '',
    String initialCategory = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiToolSheet(
        tool: tool,
        initialName: initialName,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<AiToolSheet> createState() => _AiToolSheetState();
}

class _AiToolSheetState extends State<AiToolSheet> {
  final TextEditingController _field1 = TextEditingController();
  final TextEditingController _field2 = TextEditingController();
  final TextEditingController _field3 = TextEditingController();

  bool _loading = false;
  AiResult? _result;

  @override
  void initState() {
    super.initState();
    _field1.text = widget.initialName;
    _field2.text = widget.initialCategory;
  }

  @override
  void dispose() {
    _field1.dispose();
    _field2.dispose();
    _field3.dispose();
    super.dispose();
  }

  // ── Accent color per tool type ─────────────────────────────────────────────
  Color get _accentColor {
    switch (widget.tool) {
      case AiToolType.productDescription: return AppColors.purple;
      case AiToolType.instagramPost:      return AppColors.orange;
      case AiToolType.hashtags:           return AppColors.teal;
      case AiToolType.customerReply:      return AppColors.pink;
    }
  }

  // ── Sheet title ────────────────────────────────────────────────────────────
  String get _sheetTitle {
    switch (widget.tool) {
      case AiToolType.productDescription: return 'كتابة وصف منتج';
      case AiToolType.instagramPost:      return 'إنشاء بوست انستغرام';
      case AiToolType.hashtags:           return 'توليد هاشتاقات';
      case AiToolType.customerReply:      return 'كتابة رد للعميل';
    }
  }

  bool get _canGenerate => _field1.text.trim().isNotEmpty && !_loading;

  // ── Generate ───────────────────────────────────────────────────────────────
  Future<void> _generate() async {
    final ai = AiController.instance;
    setState(() { _loading = true; _result = null; });

    try {
      late final AiResult result;
      switch (widget.tool) {
        case AiToolType.productDescription:
          result = await ai.generateProductDescription(
            name: _field1.text.trim(),
            category: _field2.text.trim(),
            extra: _field3.text.trim(),
          );
          break;
        case AiToolType.instagramPost:
          result = await ai.generateInstagramPost(
            productName: _field1.text.trim(),
            category: _field2.text.trim(),
          );
          break;
        case AiToolType.hashtags:
          result = await ai.generateHashtags(
            topic: _field1.text.trim(),
            category: _field2.text.trim(),
          );
          break;
        case AiToolType.customerReply:
          result = await ai.generateCustomerReply(
            customerMessage: _field1.text.trim(),
          );
          break;
      }

      if (mounted) setState(() { _result = result; });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'حدث خطأ غير متوقع. حاول مجدداً.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _copyResult() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!.output));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم النسخ إلى الحافظة ✅'),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xffF8F9FD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                child: Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.auto_awesome,
                          color: _accentColor, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _sheetTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1A1A1A),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, size: 22.sp, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildInputFields(),
                      SizedBox(height: 20.h),
                      // Generate button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton.icon(
                          onPressed: _canGenerate ? _generate : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            disabledBackgroundColor: _accentColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                          icon: _loading
                              ? SizedBox(
                                  width: 18.w, height: 18.h,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 18.sp),
                          label: Text(
                            _loading ? 'جارٍ التوليد...' : 'توليد بالذكاء الاصطناعي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_result != null) ...[
                        SizedBox(height: 24.h),
                        _ResultCard(result: _result!, accentColor: _accentColor, onCopy: _copyResult),
                      ],
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    switch (widget.tool) {
      case AiToolType.productDescription:
        return [
          _Label('اسم المنتج *'),
          _InputField(_field1, 'مثال: سماعات لاسلكية بلوتوث', _accentColor, () => setState(() {})),
          SizedBox(height: 14.h),
          _Label('الفئة (اختياري)'),
          _InputField(_field2, 'مثال: إلكترونيات', _accentColor, () => setState(() {})),
          SizedBox(height: 14.h),
          _Label('معلومات إضافية (اختياري)'),
          _InputField(_field3, 'مثال: مقاومة للماء، بطارية 24 ساعة', _accentColor, () => setState(() {}), maxLines: 3),
        ];
      case AiToolType.instagramPost:
        return [
          _Label('اسم المنتج / الموضوع *'),
          _InputField(_field1, 'مثال: عطر ليلة الياسمين', _accentColor, () => setState(() {})),
          SizedBox(height: 14.h),
          _Label('الفئة (اختياري)'),
          _InputField(_field2, 'مثال: كوزمتكس', _accentColor, () => setState(() {})),
        ];
      case AiToolType.hashtags:
        return [
          _Label('الموضوع أو المنتج *'),
          _InputField(_field1, 'مثال: ملابس نسائية شتوية', _accentColor, () => setState(() {})),
          SizedBox(height: 14.h),
          _Label('الفئة (اختياري)'),
          _InputField(_field2, 'مثال: أزياء', _accentColor, () => setState(() {})),
        ];
      case AiToolType.customerReply:
        return [
          _Label('رسالة العميل *'),
          _InputField(_field1, 'الصق رسالة العميل هنا...', _accentColor, () => setState(() {}), maxLines: 5),
        ];
    }
  }
}

// ─── Helper sub-widgets ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xff464555),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final Color accentColor;
  final VoidCallback onChanged;
  final int maxLines;

  const _InputField(this.ctrl, this.hint, this.accentColor, this.onChanged,
      {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black38, fontSize: 13.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffE8E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AiResult result;
  final Color accentColor;
  final VoidCallback onCopy;

  const _ResultCard({
    required this.result,
    required this.accentColor,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accentColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'النتيجة',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          Divider(color: accentColor.withValues(alpha: 0.2), height: 20.h),
          Text(
            result.output,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xff333333), height: 1.7),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              icon: Icon(Icons.copy_outlined, color: accentColor, size: 16.sp),
              label: Text(
                'نسخ النص',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
