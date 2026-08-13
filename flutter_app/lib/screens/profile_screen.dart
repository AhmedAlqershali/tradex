import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/edit_profile_screen.dart';
import 'package:ai_saas/screens/change_password_screen.dart';
import 'package:ai_saas/screens/onboarding_screen.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/screens/notifications_screen.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:ai_saas/shared/users/avatar_diagnostics.dart';
import 'package:ai_saas/shared/widgets/product_image.dart';
import 'package:ai_saas/core/api/app_config.dart';
import 'package:ai_saas/core/localization/app_locale_controller.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays the authenticated user's server-backed avatar.
///
/// A native picker path is intentionally not accepted here. Picker paths are
/// transient upload input and [AppUser.fromServerJson] only promotes a server
/// URL (or `/storage/...`) into [AppUser.photoPath].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoPath,
    this.size = 100,
  });

  static const _placeholderKey = ValueKey<String>('profile-avatar-placeholder');

  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (photoPath == null || photoPath!.trim().isEmpty) {
      AvatarDiagnostics.log(
        'ProfileAvatar ImageProvider',
        photoPath,
        provider: 'AssetImage(local-placeholder)',
      );
      AvatarDiagnostics.logProfileProvider(
        provider: 'AssetImage(client.png)',
      );
      AvatarDiagnostics.end();
      return _placeholder();
    }

    if (!AppUser.isServerPhotoPath(photoPath!)) {
      AvatarDiagnostics.log(
        'ProfileAvatar ImageProvider',
        photoPath,
        provider: 'AssetImage(local-placeholder)',
      );
      AvatarDiagnostics.logProfileProvider(
        provider: 'AssetImage(client.png)',
      );
      AvatarDiagnostics.end();
      return _placeholder();
    }

    final resolvedUrl = AppConfig.resolveMediaUrl(photoPath!);
    AvatarDiagnostics.log(
      'ProfileAvatar ImageProvider',
      resolvedUrl,
      provider: 'NetworkImage',
    );
    AvatarDiagnostics.logProfileProvider(
      provider: 'NetworkImage',
      resolvedUrl: resolvedUrl,
    );
    AvatarDiagnostics.probeDownload(resolvedUrl);
    return Image.network(
      resolvedUrl,
      key: ValueKey<String>('profile-avatar-network:$resolvedUrl'),
      fit: BoxFit.cover,
      errorBuilder: (_, __, error) {
        AvatarDiagnostics.log(
          'ProfileAvatar network failure',
          resolvedUrl,
          provider: 'AssetImage(local-placeholder)',
          error: error.runtimeType.toString(),
        );
        AvatarDiagnostics.logProfileProvider(
          provider: 'AssetImage(client.png)',
          resolvedUrl: resolvedUrl,
        );
        AvatarDiagnostics.end();
        return _placeholder();
      },
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) {
          AvatarDiagnostics.end();
        }
        return child;
      },
    );
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/images/client.png',
      key: _placeholderKey,
      fit: BoxFit.cover,
    );
  }
}

// ─── ProfileScreen ────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primary = Color(0xff4D41DF);
  static const Color _bg = Color(0xffF8F9FD);
  static const Color _textDark = Color(0xff1A1A1A);
  static const Color _textGray = Color(0xff707070);

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(const UserLoadRequested());
    context.read<FavoriteBloc>().add(const FavoritesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Directionality(
          textDirection: l10n.textDirection,
          child: ValueListenableBuilder<AppUser?>(
            valueListenable: UserController.instance.currentUserNotifier,
            builder: (context, user, _) {
              AvatarDiagnostics.log(
                'Profile rebuild',
                user?.photoPath,
                widgetReceivesUser: user != null,
              );
              final displayName = user?.displayName ?? l10n.defaultUser;
              final region = user?.region ?? '';
              final photoPath = user?.photoPath;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  children: [
                    // ── Avatar & name ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _primary.withValues(alpha: 0.2),
                                width: 4.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              color: Colors.white,
                            ),
                            child: ProfileAvatar(
                              photoPath: photoPath,
                              size: 100.w,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            displayName,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          if (region.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14.sp, color: _textGray),
                                SizedBox(width: 2.w),
                                Text(region,
                                    style: GoogleFonts.ibmPlexSans(
                                        fontSize: 13.sp, color: _textGray)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // ── Settings list ──────────────────────────────────────
                    _buildSettingsSection(context),

                    SizedBox(height: 24.h),

                    // ── Favorites ──────────────────────────────────────────
                    _buildFavoritesSection(),

                    SizedBox(height: 24.h),

                    // ── Logout ─────────────────────────────────────────────
                    _buildLogoutButton(context),

                    SizedBox(height: 20.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settings,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: _textDark)),
        SizedBox(height: 12.h),
        _buildSettingsTile(
          icon: Icons.person_outline,
          label: l10n.editProfile,
          onTap: () async {
            final userBloc = context.read<UserBloc>();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
            if (mounted) {
              userBloc.add(const UserLoadRequested());
            }
          },
        ),
        _buildSettingsTile(
          icon: Icons.lock_outline,
          label: l10n.changePassword,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          icon: Icons.notifications_outlined,
          label: l10n.notifications,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          icon: Icons.language_outlined,
          label: l10n.language,
          onTap: () => _showLanguagePicker(context),
        ),
      ],
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 12.h),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.language,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
            ),
            _languageOption(
              sheetContext,
              const Locale('ar'),
              l10n.languageArabic,
              l10n.isArabic,
            ),
            _languageOption(
              sheetContext,
              const Locale('en'),
              l10n.languageEnglish,
              !l10n.isArabic,
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext context,
    Locale locale,
    String label,
    bool selected,
  ) {
    return ListTile(
      title: Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 15.sp)),
      trailing:
          selected ? const Icon(Icons.check_rounded, color: _primary) : null,
      onTap: () async {
        await AppLocaleController.instance.setLocale(locale);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 18.sp, color: _primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _textDark)),
            ),
            Icon(Icons.arrow_back_ios_rounded,
                size: 14.sp, color: const Color(0xffCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, favState) {
        List<Product> favorites = [];
        if (favState is FavoriteLoaded) favorites = favState.products;
        if (favState is FavoriteFailure) favorites = favState.products;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).favorites,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
            SizedBox(height: 12.h),
            favorites.isEmpty
                ? _buildEmptyFavorites()
                : SizedBox(
                    height: 180.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: favorites.length,
                      separatorBuilder: (_, __) => SizedBox(width: 10.w),
                      itemBuilder: (context, i) =>
                          _buildFavoriteCard(context, favorites[i]),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        width: 130.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                child: ProductImage(
                  url: product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₪',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffEFEFEF)),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 40.sp, color: const Color(0xffCCCCCC)),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context).noFavorites,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 14.sp, color: const Color(0xff888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingAIPage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: isLoading
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.logout_rounded, size: 18.sp),
            label: Text(
              isLoading
                  ? AppLocalizations.of(context).loggingOut
                  : AppLocalizations.of(context).logout,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        );
      },
    );
  }
}
