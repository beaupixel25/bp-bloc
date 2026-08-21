import 'dart:async';
import 'package:core/core.dart' show Environment;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/app/view/home_page.dart';
import 'package:hello/app/view/notifications_page.dart';
import 'package:hello/app/view/settings_page.dart';
import 'package:hello/common/widgets/main_nav_bar/main_nav_bar.dart';
import 'package:hello/inject.dart';
import 'package:hello/routing/routes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await configureInjection(Environment.test);
    await tester.pumpWidget(const HelloApp());
    await tester.pumpAndSettle();
  }

  /// Past the launch and the sign-in gate in one step: both are pinned by
  /// launch_page_test.dart already, so this file starts at the shell
  /// instead of seeding isSignedIn and waiting out the brand animation.
  Future<void> goToMain(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/main');
    await tester.pumpAndSettle();
  }

  group('the signed-in shell', () {
    testWidgets(
      'a page pushed inside a branch survives switching away and back',
      (tester) async {
        await pumpApp(tester);
        await goToMain(tester);
        expect(find.byType(HomePage), findsOneWidget);

        // Pushed straight onto the Home branch's own Navigator — not
        // reachable from HomePage's UI, but exactly what a feature page
        // pushed deeper into the Home tab would do. A plain `IndexedStack`
        // of pages has nowhere to keep this: it swaps pages, not each
        // branch's own navigation stack.
        const pushedKey = Key('main_shell_test-pushed');
        unawaited(
          Navigator.of(tester.element(find.byType(HomePage))).push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(key: pushedKey),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(pushedKey), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Home'));
        await tester.pumpAndSettle();

        // The point of `indexedStack` over a plain `IndexedStack` of pages:
        // the branch kept its own stack, so the pushed page is still here
        // rather than back at the branch root.
        expect(find.byKey(pushedKey), findsOneWidget);
      },
    );

    testWidgets(
      'every destination reaches its own branch, in bar order',
      (tester) async {
        await pumpApp(tester);
        await goToMain(tester);

        // The bar's items and the shell's branches are two lists that
        // nothing reconciles: goBranch is handed the tapped index and
        // trusts it. Insert a destination in one list only and every tab
        // after it quietly opens its neighbour's page, which no test that
        // taps a single tab would notice. This walks all three.
        await tester.tap(find.bySemanticsLabel('Notifications'));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsPage), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Home'));
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    testWidgets(
      'the nav bar element is identical across a tab switch',
      (tester) async {
        await pumpApp(tester);
        await goToMain(tester);

        // Identity, not presence. A MainNavBar rebuilt inside each page's
        // own Scaffold would still be found here, and would still look
        // right on screen after the switch below — capturing the element
        // is the only way to tell it apart from the one MainNavBar the
        // shell builds once, outside the branch content.
        final before = tester.element(find.byType(MainNavBar));

        await tester.tap(find.bySemanticsLabel('Settings'));
        await tester.pumpAndSettle();

        final after = tester.element(find.byType(MainNavBar));
        expect(after, same(before));
      },
    );

    testWidgets(
      're-tapping the active tab returns it to the branch root',
      (tester) async {
        await pumpApp(tester);
        await goToMain(tester);

        // Pushed through go_router's own HomeRoute().push, not
        // Navigator.of(context).push: goBranch resets go_router's own
        // tracked location for the branch, and a raw Navigator push never
        // joins that — it would survive this whole test even with
        // initialLocation missing, proving nothing.
        final homeContext = tester.element(find.byType(HomePage));
        unawaited(const HomeRoute().push(homeContext));
        await tester.pumpAndSettle();

        // canPop, not a widget count: go_router reuses the one HomePage
        // element for a second match on the same route, so the pushed
        // match only shows up as something the branch's Navigator can
        // still pop back from.
        NavigatorState homeNavigatorOf(WidgetTester t) =>
            Navigator.of(t.element(find.byType(HomePage)));
        expect(homeNavigatorOf(tester).canPop(), isTrue);

        // Home is already the active tab — this taps it again rather than
        // switching to it, which is goBranch's initialLocation: true
        // argument: easy to omit, and silent when missing, since every
        // other tap in this file switches away from the active tab.
        await tester.tap(find.bySemanticsLabel('Home'));
        await tester.pumpAndSettle();

        expect(homeNavigatorOf(tester).canPop(), isFalse);
      },
    );
  });
}
