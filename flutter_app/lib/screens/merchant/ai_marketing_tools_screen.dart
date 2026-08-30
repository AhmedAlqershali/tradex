import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/screens/merchant/merchant_subscription_screen.dart';
import 'package:ai_saas/shared/ai/ai_controller.dart';
import 'package:ai_saas/shared/ai/ai_result_model.dart';
import 'package:flutter/foundation.dart';
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
  final TextEditingController _promptController = TextEditingController();
  AiToolType _selectedTool = AiToolType.productDescription;
  AiResult? _workspaceResult;
  bool _workspaceLoading = false;
  String? _workspaceError;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  SizedBox(height: 24.h),
                  _buildAssistantCard(),
                  if (_workspaceLoading || _workspaceResult != null || _workspaceError != null) ...[
                    SizedBox(height: 16.h),
                    _buildWorkspaceFeedback(),
                  ],
                  SizedBox(height: 28.h),
                  _buildSectionHeading(l10n.aiSmartWorkspaceTitle, l10n.aiSmartWorkspaceSubtitle),
                  SizedBox(height: 12.h),
                  _buildQuickActions(),
                  SizedBox(height: 28.h),
                  _buildSectionHeading(l10n.aiSmartWorkspaceTitle, l10n.aiSmartWorkspaceSubtitle),
                  SizedBox(height: 12.h),
                  _buildContextActions(),
                  SizedBox(height: 28.h),
                  _buildRecentSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xff8B7CFF)],
              ),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 23.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tradex AI', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              SizedBox(height: 2.h),
              Text(l10n.aiSmartWorkspaceSubtitle, style: TextStyle(fontSize: 12.sp, color: AppColors.textGray)),
            ],
          ),
          const Spacer(),
          Icon(Icons.tune_rounded, color: AppColors.textMid, size: 22.sp),
        ],
      ),
    );
  }

  Widget _buildAssistantCard() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff27234F), Color(0xff4D41DF)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20.r, offset: Offset(0, 10.h))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiWhatToDoPrompt, style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 5.h),
            Text(l10n.aiChooseToolPrompt, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.sp)),
            SizedBox(height: 18.h),
            _buildToolSelector(),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
              child: TextField(
                controller: _promptController,
                textDirection: TextDirection.rtl,
                onChanged: (_) => setState(() {}),
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.aiPromptPlaceholder,
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
                  suffixIcon: IconButton(
                    tooltip: l10n.generateResult,
                    onPressed: _workspaceCanGenerate ? _generateInWorkspace : null,
                    icon: _workspaceLoading
                        ? SizedBox(width: 20.w, height: 20.h, child: const CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.arrow_upward_rounded, color: _workspaceCanGenerate ? AppColors.primary : AppColors.textHint, size: 22.sp),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _workspaceCanGenerate ? _generateInWorkspace : null,
                icon: _workspaceLoading ? SizedBox(width: 17.w, height: 17.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_workspaceLoading ? l10n.aiGenerateButtonLoading : l10n.aiGenerateButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSelector() {
    final l10n = AppLocalizations.of(context);
    final tools = [
      (AiToolType.productDescription, l10n.productDescriptionTool, Icons.description_outlined),
      (AiToolType.instagramPost, l10n.marketingContentTool, Icons.campaign_outlined),
      (AiToolType.hashtags, l10n.hashtagsTool, Icons.tag),
      (AiToolType.customerReply, l10n.customerReplyTool, Icons.reply_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: tools.map((item) {
          final selected = _selectedTool == item.$1;
          return Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ChoiceChip(
              selected: selected,
              label: Text(item.$2),
              avatar: Icon(item.$3, size: 16.sp, color: selected ? AppColors.primary : Colors.white70),
              labelStyle: TextStyle(color: selected ? AppColors.primaryDark : Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700),
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.13),
              side: BorderSide(color: selected ? Colors.white : Colors.white24),
              onSelected: (_) => setState(() => _selectedTool = item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool get _workspaceCanGenerate => _promptController.text.trim().isNotEmpty && !_workspaceLoading;

  Future<void> _generateInWorkspace() async {
    if (kDebugMode) debugPrint('[AI_RUNTIME] workspace generate entered');
    if (!_workspaceCanGenerate) return;
    final prompt = _promptController.text.trim();
    setState(() {
      _workspaceLoading = true;
      _workspaceResult = null;
      _workspaceError = null;
    });
    try {
      final ai = AiController.instance;
      late final AiResult result;
      switch (_selectedTool) {
        case AiToolType.productDescription:
          if (kDebugMode) debugPrint('[AI_RUNTIME] controller method entered: generateProductDescription');
          result = await ai.generateProductDescription(name: prompt);
          break;
        case AiToolType.instagramPost:
          if (kDebugMode) debugPrint('[AI_RUNTIME] controller method entered: generateInstagramPost');
          result = await ai.generateInstagramPost(productName: prompt);
          break;
        case AiToolType.hashtags:
          if (kDebugMode) debugPrint('[AI_RUNTIME] controller method entered: generateHashtags');
          result = await ai.generateHashtags(topic: prompt);
          break;
        case AiToolType.customerReply:
          if (kDebugMode) debugPrint('[AI_RUNTIME] controller method entered: generateCustomerReply');
          result = await ai.generateCustomerReply(customerMessage: prompt);
          break;
      }
      if (mounted) setState(() => _workspaceResult = result);
    } catch (error) {
      if (kDebugMode) debugPrint('[AI_RUNTIME] workspace error: ${error.runtimeType}: $error');
      if (mounted) {
        if (AiController.isSubscriptionRequiredError(error)) {
          setState(() => _workspaceError = AiController.subscriptionRequiredMessage);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(AiController.subscriptionRequiredMessage),
                behavior: SnackBarBehavior.floating,
              ),
            );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantSubscriptionScreen(),
            ),
          );
          return;
        }
        setState(() => _workspaceError = _friendlyAiError(error));
      }
    } finally {
      if (mounted) setState(() => _workspaceLoading = false);
    }
  }

  String _friendlyAiError(Object error) {
    final cause = error is AiRuntimeFailure ? error.cause : error;
    if (AiController.isSubscriptionRequiredError(error)) {
      return AiController.subscriptionRequiredMessage;
    }
    final message = cause.toString();
    if (error is AiRuntimeFailure) {
      return '${AppLocalizations.of(context).aiStageLabel}: ${error.stage}\n${AppLocalizations.of(context).error}: $message';
    }
    return '${AppLocalizations.of(context).aiStageLabel}: ${AppLocalizations.of(context).aiStageUnknown}\n${AppLocalizations.of(context).error}: $message';
  }

  Widget _buildWorkspaceFeedback() {
    if (_workspaceLoading) {
      return _feedbackCard(const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())));
    }
    if (_workspaceError != null) {
      return _feedbackCard(Row(children: [Icon(Icons.error_outline, color: AppColors.red, size: 22.sp), SizedBox(width: 10.w), Expanded(child: Text(_workspaceError!, style: TextStyle(color: AppColors.textDark, fontSize: 13.sp, height: 1.4))), IconButton(tooltip: AppLocalizations.of(context).close, onPressed: () => setState(() => _workspaceError = null), icon: const Icon(Icons.close))]));
    }
    final result = _workspaceResult;
    if (result == null) return const SizedBox.shrink();
    return _feedbackCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.auto_awesome, color: AppColors.primary, size: 18.sp), SizedBox(width: 8.w), Expanded(child: Text(result.tool.label, style: TextStyle(color: AppColors.primaryDark, fontSize: 14.sp, fontWeight: FontWeight.w800))), IconButton(tooltip: AppLocalizations.of(context).copy, onPressed: () => _copyWorkspaceResult(result.output), icon: const Icon(Icons.copy_outlined))]),
      const Divider(),
      ConstrainedBox(constraints: BoxConstraints(maxHeight: 260.h), child: SingleChildScrollView(child: SelectableText(result.output, textDirection: TextDirection.rtl, style: TextStyle(color: AppColors.textDark, fontSize: 14.sp, height: 1.65)))),
      SizedBox(height: 8.h),
      Align(alignment: AlignmentDirectional.centerEnd, child: TextButton.icon(onPressed: _generateInWorkspace, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(AppLocalizations.of(context).regenerateResult))),
    ]));
  }

  Widget _feedbackCard(Widget child) => Container(width: double.infinity, padding: EdgeInsets.all(14.r), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppColors.border)), child: child);

  void _copyWorkspaceResult(String output) {
    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).resultCopied)));
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.textDark))),
          Text(subtitle, style: TextStyle(fontSize: 11.sp, color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    final tools = [
      (AiToolType.productDescription, Icons.description_outlined, l10n.productDescriptionTool, AppColors.primary),
      (AiToolType.instagramPost, Icons.camera_alt_outlined, l10n.marketingContentTool, AppColors.orange),
      (AiToolType.hashtags, Icons.tag, l10n.hashtagsTool, AppColors.teal),
      (AiToolType.customerReply, Icons.forum_outlined, l10n.customerReplyTool, AppColors.pink),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: tools.map((item) => _quickAction(item.$1, item.$2, item.$3, item.$4)).toList(),
      ),
    );
  }

  Widget _quickAction(AiToolType tool, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _openTool(tool),
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 60.w) / 2,
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 13.h),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: color, size: 21.sp),
          SizedBox(width: 9.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          Icon(Icons.chevron_left_rounded, color: AppColors.textLight, size: 19.sp),
        ]),
      ),
    );
  }

  Widget _buildContextActions() {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(children: [
          _contextChip(l10n.aiContextPrompt1, Icons.edit_note_rounded, AiToolType.productDescription),
          SizedBox(width: 10.w),
          _contextChip(l10n.aiContextPrompt2, Icons.campaign_outlined, AiToolType.instagramPost),
          SizedBox(width: 10.w),
          _contextChip(l10n.aiContextPrompt3, Icons.reply_rounded, AiToolType.customerReply),
        ]),
      ),
    );
  }

  Widget _contextChip(String label, IconData icon, AiToolType tool) {
    return InkWell(
      onTap: () => _openTool(tool),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14.r)),
        child: Row(children: [Icon(icon, color: AppColors.primary, size: 19.sp), SizedBox(width: 7.w), Text(label, style: TextStyle(color: AppColors.primaryDark, fontSize: 12.sp, fontWeight: FontWeight.w700))]),
      ),
    );
  }

  Widget _buildRecentSection() {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<List<AiResult>>(
      valueListenable: AiController.instance.historyNotifier,
      builder: (context, history, _) {
        final recent = history.take(3).toList();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionHeading(l10n.aiRecentActivity, l10n.aiSavedInSession),
            SizedBox(height: 12.h),
            if (recent.isEmpty)
              Container(width: double.infinity, padding: EdgeInsets.all(18.r), decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppColors.border)), child: Row(children: [Icon(Icons.history_rounded, color: AppColors.textLight, size: 23.sp), SizedBox(width: 12.w), Expanded(child: Text(l10n.aiResultOutputHint, style: TextStyle(color: AppColors.textGray, fontSize: 12.sp, height: 1.5))) ]))
            else
              ...recent.map((result) => Padding(padding: EdgeInsets.only(bottom: 9.h), child: _recentItem(icon: _iconForTool(result.tool), iconColor: _colorForTool(result.tool), title: '${result.tool.label}: ${result.prompt.split(' | ').first}', time: _formatTime(result.generatedAt), onTap: () => setState(() { _selectedTool = result.tool; _workspaceResult = result; _workspaceError = null; })))),
          ]),
        );
      },
    );
  }

  void _openFromPrompt(AiToolType tool) {
    final prompt = _promptController.text.trim();
    _openTool(tool, initialName: prompt);
  }

  void _openTool(AiToolType tool, {String initialName = ''}) {
    _promptController.clear();
    _AiToolSheet.show(context, tool, initialName: initialName);
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
              AppLocalizations.of(context).aiHeroTitle,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context).aiHeroSubtitle,
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
                    AppLocalizations.of(context).startNow,
                    AppColors.white,
                    AppColors.purple,
                  ),
                ),
                SizedBox(width: 12.w),
                _heroButton(
                  AppLocalizations.of(context).watchGuide,
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
            AppLocalizations.of(context).aiAccuracy,
            style: TextStyle(
              color: AppColors.green,
              fontSize: 52.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).aiGeneratedAccuracy,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            AppLocalizations.of(context).aiGeneratedVolume,
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
                  AppLocalizations.of(context).aiOverviewTitle,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: _showHistory,
                  child: Text(
                    AppLocalizations.of(context).aiViewHistory,
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
                      AppLocalizations.of(context).aiNoOperationsAfter,
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
                  ? Center(child: Text(AppLocalizations.of(context).aiNoHistory))
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
    final l10n = AppLocalizations.of(context);

    if (diff.inMinutes < 1) {
      return l10n.now;
    }

    if (diff.inMinutes < 60) {
      return '${l10n.before} ${diff.inMinutes} ${l10n.minutesAgo}';
    }

    if (diff.inHours < 24) {
      return '${l10n.before} ${diff.inHours} ${l10n.hoursAgo}';
    }

    return '${l10n.before} ${diff.inDays} ${l10n.daysAgo}';
  }

  Widget _recentItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
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
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 3.h),
                  Text(time, style: TextStyle(fontSize: 11.sp, color: AppColors.textGray)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_left_rounded, color: AppColors.textLight, size: 20.sp),
          ],
        ),
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
    final l10n = AppLocalizations.of(context);
    switch (widget.tool) {
      case AiToolType.productDescription:
        return l10n.aiGenerateSheetTitleProduct;

      case AiToolType.instagramPost:
        return l10n.aiGenerateSheetTitleInstagram;

      case AiToolType.hashtags:
        return l10n.aiGenerateSheetTitleHashtags;

      case AiToolType.customerReply:
        return l10n.aiGenerateSheetTitleCustomerReply;
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
    final cause = error is AiRuntimeFailure ? error.cause : error;
    final message = cause.toString();
    if (error is AiRuntimeFailure) {
      return '${AppLocalizations.of(context).aiStageLabel}: ${error.stage}\n${AppLocalizations.of(context).error}: $message';
    }
    return '${AppLocalizations.of(context).aiStageLabel}: ${AppLocalizations.of(context).aiStageUnknown}\n${AppLocalizations.of(context).error}: $message';
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
        content: Text(
          AppLocalizations.of(context).aiCopiedToClipboard,
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
                                  ? AppLocalizations.of(context).aiGenerateButtonLoading
                                  : AppLocalizations.of(context).generateAiText,
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
          _label(AppLocalizations.of(context).productNameLabel),
          _inputField(
            _field1,
            AppLocalizations.of(context).exampleWirelessHeadphones,
          ),
          SizedBox(height: 14.h),
          _label(AppLocalizations.of(context).optionalCategory),
          _inputField(
            _field2,
            AppLocalizations.of(context).categoryExample,
          ),
          SizedBox(height: 14.h),
          _label(AppLocalizations.of(context).optionalDetails),
          _inputField(
            _field3,
            AppLocalizations.of(context).productDescriptionExample,
            maxLines: 3,
          ),
        ];

      case AiToolType.instagramPost:
        return [
          _label(AppLocalizations.of(context).productOrTopic),
          _inputField(
            _field1,
            AppLocalizations.of(context).examplePerfume,
          ),
          SizedBox(height: 14.h),
          _label(AppLocalizations.of(context).optionalCategory),
          _inputField(
            _field2,
            AppLocalizations.of(context).exampleCosmetics,
          ),
        ];

      case AiToolType.hashtags:
        return [
          _label(AppLocalizations.of(context).productOrTopic),
          _inputField(
            _field1,
            AppLocalizations.of(context).exampleWinterFashion,
          ),
          SizedBox(height: 14.h),
          _label(AppLocalizations.of(context).optionalCategory),
          _inputField(
            _field2,
            AppLocalizations.of(context).categoryExample,
          ),
        ];

      case AiToolType.customerReply:
        return [
          _label(AppLocalizations.of(context).customerMessageLabel),
          _inputField(
            _field1,
            AppLocalizations.of(context).exampleCustomerMessage,
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
                AppLocalizations.of(context).resultText,
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
                AppLocalizations.of(context).copyText,
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
