import 'package:core/core.dart' show Environment;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/bloc/app_bloc.dart';
import 'package:hello/app/view/app.dart';
import 'package:hello/app/view/launch_page.dart';
import 'package:hello/inject.dart';

class _SeededAppBloc extends AppBloc {
  _SeededAppBloc({required bool isSignedIn}) {
    emit(state.copyWith(isSignedIn: isSignedIn));
  }

  @override
  void start() {}
}

void main() {
  Future<void> pumpLaunch(
    WidgetTester tester,
    ValueChanged<bool> onResolved,
  ) async {
    await tester.pumpWidget(
      BlocProvider<AppBloc>(
        create: (_) => AppBloc(),
        child: MaterialApp(home: LaunchPage(onResolved: onResolved)),
      ),
    );
    // Microtask-fast, but has not resolved straight out of pumpWidget —
    // forward() has not been called yet either.
    await tester.pump();
  }

  Future<void> pumpFullApp(
    WidgetTester tester, {
    bool isSignedIn = false,
  }) async {
    await configureInjection(Environment.test);
    if (isSignedIn) {
      await injector.unregister<AppBloc>();
      injector.registerFactory<AppBloc>(
        () => _SeededAppBloc(isSignedIn: true),
      );
    }
    await tester.pumpWidget(const HelloApp());
    await tester.pump();
  }

  double markScale(WidgetTester tester) {
    // Found by key, not by type: Scaffold builds a ScaleTransition of its
    // own for the floating-action-button slot even when there is no button,
    // and Material's zoom page-transition wraps every route in another. A
    // bare find.byType(ScaleTransition) picks up both.
    final scaleTransition = find.byKey(LaunchPage.markKey);
    return tester
        .widget<Transform>(
          find.descendant(
            of: scaleTransition,
            matching: find.byType(Transform),
          ),
        )
        .transform
        .entry(0, 0);
  }

  String location(WidgetTester tester) => GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).routerDelegate.currentConfiguration.uri.toString();

  /// Fails if go_router fell through to its "page not found" screen.
  ///
  /// [location] alone cannot see this: go_router sets `currentConfiguration`
  /// to the requested path even when nothing matches it, so a URI assertion
  /// passes while the user is looking at an error screen. That is exactly what
  /// happens if a route is deleted without repointing what navigates to it.
  void expectNoErrorScreen(WidgetTester tester) {
    expect(
      find.textContaining('Page Not Found'),
      findsNothing,
      reason: 'go_router fell through to its error screen',
    );
  }

  group('LaunchPage', () {
    testWidgets('opens on the bento cluster, not on the mark', (tester) async {
      await pumpLaunch(tester, (_) {});

      // Stage one starts with the tiles: the first goes up at 20ms and the
      // mark does not begin to resolve until 520ms. A launch that painted
      // the mark straight away would still pass every timing assertion
      // below, so the order is worth pinning on its own.
      expect(find.byKey(LaunchPage.bentoKey), findsOneWidget);
      expect(markScale(tester), lessThan(1));
    });

    testWidgets(
      'scales the mark in over its own 520-1000ms interval',
      (tester) async {
        await pumpLaunch(tester, (_) {});

        // A scale read off the matrix's max-scale-on-axis would silently
        // read 1.0 here even if markIn never ran, so this reads entry(0, 0)
        // straight off the matrix instead.
        expect(markScale(tester), lessThan(1));

        // Still mid-beat: markIn's own interval ends at 1000ms.
        await tester.pump(const Duration(milliseconds: 600));
        expect(markScale(tester), lessThan(1));

        await tester.pump(const Duration(milliseconds: 450));
        expect(markScale(tester), closeTo(1, 0.001));
      },
    );

    testWidgets(
      'hands off exactly once, at the 2950ms sync point',
      (tester) async {
        var callCount = 0;
        await pumpLaunch(tester, (_) => callCount++);

        // Deep into the hold, and still nothing: the whole point of the
        // sync point is that it is not the end of stage one.
        await tester.pump(const Duration(milliseconds: 2400));
        expect(callCount, 0);

        // 550ms more reaches the sync point; a further 50ms clears the
        // interval's own floating-point boundary at exactly 2950ms.
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump(const Duration(milliseconds: 50));
        expect(callCount, 1);

        // The rest of the timeline must not fire it again — the one thing
        // a listener running on every frame cannot prove by itself.
        await tester.pump(const Duration(milliseconds: 450));
        expect(callCount, 1);
      },
    );

    testWidgets('reduced motion hands off within 900ms', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures();
      });

      var callCount = 0;
      await pumpLaunch(tester, (_) => callCount++);
      await tester.pump(const Duration(milliseconds: 900));

      expect(callCount, 1);
    });

    testWidgets(
      'signed out lands on /landing',
      (tester) async {
        await pumpFullApp(tester);
        await tester.pump(const Duration(milliseconds: 3000));

        expect(location(tester), '/landing');
        // The URI alone would pass even if the route no longer resolved.
        expectNoErrorScreen(tester);
      },
    );

    testWidgets('signed in lands on /main', (tester) async {
      await pumpFullApp(tester, isSignedIn: true);
      await tester.pump(const Duration(milliseconds: 3000));

      expect(location(tester), '/main');
      expectNoErrorScreen(tester);
    });
  });
}
