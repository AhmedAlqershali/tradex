import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/shared/ai/ai_controller.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── AI Marketing Tools Screen ────────────────────────────────────────────────

class AlMarketingToolsScreen extends StatefulWidget {
  const AlMarketingToolsScreen({super.key});

  @override
  State<AlMarketingToolsScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<AlMarketingToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 20.h),
          child: Column(
            children: [
              _buildTopBar(),
              _buildHeroBanner(),
              SizedBox(height: 24.h),
              _buildToolCard(
                tag: 'الأكثر استخداماً',
                icon: Icons.description_outlined,
                iconColor: AppColors.purple,
                title: 'كتابة وصف منتج',
                subtitle:
                    'حوّل مواصفات منتجك إلى نصوص بيعية جذابة تقنع العميل بالشراء فوراً.',
                buttonText: 'ابدأ الوصف ←',
                buttonColor: AppColors.purple,
                tool: AiToolType.productDescription,
              ),
              _buildToolCard(
                icon: Icons.camera_alt_outlined,
                iconColor: AppColors.orange,
                title: 'إنشاء بوست انستغرام',
                subtitle:
                    'احصل على أفكار لمحتوى الصور والتعليقات المناسبة لكل منصة اجتماعية.',
                buttonText: 'صمم المنشور ←',
                buttonColor: AppColors.orange,
                tool: AiToolType.instagramPost,
              ),
              _buildToolCard(
                icon: Icons.tag,
                iconColor: AppColors.teal,
                title: 'توليد هاشتاقات',
                subtitle:
                    'ارفع نسبة الوصول لمنشوراتك باستخدام هاشتاقات ذكية ومخصصة.',
                buttonText: 'توليد الآن',
                buttonColor: AppColors.teal,
                tool: AiToolType.hashtags,
              ),
              _buildToolCard(
                icon: Icons.chat_bubble_outline,
                iconColor: AppColors.pink,
                title: 'كتابة ردود للعملاء',
                subtitle:
                    'ردود سريعة واحترافية على استفسارات العملاء وشكاواهم بكل لباقة.',
                buttonText: 'رد ذكي',
                buttonColor: AppColors.pink,
                tool: AiToolType.customerReply,
              ),
              SizedBox(height: 16.h),
              _buildAccuracyCard(),
              SizedBox(height: 24.h),
              _buildRecentOperations(),
            ],
          ),
        ),
      ),
    );
  }

// ── TOP BAR ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38.w,
            height: 38.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.purple,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Tradex AI',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              Icon(
                Icons.notifications_none,
                size: 26.sp,
                color: AppColors.textDark,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          Icon(
            Icons.menu,
            size: 26.sp,
            color: AppColors.textDark,
          ),
        ],
      ),
    );
  }

