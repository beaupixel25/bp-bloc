import 'dart:async';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

// core exports a `test` environment const; hide it so flutter_test's
// `test` function is unambiguous.
import 'package:core/core.dart' hide test;
import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the global error net hands to the crash sink.
class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];
  final List<AppException> handled = [];

  @override
  Future<void> report(Object error, StackTrace stackTrace) async =>
      reported.add(error);

  @override
  Future<void> reportHandled(AppException error) async => handled.add(error);
}

void main() {
  late _RecordingReporter reporter;
  late FlutterExceptionHandler? previousOnError;
  late ErrorCallback? previousPlatformOnError;
  late ErrorWidgetBuilder previousErrorWidgetBuilder;

  setUp(() {
    reporter = _RecordingReporter();
    // `bootstrap` installs process-global handlers; a test that leaves them
    // installed changes how every later test reports its own failures.
    previousOnError = FlutterError.onError;
    previousPlatformOnError = PlatformDispatcher.instance.onError;
    previousErrorWidgetBuilder = ErrorWidget.builder;
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
    PlatformDispatcher.instance.onError = previousPlatformOnError;
    ErrorWidget.builder = previousErrorWidgetBuilder;
    appErrorReporter = const NoopErrorReporter();
  });

  /// Runs `bootstrap` on the real clock, with a deadline, and hands the
  /// framework back the error handler that `bootstrap` overwrote.
  ///
  /// Three details, each load-bearing:
  ///
  /// - **Real clock.** `bootstrap` must be awaited to completion — that is the
  ///   contract every `main_<flavor>.dart` relies on — and a version that never
  ///   completes has to *fail* rather than hang. It cannot be left to
  ///   `--timeout`: under `testWidgets`' fake clock a body stuck on a future
  ///   that never completes also stops time advancing, so the timeout timer
  ///   never fires either and the suite stalls with no output at all.
  /// - **Deadline reported as a value.** An exception thrown inside
  ///   `runAsync` surfaces asynchronously and gets attributed to whichever test
  ///   runs next, so the timeout is caught and asserted on here instead.
  /// - **Restoring the binding's globals.** `bootstrap` installs process-wide
  ///   handlers, and the test binding needs its own back *inside the test
  ///   body*: it asserts that a test neither overrode `FlutterError.onError`
  ///   without restoring it nor changed `ErrorWidget.builder`, and it checks
  ///   the latter when the body ends — too early for a `tearDown` to help.
  Future<void> runBootstrap(
    WidgetTester tester, {
    required FutureOr<Widget> Function() builder,
    required FutureOr<void> Function() initializer,
  }) async {
    final bindingOnError = FlutterError.onError;
    final bindingErrorWidgetBuilder = ErrorWidget.builder;

    final completed = await tester.runAsync(() async {
      try {
        await bootstrap(
          builder,
        initializer: initializer,
          reporter: reporter,
        ).timeout(const Duration(seconds: 5));
        return true;
      } on TimeoutException {
        return false;
      }
    });

    FlutterError.onError = bindingOnError;
    ErrorWidget.builder = bindingErrorWidgetBuilder;

    expect(
      completed,
      isTrue,
      reason: 'bootstrap() never completed — main() would hang here',
    );
    await tester.pump();
  }

  testWidgets('runs the app when composition succeeds', (tester) async {
    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async {},
    );

    expect(find.text('composed'), findsOneWidget);
    expect(reporter.reported, isEmpty);
  });

  testWidgets('completes when composition throws', (tester) async {
    // Composition here is the initializer.
    //
    // The defect this pins: `runZonedGuarded` routes an async body's error to
    // its handler and then abandons the future it returned, so `await
    // runZonedGuarded(...)` never returns and `main()` hangs forever.
    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async => throw StateError('DI blew up'),
    );
  });

  testWidgets('reports a composition failure', (tester) async {
    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async => throw StateError('DI blew up'),
    );

    expect(reporter.reported.single, isA<StateError>());
  });

  testWidgets('renders a surface when composition fails', (tester) async {
    // With the failure reported but nothing left to call `runApp`, the user
    // gets a dead frame. `ErrorWidget.builder` cannot cover it — that replaces
    // a widget that threw during build, and when composition fails there is no
    // tree to replace anything in.
    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async => throw StateError('DI blew up'),
    );

    expect(find.text('composed'), findsNothing);
    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('reports and renders when the builder fails', (tester) async {
    await runBootstrap(
      tester,
      builder: () async => throw StateError('no widget for you'),
      initializer: () async {},
    );

    expect(reporter.reported.single, isA<StateError>());
    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('installs the async catch-all, which claims the error',
      (tester) async {
    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async {},
    );

    final handler = PlatformDispatcher.instance.onError;
    expect(handler, isNotNull);

    // Returning true is what stops the engine re-throwing after we have
    // reported it.
    expect(handler!(StateError('async leak'), StackTrace.current), isTrue);
    expect(reporter.reported.single, isA<StateError>());
  });

  testWidgets('installs the reporter as the breadcrumb sink before composing',
      (tester) async {
    // `appErrorReporter` backs the handled-failure lane, so a breadcrumb
    // captured during composition has to reach the real sink, not the no-op.
    ErrorReporter? sinkDuringInit;

    await runBootstrap(
      tester,
      builder: () => const MaterialApp(home: Text('composed')),
      initializer: () async => sinkDuringInit = appErrorReporter,
    );

    expect(sinkDuringInit, same(reporter));
  });
}
