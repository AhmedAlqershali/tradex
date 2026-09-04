import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:ai_saas/presentation/blocs/order/order_bloc.dart';
import 'package:ai_saas/screens/client/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  testWidgets('focused Checkout fields stay above the button with keyboard open',
      (tester) async {
    final orderBloc = OrderBloc();
    addTearDown(orderBloc.close);

    const keyboardInset = 300.0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, child) => MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: BlocProvider.value(
              value: orderBloc,
              child: const CheckoutScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    final confirmButton = find.byType(ElevatedButton);
    expect(fields, findsNWidgets(4));

    for (var index = 0; index < 4; index++) {
      await tester.tap(fields.at(index));
      await tester.pumpAndSettle();

      final fieldRect = tester.getRect(fields.at(index));
      final buttonRect = tester.getRect(confirmButton);
      expect(buttonRect.bottom, lessThanOrEqualTo(500));
      expect(fieldRect.bottom, lessThanOrEqualTo(buttonRect.top));
    }
  });
}