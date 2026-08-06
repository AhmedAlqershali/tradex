import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── CategoriesScreen ─────────────────────────────────────────────────────────
//
// Previously used a hardcoded Arabic category list (lib/models/item_category.dart)
// that never matched the backend's real category names (English strings like
// "Electronics", "Fashion & Clothing"). Tapping a tile silently filtered by a
// name the backend couldn't resolve, so the tap effectively did nothing.
//
// Now loads real categories via CategoryBloc (GET /categories) and maps each
// name to a representative icon, with a generic fallback for anything unmapped.
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryListRequested());
  }

  /// Best-effort icon for a backend category name. Matches on keywords so it
  /// keeps working if the backend's category list changes/grows; falls back
  /// to a generic category icon otherwise.
  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('electronic') || n.contains('device')) return Icons.devices;
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom;
    if (n.contains('shoe')) return Icons.hiking;
    if (n.contains('home') || n.contains('kitchen')) return Icons.kitchen_outlined;
    if (n.contains('food') || n.contains('grocer')) return Icons.restaurant;
    if (n.contains('beauty') || n.contains('cosmetic') || n.contains('personal care')) {
      return Icons.brush;
    }
    if (n.contains('sport') || n.contains('outdoor')) return Icons.sports_soccer;
    if (n.contains('toy') || n.contains('game')) return Icons.toys_outlined;
    if (n.contains('book') || n.contains('stationery')) return Icons.menu_book_outlined;
    if (n.contains('health') || n.contains('wellness')) return Icons.favorite_border;
    if (n.contains('auto') || n.contains('car')) return Icons.directions_car_outlined;
    if (n.contains('jewel') || n.contains('accessor')) return Icons.diamond_outlined;
    if (n.contains('baby') || n.contains('kid')) return Icons.child_friendly_outlined;
    if (n.contains('office') || n.contains('work')) return Icons.laptop;
    if (n.contains('service')) return Icons.shopping_bag_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        actionsPadding: EdgeInsets.only(right: 20.w),
        title: Text(
          'Tradex',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff4D41DF),
          ),
        ),
        centerTitle: true,
        leading: Icon(
          Icons.shopping_bag_outlined,
          color: const Color(0xff4D41DF),
          size: 25.sp,
        ),
        actions: [
          Icon(
            Icons.location_on_outlined,
            color: const Color(0xff4D41DF),
            size: 25.sp,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                width: double.infinity,
                child: Text(
                  'التصنيفات ',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                width: double.infinity,
                child: Text(
                  'تصفح أفضل المتاجر والخدمات في منطقتك ',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 18.sp,
                    color: const Color(0xff464555),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading || state is CategoryInitial) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is CategoryFailure) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                      child: Column(
                        children: [
                          Text(
                            'تعذر تحميل التصنيفات',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14.sp,
                              color: const Color(0xff707070),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          TextButton(
                            onPressed: () => context
                                .read<CategoryBloc>()
                                .add(const CategoryListRequested()),
                            child: Text(
                              'إعادة المحاولة',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13.sp,
                                color: const Color(0xff4D41DF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final names =
                      state is CategoriesLoaded ? state.categories : const <String>[];

                  if (names.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: Text(
                        'لا توجد تصنيفات متاحة حالياً',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: const Color(0xff707070),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.all(8.r),
                    itemCount: names.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20.w,
                      mainAxisSpacing: 20.h,
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) {
                      final name = names[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8.r,
                              offset: Offset(0, 5.h),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(initialCategory: name),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 15.h),
                              Container(
                                padding: EdgeInsets.all(15.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDE7F6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconFor(name),
                                  size: 30.sp,
                                  color: const Color(0xFF5E35B1),
                                ),
                              ),
                              SizedBox(height: 15.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: 342.w,
                height: 193.h,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/shoes.png',
                      width: 342.w,
                      height: 193.h,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 100.h,
                      right: 10.w,
                      child: Container(
                        width: 45.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: const Color(0xff4D41DF),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Text(
                            'متميز',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50.h,
                      right: 10.w,
                      child: Text(
                        'أفضل عروض المولات',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30.h,
                      right: 10.w,
                      child: Text(
                        'استكشف خصومات تصل إلى ٥٠٪',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
