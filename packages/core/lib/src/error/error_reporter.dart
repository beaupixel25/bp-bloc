import 'dart:developer';

import 'package:core/src/domain/exceptions/app_exception.dart';

/// Vendor-agnostic crash/error sink.
///
/// `core` never depends on a concrete crash reporter (Sentry, Crashlytics,
/// ...). `bootstrap` owns the instance: it constructs a
/// [ConsoleErrorReporter] unless an app passes its own, installs it in the
/// global error net, and registers it in the app's container so the handled
/// lane resolves the very same object.
abstract class ErrorReporter {
  /// Reports [error] with its [stackTrace] to the backing service.
  ///
  /// Everything arriving here is *unhandled*: nothing turned it into state, so
  /// it is a crash.
  Future<void> report(Object error, StackTrace stackTrace);

  /// Reports a failure that was handled and shown to the user.
  ///
  /// Handled failures are not crashes — someone read a sentence and the app
  /// carried on — but a 5xx that a user experienced as generic copy is still a
  /// defect, and nothing else in the app would ever tell you it happened.
  /// Implementations should record these as breadcrumbs rather than as issues.
  Future<void> reportHandled(AppException error) async {}
}

/// An [ErrorReporter] that discards everything.
///
/// Not the default — [ConsoleErrorReporter] is. Use this where reporting is
/// noise rather than signal: a test that exercises a failure on purpose, or a
/// flavor running against a fake backend.
class NoopErrorReporter implements ErrorReporter {
  /// Creates a [NoopErrorReporter].
  const NoopErrorReporter();

  @override
  Future<void> report(Object error, StackTrace stackTrace) async {}

  // Declared even though `ErrorReporter` supplies a body: `implements` takes
  // the interface, never the implementation.
  @override
  Future<void> reportHandled(AppException error) async {}
}

/// An [ErrorReporter] that writes to the developer log. What `bootstrap`
/// constructs when an app passes no reporter of its own.
///
/// The single swap point for a real backend: pass
/// `reporter: const SentryErrorReporter()` to `bootstrap` and every reporting
/// site in the app follows, because nothing else names a reporter.
///
/// A default that logs rather than one that discards: a generated app runs
/// with no backend either way, but this one tells you a crash happened.
class ConsoleErrorReporter implements ErrorReporter {
  /// Creates a [ConsoleErrorReporter].
  const ConsoleErrorReporter();

  @override
  Future<void> report(Object error, StackTrace stackTrace) async {
    log('crash: $error', name: 'ErrorReporter', stackTrace: stackTrace);
  }

  @override
  Future<void> reportHandled(AppException error) async {
    // A breadcrumb, not an issue: the user read a sentence and carried on.
    log(
      'handled: ${error.runtimeType}(code: ${error.code})',
      name: 'ErrorReporter',
    );
  }
}
