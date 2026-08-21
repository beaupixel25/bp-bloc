import 'dart:async';
import 'dart:developer';
import 'dart:ui' show PlatformDispatcher;

import 'package:bloc/bloc.dart';
import 'package:core/src/app_bloc_observer.dart';
import 'package:core/src/error/error_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Bootstraps the app: installs the global error net, wires the BLoC observer
/// to the crash [reporter], runs the [initializer] (e.g. DI setup), then runs
/// the app.
///
/// [initializer] runs after `WidgetsFlutterBinding.ensureInitialized()`, so a
/// dependency that must be resolved before the first frame and needs a plugin
/// — injectable's `@preResolve` over SharedPreferences, Firebase, and so on —
/// can be awaited from it.
///
/// [reporter] defaults to a `NoopErrorReporter`; pass a real one to forward
/// crashes to Sentry/Crashlytics/etc. [onUnauthorized] is invoked when an
/// `UnauthorizedException` reaches the observer.
Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required FutureOr<void> Function() initializer,
  ErrorReporter reporter = const NoopErrorReporter(),
  void Function()? onUnauthorized,
}) async {
  // With the other global installs, and deliberately before composition:
  // a failure `handleBlocAction` captures while `initializer()` runs
  // would otherwise breadcrumb to the no-op.
  appErrorReporter = reporter;

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    unawaited(
      reporter.report(details.exception, details.stack ?? StackTrace.current),
    );
  };

  // The async catch-all: uncaught futures, platform channels, anything that
  // escapes `main`. Deliberately NOT paired with a `runZonedGuarded` — a custom
  // zone handles in-zone errors itself, so they never reach the root zone and
  // this handler would be dead for everything except errors raised outside the
  // zone. Flutter has recommended this over zones since 3.3, which also avoids
  // the start-up cost a zone imposes on Dart's core libraries.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log(error.toString(), stackTrace: stackTrace);
    unawaited(reporter.report(error, stackTrace));
    return true;
  };

  ErrorWidget.builder = (details) => const Material(
        child: Center(child: Text('Something went wrong.')),
      );

  Bloc.observer = AppBlocObserver(
    reporter: reporter,
    onUnauthorized: onUnauthorized,
  );

  try {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();
    // After the binding, so an initializer that awaits a plugin
    // (SharedPreferences, Firebase) works. That was true of the Riverpod
    // variant from the start; this one used to run the initializer before the
    // binding, and a `@preResolve` dependency that touched a plugin failed on
    // it.
    await initializer();
    runApp(await builder());
    // Composition is the one place a bare catch is right: anything at all
    // going wrong here means there is no app, and the alternative is a hang.
    // ignore: avoid_catches_without_on_clauses
  } catch (error, stackTrace) {
    // Composition failed, so nothing called `runApp`. `ErrorWidget.builder`
    // cannot cover this — it replaces a widget that threw during build, and
    // there is no tree yet — so render the surface here.
    //
    // A `runZonedGuarded` cannot do this job at all: given an async body that
    // throws, it routes the error to its handler and then abandons the future
    // it returned, so `await` on it never returns and `main()` hangs.
    log(error.toString(), stackTrace: stackTrace);
    unawaited(reporter.report(error, stackTrace));
    runApp(const _BootstrapFailure());
  }
}

/// Shown when composition itself failed, so there is no app to render.
///
/// Self-contained on purpose: this is a `runApp` root, so nothing above it
/// supplies the `Directionality` that [ErrorWidget.builder]'s bare [Material]
/// gets from the tree it is spliced into.
class _BootstrapFailure extends StatelessWidget {
  const _BootstrapFailure();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Something went wrong.')),
        ),
      );
}
