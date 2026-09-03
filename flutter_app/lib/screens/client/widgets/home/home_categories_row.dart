import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/core/services/category_service.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── HomeCategoriesRow ────────────────────────────────────────────────────────
//
// Horizontal row of category icon buttons on the shopper home page.
// ─────────────────────────────────────────────────────────────────────────────

class HomeCategoriesRow extends StatelessWidget {
  const HomeCategoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading || state is CategoryInitial) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is CategoryFailure) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).categoryLoadError,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.sp, color: const Color(0xff888888)),
                  ),
                ),
                TextButton(
                  onPressed: () => context
                      .read<CategoryBloc>()
                      .add(const CategoryListRequested()),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          );
        }

        final options = state is CategoriesLoaded
            ? state.options
            : const <CategoryOption>[];
        if (options.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 112.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => SizedBox(width: 14.w),
            itemBuilder: (context, index) {
              final category = options[index];
              return _CategoryItem(
                icon: _iconFor(category.name),
                label: category.localizedName(
                  isArabic: AppLocalizations.of(context).isArabic,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      initialCategory: category.name,
                      initialCategoryId: category.id,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconFor(String name) {
    final value = name.toLowerCase();
    if (value.contains('electronic') || value.contains('device')) {
      return Icons.devices_other_rounded;
    }
    if (value.contains('fashion') || value.contains('cloth')) {
      return Icons.checkroom_rounded;
    }
    if (value.contains('shoe')) return Icons.ice_skating_rounded;
    if (value.contains('food') || value.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('beauty') || value.contains('cosmetic')) {
      return Icons.face_retouching_natural_rounded;
    }
    return Icons.category_rounded;
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  static const Color _primary = Color(0xff4D41DF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65.w,
            height: 65.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
              ],
            ),
            child: Icon(icon, color: _primary, size: 26.sp),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: 70.w,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
