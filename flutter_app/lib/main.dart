import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/theme/app_colors.dart';
import 'package:ai_saas/presentation/blocs/blocs.dart';
import 'package:ai_saas/screens/splash_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When a 401 cannot be recovered via token refresh, notify UserController so
  // it can clear user state. Done via callback to avoid a circular import
  // (ApiClient ← UserController ← AuthService ← ApiClient).
  ApiClient.setSessionExpiredCallback(
      () => UserController.instance.onTokenExpired());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<UserBloc>(create: (_) => UserBloc()),
        BlocProvider<ProductBloc>(create: (_) => ProductBloc()),
        BlocProvider<StoreBloc>(create: (_) => StoreBloc()),
        BlocProvider<CartBloc>(create: (_) => CartBloc()),
        BlocProvider<OrderBloc>(create: (_) => OrderBloc()),
        BlocProvider<FavoriteBloc>(create: (_) => FavoriteBloc()),
        BlocProvider<CategoryBloc>(create: (_) => CategoryBloc()),
        BlocProvider<MerchantBloc>(create: (_) => MerchantBloc()),
        BlocProvider<ClientDashboardBloc>(
          create: (_) => ClientDashboardBloc(),
        ),
        BlocProvider<MerchantDashboardBloc>(
          create: (_) => MerchantDashboardBloc(),
        ),
        BlocProvider<MerchantSubscriptionBloc>(
          create: (_) => MerchantSubscriptionBloc(
            refreshCurrentUser: UserController.instance.refreshProfile,
          ),
        ),
        BlocProvider<AdminDashboardBloc>(create: (_) => AdminDashboardBloc()),
        BlocProvider<AdminAnalyticsBloc>(create: (_) => AdminAnalyticsBloc()),
        BlocProvider<AdminUsersBloc>(create: (_) => AdminUsersBloc()),
        BlocProvider<AdminMerchantsBloc>(create: (_) => AdminMerchantsBloc()),
        BlocProvider<AdminCategoriesBloc>(create: (_) => AdminCategoriesBloc()),
        BlocProvider<AdminPlansBloc>(create: (_) => AdminPlansBloc()),
        BlocProvider<AdminReviewsBloc>(create: (_) => AdminReviewsBloc()),
        BlocProvider<AdminSubscriptionRequestsBloc>(
          create: (_) => AdminSubscriptionRequestsBloc(),
        ),
        BlocProvider<AdminProductsBloc>(
          create: (_) => AdminProductsBloc(),
        ),
        BlocProvider<NotificationsBloc>(
          create: (_) => NotificationsBloc(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            home: const SplashScreen(),
            // home: const BnScreen(type: AppType.client),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    // Base text theme using IBM Plex Sans
    final base = GoogleFonts.ibmPlexSansTextTheme();

    return ThemeData(
      useMaterial3: false,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        hintStyle: GoogleFonts.ibmPlexSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
      ),
    );
  }
}
