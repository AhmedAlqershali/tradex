import 'package:ai_saas/screens/auth/complete_profile_photo_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── CompleteProfileClientScreen ─────────────────────────────────────────────
//
// Region-selection step in the client onboarding flow.
//
// Fixes over the original:
//   - All sizes now use ScreenUtil (.sp / .h / .w / .r)
//   - Font standardised to IBM Plex Sans everywhere
//   - Primary color corrected to 0xff4D41DF (was 0xFF5342E6)
//   - Custom selection rows replace RadioListTile (better RTL alignment)
// ─────────────────────────────────────────────────────────────────────────────

class CompleteProfileClientScreen extends StatefulWidget {
  const CompleteProfileClientScreen({super.key});

  @override
  State<CompleteProfileClientScreen> createState() =>
      _CompleteProfileClientScreenState();
}

class _CompleteProfileClientScreenState
    extends State<CompleteProfileClientScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);

  String? _selectedRegion = UserController.instance.currentUser?.region;
  bool _isLocating = false;

  final List<Map<String, dynamic>> _regions = [
    {'name': 'غزة', 'icon': Icons.location_on_outlined},
    {'name': 'شمال غزة', 'icon': Icons.map_outlined},
    {'name': 'الوسطى', 'icon': Icons.map_outlined},
    {'name': 'خانيونس', 'icon': Icons.explore_outlined},
    {'name': 'رفح', 'icon': Icons.navigation_outlined},
    {'name': 'دير البلح', 'icon': Icons.location_on_outlined},
  ];

  Future<void> _onNext() async {
    if (_selectedRegion == null || _selectedRegion!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر منطقتك أولاً.')),
      );
      return;
    }
    await UserController.instance.updateProfile(region: _selectedRegion);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompleteProfilePhotoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'إكمال الملف للمتسوق',
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xff888888),
              fontSize: 14.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable content ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),

                      // Heading
                      Text(
                        'حدد منطقتك',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1A1A1A),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'اختر المنطقة التي تتواجد بها لتخصيص تجربتك.',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13.sp,
                          color: const Color(0xff707070),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Search field
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xffEFEFEF)),
                        ),
                        child: TextField(
                          textAlign: TextAlign.right,
                          style: GoogleFonts.ibmPlexSans(fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منطقتك...',
                            hintStyle: GoogleFonts.ibmPlexSans(
                              color: const Color(0xff888888),
                              fontSize: 13.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: const Color(0xff888888),
                              size: 20.sp,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Use current location button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: _isLocating
                              ? SizedBox(
                                  width: 18.sp,
                                  height: 18.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.my_location,
                                  size: 18.sp, color: _primary),
                          label: Text(
                            'استخدام موقعي الحالي',
                            style: GoogleFonts.ibmPlexSans(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _primary.withValues(alpha: 0.05),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Region selection list
                      ...List.generate(_regions.length, (index) {
                        final region = _regions[index];
                        final name = region['name'] as String;
                        final icon = region['icon'] as IconData;
                        final selected = _selectedRegion == name;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedRegion = name),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: selected
                                    ? _primary
                                    : const Color(0xffEFEFEF),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio indicator
                                Container(
                                  width: 20.w,
                                  height: 20.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? _primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? _primary
                                          : const Color(0xffCCCCCC),
                                      width: selected ? 5 : 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),

                                // Region name
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 15.sp,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: const Color(0xff1A1A1A),
                                    ),
                                  ),
                                ),

                                // Icon badge
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _primary.withValues(alpha: 0.08)
                                        : const Color(0xffF5F5F5),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: selected
                                        ? _primary
                                        : const Color(0xff888888),
                                    size: 18.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),

              // ── Fixed bottom CTA ────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xffEFEFEF)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'التالي',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 18.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      if (result.region == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'تعذر مطابقة موقعك مع منطقة متاحة. اختر المنطقة يدوياً.')),
        );
        return;
      }
      setState(() => _selectedRegion = result.region);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديد الموقع: ${result.region}')),
      );
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على موقعك الحالي.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }
}
