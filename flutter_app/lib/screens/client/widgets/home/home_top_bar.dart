import 'package:ai_saas/screens/client/cart_screen.dart';
import 'package:ai_saas/screens/search_screen.dart';
import 'package:ai_saas/screens/notifications_screen.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    this.onLocationTap,
  });

  static const Color _primary = Color(0xff4D41DF);
  final String? locationName;
  final bool isLocationLoading;
  final String? locationError;
  final VoidCallback? onLocationRetry;
  final VoidCallback? onLocationTap;

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
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final unreadCount = state is NotificationsLoaded
                  ? state.unreadCount
                  : 0;
              return _NotificationButton(
                unreadCount: unreadCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              );
            },
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
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: _primary, size: 16.sp),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: isLocationLoading
                              ? Text(
                                  AppLocalizations.of(context).locationLoading,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.sp,
                                    color: const Color(0xff888888),
                                  ),
                                )
                              : Text(
                                  locationName ?? AppLocalizations.of(context).locationSelectPrompt,
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
                  ),
                ),
                if (locationError != null)
                  GestureDetector(
                    onTap: onLocationRetry,
                    child: Text(
                      AppLocalizations.of(context).unableGetCurrentLocation,
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
                    AppLocalizations.of(context).currentLocationTitle,
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconCircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xffD92D20),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
