import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget _testApp({Locale locale = const Locale('ar')}) {
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
      home: const ChangePasswordScreen(),
    ),
  );
}

void main() {
  testWidgets('renders full-screen password form with three fields', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('تغيير كلمة المرور'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byIcon(Icons.visibility), findsNWidgets(3));
  });

  testWidgets('shows localized validation messages for an empty form', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(locale: const Locale('en')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Save password'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save password'));
    await tester.pump();

    expect(find.text('This field is required.'), findsNWidgets(3));
  });

  testWidgets('password visibility controls reveal and hide text', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;

    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility).first);
    await tester.pump();
    expect(tester.widget<TextField>(field).obscureText, isFalse);
  });
}
