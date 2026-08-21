import 'package:core/core.dart' show Environment;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/inject.dart';

void main() {
  group('HelloApp', () {
    // The app root resolves its title from BuildConfiguration, so the
    // container has to be populated before the first pump.
    setUpAll(() => configureInjection(Environment.test));

    // The launch's signed-out branch goes to '/landing', where this variant
    // now owns a real page. The stubbed `_restoreSession` always answers
    // signed-out, so a cold start settles there every time today.
    //
    // Every page in the app renders a Scaffold, so this reaches inside the
    // router's Navigator without naming the page that landed there.
    testWidgets('boots and resolves the initial route', (tester) async {
      await tester.pumpWidget(const HelloApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/landing',
      );
    });

    // Regression: `/landing` used to carry no page of its own in this
    // variant and only redirected to `/login`. It owns a real page now, so
    // this pins that the path resolves to something rendered — a URI
    // assertion alone cannot tell a resolved route from go_router's own
    // "page not found" screen, because currentConfiguration reports the
    // requested path either way.
    testWidgets('the landing path resolves to a rendered page',
        (tester) async {
      await tester.pumpWidget(const HelloApp());
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first))
        ..go('/landing');
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/landing',
      );
      expect(find.textContaining('Page Not Found'), findsNothing);
    });

    // Regression: an earlier task left `/` unrouted while `initialLocation`
    // pointed elsewhere, so a cold start never noticed. A web reload at the
    // root, a deep link, or a restored saved state pointed at `/` would have
    // hit go_router's own "page not found" screen instead of the app. This
    // has already settled once above, so the `go('/')` below is a genuine
    // second visit, not a reading of the initial location.
    testWidgets('/ resolves instead of hitting page-not-found', (tester) async {
      await tester.pumpWidget(const HelloApp());
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first))
        ..go('/');
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/landing',
      );
      expect(find.textContaining('Page Not Found'), findsNothing);
    });
  });
}
