import 'package:core/core.dart' hide test;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/app/view/home_page.dart';
import 'package:hello/features/onboarding/data/repositories/mock/onboarding_repository.dart';
import 'package:hello/features/onboarding/presentation/view/pages/landing/landing_page.dart';
import 'package:hello/inject.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await configureInjection(Environment.test);
    await tester.pumpWidget(const HelloApp());
    await tester.pumpAndSettle();
  }

  /// Fills the email and password fields, then submits.
  ///
  /// The explicit `pump()` after the last `enterText` is not optional:
  /// `enterText` does not guarantee a frame, so tapping straight after it can
  /// run against a stale form and pass while checking nothing.
  Future<void> submit(
    WidgetTester tester, {
    required String email,
    required String password,
    required String cta,
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.pump();

    // widgetWithText, not text: the scaffold's title and the CTA carry the
    // same words, so a bare find.text matches two widgets and throws.
    await tester.tap(find.widgetWithText(PillButton, cta));
    // pumpAndSettle does not advance a plain Future.delayed, and the account
    // store waits `mockRepositoryLatency` so the busy state is visible. Pump
    // past it explicitly or the assertion below runs before the result.
    await tester.pump(mockRepositoryLatency + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('signup -> home -> start over -> login closes the loop',
      (tester) async {
    const email = 'loop@example.com';
    const password = 'hunter2xy';

    await pumpApp(tester);
    expect(find.byType(LandingPage), findsOneWidget);

    // 1. Sign up with an address the store has never seen.
    await tester.tap(find.widgetWithText(PillButton, 'Create account'));
    await tester.pumpAndSettle();
    await submit(
      tester,
      email: email,
      password: password,
      cta: 'Create account',
    );
    expect(find.byType(HomePage), findsOneWidget);

    // 2. Start over — with no session, this is what signing out looks like.
    await tester.tap(find.widgetWithText(PillButton, 'Start over'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);

    // 3. Log in with the credentials just created. This is the assertion the
    // whole test exists for: it can only pass if signup actually registered
    // the account.
    await tester.tap(find.widgetWithText(PillButton, 'Log in'));
    await tester.pumpAndSettle();
    await submit(tester, email: email, password: password, cta: 'Log in');
    expect(find.byType(HomePage), findsOneWidget);
  });
}
