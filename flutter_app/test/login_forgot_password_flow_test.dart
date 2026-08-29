import 'package:ai_saas/core/services/password_reset_link_service.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/presentation/blocs/auth/auth_bloc.dart';
import 'package:ai_saas/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp() {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (context, child) => MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(),
        child: const LoginScreen(type: AppType.client),
      ),
    ),
  );
}

void main() {
  group('forgot-password flow', () {
    testWidgets('dialog opens and validates input', (tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();

      expect(find.text('استعادة كلمة المرور'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('إرسال رابط إعادة التعيين'), findsOneWidget);

      await tester.tap(find.text('إرسال رابط إعادة التعيين'));
      await tester.pumpAndSettle();
      expect(find.text('يرجى إدخال البريد الإلكتروني.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'not-an-email');
      await tester.tap(find.text('إرسال رابط إعادة التعيين'));
      await tester.pumpAndSettle();
      expect(find.text('يرجى إدخال بريد إلكتروني صحيح.'), findsOneWidget);
    });

    test('deep-link parser extracts email and token from the real Laravel URL', () {
      const url = 'https://tradex-v2us.onrender.com/api/v1/auth/password/reset?token=abc123&email=user@example.com';
      final payload = PasswordResetLinkParser.parse(url);

      expect(payload, isNotNull);
      expect(payload!.email, 'user@example.com');
      expect(payload.token, 'abc123');
    });

    test('deep-link parser rejects malformed or non-reset URLs', () {
      expect(PasswordResetLinkParser.parse('https://example.com/'), isNull);
      expect(PasswordResetLinkParser.parse('https://example.com/reset?token=abc'), isNull);
      expect(PasswordResetLinkParser.parse('https://example.com/api/v1/auth/password/reset?email=user@example.com'), isNull);
    });
  });
}
