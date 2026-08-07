import 'package:ai_saas/screens/auth/register_screen.dart';
import 'package:ai_saas/screens/auth/login_screen.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class UserSelection extends StatefulWidget {
  const UserSelection({super.key});

  @override
  State<UserSelection> createState() => _UserSelectionState();
}

class _UserSelectionState extends State<UserSelection> {
  AppType _selectedType = AppType.client;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5342E6);
    const Color backgroundColor = Color(0xFFF9FAFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        // LayoutBuilder يعطينا مقاسات الشاشة المتاحة
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                // لضمان أن العناصر تأخذ كامل ارتفاع الشاشة على الأقل
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),

                      // العنوان الرئيسي
                      Text(
                        'مرحباً بك في Tradex',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 26.sp, // تقليل بسيط ليناسب الشاشات الصغيرة
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'اختر نوع الحساب للمتابعة',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      SizedBox(height: 30.h),

                      // كارت متسوق
                      _buildSelectionCard(
                        title: 'متسوق',
                        description:
                            'ابحث عن المنتجات، قارن الأسعار، وتسوق بسهولة ذكية.',
                        imagePath: 'assets/images/client.png',
                        type: AppType.client,
                        isSelected: _selectedType == AppType.client,
                        primaryColor: primaryColor,
                      ),

                      // كارت تاجر
                      _buildSelectionCard(
                        title: 'تاجر',
                        description:
                            'قم ببيع منتجاتك، تتبع أرباحك، ووسع تجارتك باستخدام الذكاء الاصطناعي.',
                        imagePath: 'assets/images/merchant.png',
                        type: AppType.merchant,
                        isSelected: _selectedType == AppType.merchant,
                        primaryColor: primaryColor,
                      ),

                      // هذا الـ Spacer سيعمل الآن بشكل صحيح بفضل IntrinsicHeight
                      const Spacer(),

                      // الجزء السفلي: الزر ونصوص الشروط
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 24.h),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RegisterScreen(type: _selectedType),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: Size(double.infinity, 56.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'متابعة',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'بالنقر على متابعة، فإنك توافق على شروط الخدمة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginScreen(type: AppType.admin),
                                ),
                              ),
                              child: Text(
                                'دخول الإدارة',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ويجت مخصص لبناء الكروت لضمان التناسق وسهولة التعديل
  Widget _buildSelectionCard({
    required String title,
    required String description,
    required String imagePath,
    required AppType type,
    required bool isSelected,
    required Color primaryColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // إزالة الارتفاع الثابت ليكون مرناً مع المحتوى
          constraints: BoxConstraints(minHeight: 120.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r), // زوايا أنعم
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              // تحسين عرض الصورة
              SizedBox(
                width: 70.w,
                height: 70.w,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  // التعامل مع حالة عدم وجود الصورة لتجنب كراش التطبيق
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
