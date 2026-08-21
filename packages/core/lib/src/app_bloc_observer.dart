import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:core/src/error/error_reporter.dart';

/// Logs BLoC lifecycle events, reports unhandled bloc errors to the crash
/// [ErrorReporter], and signals when a session has expired.
///
/// Any error that reaches [onError] is one a bloc did not handle as state, so
/// it is treated as a crash: normalized to an [AppException] and forwarded to
/// the [reporter] with the original cause + stack trace. An
/// [UnauthorizedException] additionally triggers [onUnauthorized] so the app
/// can route to sign-in.
class AppBlocObserver extends BlocObserver {
  /// Creates the observer. [reporter] and [onUnauthorized] default to no-ops so
  /// a generated app runs without extra wiring.
  const AppBlocObserver({
    this.reporter = const NoopErrorReporter(),
    this.onUnauthorized,
  });

  /// Crash sink that unhandled bloc errors are reported to.
  final ErrorReporter reporter;

  /// Called when an [UnauthorizedException] reaches [onError].
  final void Function()? onUnauthorized;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    final normalized = error is AppException
        ? error
        : UnknownException(cause: error, stackTrace: stackTrace);
    if (normalized is UnauthorizedException) {
      onUnauthorized?.call();
    }
    unawaited(
      reporter.report(
        normalized.cause ?? error,
        normalized.stackTrace ?? stackTrace,
      ),
    );
    super.onError(bloc, error, stackTrace);
  }
}
