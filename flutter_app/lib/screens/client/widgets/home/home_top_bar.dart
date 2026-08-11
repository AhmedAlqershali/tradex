import 'package:ai_saas/screens/client/cart_screen.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:ai_saas/screens/notifications_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── HomeTopBar ───────────────────────────────────────────────────────────────
//
// Top bar of the shopper home: avatar, notifications, cart, location, menu.
// ─────────────────────────────────────────────────────────────────────────────

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    this.locationName,
    this.isLocationLoading = false,
    this.locationError,
    this.onLocationRetry,
  });

  static const Color _primary = Color(0xff4D41DF);
  final String? locationName;
  final bool isLocationLoading;
  final String? locationError;
  final VoidCallback? onLocationRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          ValueListenableBuilder(
            valueListenable: UserController.instance.currentUserNotifier,
            builder: (context, user, _) {
              final avatar = user?.photoPath;
              return CircleAvatar(
                radius: 22.r,
                backgroundColor: _primary.withValues(alpha: 0.1),
                child: avatar == null || avatar.isEmpty
                    ? Icon(Icons.person_outline_rounded,
                        color: _primary, size: 22.sp)
                    : ClipOval(
                        child: Image.network(
                          avatar,
                          width: 44.r,
                          height: 44.r,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_outline_rounded,
                            color: _primary,
                            size: 22.sp,
                          ),
                        ),
                      ),
              );
            },
          ),
          SizedBox(width: 10.w),
          _IconCircleButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          SizedBox(width: 8.w),
          _IconCircleButton(
            icon: Icons.shopping_cart_outlined,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          const Spacer(),
          Flexible(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: _primary, size: 16.sp),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: isLocationLoading
                          ? Text(
                              'جارٍ تحديد موقعك...',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13.sp,
                                color: const Color(0xff888888),
                              ),
                            )
                          : Text(
                              locationName ?? 'حدد موقعك',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff1A1A1A),
                              ),
                            ),
                    ),
                  ],
                ),
                if (locationError != null)
                  GestureDetector(
                    onTap: onLocationRetry,
                    child: Text(
                      'تعذر تحديد الموقع — إعادة المحاولة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10.sp,
                        color: _primary,
                      ),
                    ),
                  )
                else
                  Text(
                    'الموقع الحالي',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 10.sp, color: Colors.black38),
                  ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
            icon: Icon(Icons.menu_rounded, size: 26.sp, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Icon(icon, size: 22.sp, color: Colors.black87),
      ),
    );
  }
}
