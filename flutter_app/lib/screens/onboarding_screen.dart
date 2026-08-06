import 'package:ai_saas/screens/user_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingAIPage extends StatelessWidget {
  const OnboardingAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xff4D41DF);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ─── الجزء العلوي: النصوص ───
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20.h),
                            _buildAITag(primaryColor),
                            SizedBox(height: 16.h),
                            _buildMainHeading(primaryColor),
                            SizedBox(height: 10.h),
                            Text(
                              'حوّل أفكارك إلى حملات تسويقية احترافية في ثوانٍ معدودة. دع مساعدنا الذكي يتولى كتابة المحتوى وتصميم العروض.',
                              style: GoogleFonts.ibmPlexSans(
                                color: const Color(0xff707070),
                                fontSize: 14.sp,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),

                        // ─── الجزء الأوسط: الـ Stack المحمي ───
                        // تم تغليف الـ Stack بحاوية مرنة لضمان عدم حدوث Overflow
                        Container(
                          height: 300.h,
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(vertical: 20.h),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // الصورة المركزية (المنتج)
                              _buildCentralImage(),

                              // بطاقة "وصف مقترح" (أعلى اليمين)
                              Positioned(
                                top: 5.h,
                                right: -10.w,
                                child: _buildSuggestedDescriptionCard(),
                              ),

                              // أيقونة المشاركة (منتصف اليمين)
                              Positioned(
                                bottom: 80.h,
                                right: 5.w,
                                child: _buildShareBadge(),
                              ),

                              // بطاقة "تحليل البيانات" (أسفل اليسار)
                              Positioned(
                                bottom: 10.h,
                                left: -5.w,
                                child: _buildFloatingBadge(
                                  icon: Icons.psychology_rounded,
                                  label: 'تحليل البيانات',
                                  color: primaryColor,
                                ),
                              ),

                              // بطاقة "الزيادة المتوقعة" (منتصف اليسار)
                              Positioned(
                                top: 120.h,
                                left: -10.w,
                                child: _buildStatBadge(),
                              ),
                            ],
                          ),
                        ),

                        // ─── الجزء السفلي: الأزرار ───
                        Column(
                          children: [
                            _buildPageIndicator(primaryColor),
                            SizedBox(height: 24.h),
                            _buildMainButton(context, primaryColor),
                            SizedBox(height: 8.h),
                            _buildSkipButton(context),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- مكونات الواجهة الصغيرة ---

  Widget _buildAITag(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            'الذكاء الاصطناعي',
            style: GoogleFonts.ibmPlexSans(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeading(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سوّق باستخدام',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1A1A1A),
            height: 1.1,
          ),
        ),
        Text(
          'الذكاء الاصطناعي',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildCentralImage() {
    return Container(
      width: 200.w,
      height: 150.h,
      decoration: BoxDecoration(
        color: const Color(0xff4D41DF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/shoes.png',
          width: 160.w,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.shopping_bag_outlined, size: 50.sp, color: Colors.grey.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(false, color),
        SizedBox(width: 6.w),
        _buildDot(true, color),
        SizedBox(width: 6.w),
        _buildDot(false, color),
      ],
    );
  }

  Widget _buildDot(bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6.h,
      width: isActive ? 24.w : 6.w,
      decoration: BoxDecoration(
        color: isActive ? color : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSelection())),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: Text(
          'التالي',
          style: GoogleFonts.ibmPlexSans(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSelection())),
      child: Text(
        'تخطي للمرحلة النهائية',
        style: GoogleFonts.ibmPlexSans(color: const Color(0xff707070), fontSize: 14.sp),
      ),
    );
  }

  // --- البطاقات العائمة ---

  Widget _buildSuggestedDescriptionCard() {
    return Container(
      width: 160.w,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 3, backgroundColor: Color(0xff14db66)),
              SizedBox(width: 6.w),
              Text('وصف مقترح', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4.h),
          Text("اكتشف الأناقة العصرية مع تصاميمنا الجديدة.", style: TextStyle(fontSize: 10.sp, color: Colors.grey, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildStatBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFDCD0)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: const Color(0xFFE65100), size: 16.sp),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('زيادة متوقعة', style: TextStyle(fontSize: 8.sp, color: const Color(0xFFE65100))),
              Text('+240%', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 6.w),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShareBadge() {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: const BoxDecoration(color: Color(0xffe0fbf6), shape: BoxShape.circle),
      child: Icon(Icons.share_rounded, color: const Color(0xff00bfa5), size: 16.sp),
    );
  }
}