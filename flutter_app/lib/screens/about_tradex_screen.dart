import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutTradexScreen extends StatelessWidget {
  const AboutTradexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Directionality(
      textDirection: l10n.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(l10n.aboutTradex),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20.w,
              16.h,
              20.w,
              28.h + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(l10n),
                SizedBox(height: 28.h),
                _buildSectionTitle(l10n.aboutOffers),
                SizedBox(height: 12.h),
                _buildFeatureCard(
                  icon: Icons.shopping_bag_outlined,
                  title: l10n.aboutForShoppers,
                  description: l10n.aboutForShoppersDescription,
                ),
                SizedBox(height: 10.h),
                _buildFeatureCard(
                  icon: Icons.storefront_outlined,
                  title: l10n.aboutForMerchants,
                  description: l10n.aboutForMerchantsDescription,
                ),
                SizedBox(height: 10.h),
                _buildFeatureCard(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.aboutAiTools,
                  description: l10n.aboutAiToolsDescription,
                ),
                SizedBox(height: 10.h),
                _buildFeatureCard(
                  icon: Icons.local_shipping_outlined,
                  title: l10n.aboutCompleteExperience,
                  description: l10n.aboutCompleteExperienceDescription,
                ),
                SizedBox(height: 28.h),
                _buildSectionTitle(l10n.aboutHowItWorks),
                SizedBox(height: 12.h),
                _buildFlowCard(
                  title: l10n.aboutShopperFlow,
                  steps: [
                    (Icons.explore_outlined, l10n.aboutDiscover),
                    (Icons.checkroom_outlined, l10n.aboutChoose),
                    (Icons.shopping_cart_outlined, l10n.aboutOrder),
                    (Icons.track_changes_outlined, l10n.aboutTrack),
                  ],
                  isArabic: l10n.isArabic,
                ),
                SizedBox(height: 10.h),
                _buildFlowCard(
                  title: l10n.aboutMerchantFlow,
                  steps: [
                    (Icons.add_business_outlined, l10n.aboutCreateStore),
                    (Icons.inventory_2_outlined, l10n.aboutAddProducts),
                    (Icons.receipt_long_outlined, l10n.aboutManageOrders),
                    (Icons.forum_outlined, l10n.aboutReachCustomers),
                  ],
                  isArabic: l10n.isArabic,
                ),
                SizedBox(height: 28.h),
                _buildSectionTitle(l10n.aboutPurpose),
                SizedBox(height: 12.h),
                _buildPurposeCard(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 22.h),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.flash_on, size: 38.sp, color: Colors.white),
          ),
          SizedBox(height: 16.h),
          Text(
            'Tradex',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.aboutHeroDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14.sp,
              height: 1.55,
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  description,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.sp,
                    height: 1.45,
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

  Widget _buildFlowCard({
    required String title,
    required List<(IconData, String)> steps,
    required bool isArabic,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              title,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: _buildFlowStep(
                    icon: steps[index].$1,
                    label: steps[index].$2,
                  ),
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Icon(
                      isArabic
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 15.sp,
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19.sp, color: AppColors.primary),
        ),
        SizedBox(height: 7.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 11.sp,
            height: 1.25,
            color: AppColors.textMid,
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        l10n.aboutPurposeDescription,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 14.sp,
          height: 1.65,
          color: AppColors.textMid,
        ),
      ),
    );
  }
}
