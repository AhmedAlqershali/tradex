import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/complete_profile_client_screen.dart';
import 'package:ai_saas/screens/auth/complete_profile_photo_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp({
  required Widget child,
  Locale locale = const Locale('ar'),
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (context, child) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
    child: child,
  );
}

void main() {
  setUp(() {
    UserController.instance.currentUserNotifier.value = AppUser(
      id: 'user-1',
      name: 'Test User',
      email: 'user@example.com',
      phone: '0500000000',
      role: AppType.client,
      createdAt: DateTime.now(),
    );
    UserController.instance.authErrorNotifier.value = null;
  });

  tearDown(() {
    UserController.instance.currentUserNotifier.value = null;
    UserController.instance.authErrorNotifier.value = null;
  });

  testWidgets('selected region and successful save navigates to photo step', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _testApp(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CompleteProfileClientScreen(
            onSubmitRegion: ({String? region}) async {
              expect(region, 'غزة');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('غزة'));
    await tester.pump();

    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompleteProfilePhotoScreen), findsOneWidget);
  });

  testWidgets('failed profile update shows error and does not navigate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: CompleteProfileClientScreen(
          onSubmitRegion: ({String? region}) async {
            UserController.instance.authErrorNotifier.value =
                'تعذر حفظ التغييرات. حاول مرة أخرى.';
            throw const ValidationException('تعذر حفظ التغييرات. حاول مرة أخرى.');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('غزة'));
    await tester.pump();

    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompleteProfilePhotoScreen), findsNothing);
    expect(find.text('تعذر حفظ التغييرات. حاول مرة أخرى.'), findsOneWidget);
  });
}
