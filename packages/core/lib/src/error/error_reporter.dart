import 'package:core/src/domain/exceptions/app_exception.dart';

/// Vendor-agnostic crash/error sink.
///
/// `core` never depends on a concrete crash reporter (Sentry, Crashlytics,
/// ...). Apps provide an implementation and pass it to `bootstrap`, which
/// installs it in the global error net. The default `NoopErrorReporter` does
/// nothing, so a generated app runs without a backend.
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

/// An [ErrorReporter] that discards everything. The default until an app wires
/// in a real reporter.
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

/// The sink handled failures are breadcrumbed to. Installed by `bootstrap`.
///
/// A process-global because a handled failure is captured deep in a state
/// holder, sometimes by a top-level function, and neither can be handed a
/// reporter without changing every caller.
///
/// Mutable so a test can install a recorder and restore the no-op in
/// `tearDown`.
ErrorReporter appErrorReporter = const NoopErrorReporter();
