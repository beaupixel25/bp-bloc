import 'package:core/core.dart' hide test;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/features/onboarding/presentation/view/pages/landing/landing_page.dart';
import 'package:hello/features/onboarding/presentation/view/pages/login/login_page.dart';
import 'package:hello/inject.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await configureInjection(Environment.test);
    await tester.pumpWidget(const HelloApp());
    await tester.pumpAndSettle();
  }

  testWidgets('leaving a form keeps what was typed', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(PillButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'someone@example.com',
    );
    // enterText does not guarantee a frame.
    await tester.pump();

    // Back out, then return. Not pageBack(): that hunts for a Material or
    // Cupertino back button, and the onboarding scaffold uses its own
    // IconActionButton, which is found by the label it announces.
    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);

    await tester.tap(find.widgetWithText(PillButton, 'Log in'));
    await tester.pumpAndSettle();

    // The draft survives: leaving a form must cost nothing.
    expect(find.text('someone@example.com'), findsOneWidget);
  });
}