// ── HERO BANNER ──────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7B6FFF),
              Color(0xFF5A4FDF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مساعدك الذكي\nلإدارة متجرك\nباحترافية',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'استخدم أدوات الذكاء الاصطناعي لتوفير وزيادة مبيعاتك بضغطة زر واحدة.',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _AiToolSheet.show(
                    context,
                    AiToolType.productDescription,
                  ),
                  child: _heroButton(
                    'ابدأ الآن',
                    AppColors.white,
                    AppColors.purple,
                  ),
                ),
                SizedBox(width: 12.w),
                _heroButton(
                  'شاهد الشرح',
                  Colors.transparent,
                  AppColors.white,
                  isOutlined: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroButton(
    String text,
    Color bg,
    Color textColor, {
    bool isOutlined = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 22.w,
        vertical: 11.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: isOutlined
            ? Border.all(
                color: AppColors.white,
                width: 1.5.w,
              )
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

// ── TOOL CARD ─────────────────────────────────────────────────────────────────

  Widget _buildToolCard({
    String? tag,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required AiToolType tool,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 8.h,
        ),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22.sp,
                  ),
                ),
                if (tag != null) ...[
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => _AiToolSheet.show(
                context,
                tool,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 11.h,
                ),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: buttonColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ── ACCURACY CARD ─────────────────────────────────────────────────────────────

  Widget _buildAccuracyCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(
        vertical: 32.h,
        horizontal: 20.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Text(
            '98%',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 52.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'دقة المحتوى المولّد بواسطة AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'بناءً على أكثر من 10,000 محتوى تم إنشاؤه',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.45),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

// ── RECENT OPERATIONS ─────────────────────────────────────────────────────────

  Widget _buildRecentOperations() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر العمليات',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: _showHistory,
                  child: Text(
                    'عرض السجل',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ValueListenableBuilder<List<AiResult>>(
              valueListenable: AiController.instance.historyNotifier,
              builder: (context, history, _) {
                if (history.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      'لا توجد عمليات بعد. استخدم إحدى أدوات الذكاء الاصطناعي لبدء التوليد.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGray,
                      ),
                    ),
                  );
                }

                return Column(
                  children: history.take(5).map((result) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _recentItem(
                        icon: _iconForTool(result.tool),
                        iconColor: _colorForTool(result.tool),
                        title:
                            '${result.tool.label}: ${result.prompt.split(' | ').first}',
                        time: _formatTime(result.generatedAt),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    final history = AiController.instance.historyNotifier.value;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.75,
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: history.isEmpty
                  ? const Center(child: Text('لا توجد عمليات محفوظة بعد.'))
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final item = history[index];
                        return ListTile(
                          leading: Icon(_iconForTool(item.tool)),
                          title: Text(item.tool.label),
                          subtitle: Text(
                            item.output,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForTool(AiToolType tool) {
    switch (tool) {
      case AiToolType.productDescription:
        return Icons.description_outlined;

      case AiToolType.instagramPost:
        return Icons.camera_alt_outlined;

      case AiToolType.hashtags:
        return Icons.tag;

      case AiToolType.customerReply:
        return Icons.chat_bubble_outline;
    }
  }

  Color _colorForTool(AiToolType tool) {
    switch (tool) {
      case AiToolType.productDescription:
        return AppColors.purple;

      case AiToolType.instagramPost:
        return AppColors.orange;

      case AiToolType.hashtags:
        return AppColors.teal;

      case AiToolType.customerReply:
        return AppColors.pink;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) {
      return 'الآن';
    }

    if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes} دقيقة';
    }

    if (diff.inHours < 24) {
      return 'قبل ${diff.inHours} ساعة';
    }

    return 'قبل ${diff.inDays} يوم';
  }

  Widget _recentItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Tool Bottom Sheet ─────────────────────────────────────────────────────

class _AiToolSheet extends StatefulWidget {
  final AiToolType tool;

  final String initialName;
  final String initialCategory;

  const _AiToolSheet({
    required this.tool,
    this.initialName = '',
    this.initialCategory = '',
  });

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
      useSafeArea: true,
      builder: (_) {
        return _AiToolSheet(
          tool: tool,
          initialName: initialName,
          initialCategory: initialCategory,
        );
      },
    );
  }

  @override
  State<_AiToolSheet> createState() => _AiToolSheetState();
}

class _AiToolSheetState extends State<_AiToolSheet> {
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

  Color get _accentColor {
    switch (widget.tool) {
      case AiToolType.productDescription:
        return AppColors.purple;

      case AiToolType.instagramPost:
        return AppColors.orange;

      case AiToolType.hashtags:
        return AppColors.teal;

      case AiToolType.customerReply:
        return AppColors.pink;
    }
  }

  String get _sheetTitle {
    switch (widget.tool) {
      case AiToolType.productDescription:
        return 'كتابة وصف منتج';

      case AiToolType.instagramPost:
        return 'إنشاء بوست انستغرام';

      case AiToolType.hashtags:
        return 'توليد هاشتاقات';

      case AiToolType.customerReply:
        return 'كتابة رد للعميل';
    }
  }

// ── AI GENERATION ────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (!_canGenerate) return;

    final ai = AiController.instance;

    setState(() {
      _loading = true;
      _result = null;
    });

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

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;

      final message = _friendlyAiError(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

// ── FRIENDLY ERROR ───────────────────────────────────────────────────────────

  String _friendlyAiError(Object error) {
    final message = error.toString();

    if (message.contains('Gemini API key is not configured')) {
      return 'خدمة الذكاء الاصطناعي غير مهيأة حالياً على الخادم.';
    }

    if (message.contains('GEMINI_API_KEY')) {
      return 'مفتاح Gemini غير مهيأ على الخادم.';
    }

    if (message.contains('503')) {
      return 'خدمة الذكاء الاصطناعي غير متاحة حالياً. حاول مرة أخرى.';
    }

    if (message.contains('401')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مرة أخرى.';
    }

    if (error is ForbiddenException || message.contains('403')) {
      if (message.contains('active trial or paid subscription')) {
        return 'لاستخدام أدوات الذكاء الاصطناعي، فعّل التجربة المجانية أو اشترك في خطة مدفوعة.';
      }
      return 'ليس لديك صلاحية لاستخدام هذه الخدمة.';
    }

    if (message.contains('404')) {
      return 'خدمة الذكاء الاصطناعي غير موجودة على الخادم.';
    }

    if (message.contains('429')) {
      return 'تم تجاوز الحد المسموح لطلبات الذكاء الاصطناعي. حاول لاحقاً.';
    }

    if (message.contains('500')) {
      return 'حدث خطأ داخلي في الخادم. حاول مرة أخرى.';
    }

    if (message.contains('SocketException')) {
      return 'تعذر الاتصال بالخادم. تأكد من اتصال الإنترنت.';
    }

    if (message.contains('TimeoutException') ||
        message.contains('timeout') ||
        message.contains('Timeout')) {
      return 'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.';
    }

    return 'حدث خطأ أثناء توليد المحتوى. حاول مرة أخرى.';
  }

  bool get _canGenerate {
    return _field1.text.trim().isNotEmpty && !_loading;
  }

// ── COPY RESULT ──────────────────────────────────────────────────────────────

  void _copyResult() {
    if (_result == null) return;

    Clipboard.setData(
      ClipboardData(
        text: _result!.output,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم النسخ إلى الحافظة ✅',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 12.h,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

// ── BUILD BOTTOM SHEET ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xffF8F9FD),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24.r),
              ),
            ),
            child: Column(
              children: [
// Drag handle
                Padding(
                  padding: EdgeInsets.only(
                    top: 12.h,
                    bottom: 4.h,
                  ),
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

// Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: _accentColor,
                          size: 20.sp,
                        ),
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
                        child: Icon(
                          Icons.close,
                          size: 22.sp,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

// Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20.r,
                      20.r,
                      20.r,
                      40.r,
                    ),
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
                              disabledBackgroundColor:
                                  _accentColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            icon: _loading
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                            label: Text(
                              _loading
                                  ? 'جارٍ التوليد...'
                                  : 'توليد بالذكاء الاصطناعي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

// Result
                        if (_result != null) ...[
                          SizedBox(height: 24.h),
                          _buildResultCard(),
                        ],

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// ── INPUT FIELDS ─────────────────────────────────────────────────────────────

  List<Widget> _buildInputFields() {
    switch (widget.tool) {
      case AiToolType.productDescription:
        return [
          _label('اسم المنتج *'),
          _inputField(
            _field1,
            'مثال: سماعات لاسلكية بلوتوث',
          ),
          SizedBox(height: 14.h),
          _label('الفئة (اختياري)'),
          _inputField(
            _field2,
            'مثال: إلكترونيات',
          ),
          SizedBox(height: 14.h),
          _label('معلومات إضافية (اختياري)'),
          _inputField(
            _field3,
            'مثال: مقاومة للماء، بطارية 24 ساعة',
            maxLines: 3,
          ),
        ];

      case AiToolType.instagramPost:
        return [
          _label('اسم المنتج / الموضوع *'),
          _inputField(
            _field1,
            'مثال: عطر ليلة الياسمين',
          ),
          SizedBox(height: 14.h),
          _label('الفئة (اختياري)'),
          _inputField(
            _field2,
            'مثال: كوزمتكس',
          ),
        ];

      case AiToolType.hashtags:
        return [
          _label('الموضوع أو المنتج *'),
          _inputField(
            _field1,
            'مثال: ملابس نسائية شتوية',
          ),
          SizedBox(height: 14.h),
          _label('الفئة (اختياري)'),
          _inputField(
            _field2,
            'مثال: أزياء',
          ),
        ];

      case AiToolType.customerReply:
        return [
          _label('رسالة العميل *'),
          _inputField(
            _field1,
            'الصق رسالة العميل هنا...',
            maxLines: 5,
          ),
        ];
    }
  }

// ── LABEL ────────────────────────────────────────────────────────────────────

  Widget _label(String text) {
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

// ── INPUT ────────────────────────────────────────────────────────────────────

  Widget _inputField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      onChanged: (_) {
        if (mounted) {
          setState(() {});
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.black38,
          fontSize: 13.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: Color(0xffE0E0E0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: Color(0xffE8E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: _accentColor,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
      ),
    );
  }

// ── RESULT CARD ──────────────────────────────────────────────────────────────

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.06),
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
              Icon(
                Icons.auto_awesome,
                color: _accentColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'النتيجة',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          Divider(
            color: _accentColor.withValues(alpha: 0.2),
            height: 20.h,
          ),
          SelectableText(
            _result!.output,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xff333333),
              height: 1.7,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton.icon(
              onPressed: _copyResult,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _accentColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: Icon(
                Icons.copy_outlined,
                color: _accentColor,
                size: 16.sp,
              ),
              label: Text(
                'نسخ النص',
                style: TextStyle(
                  color: _accentColor,
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
