import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:core/src/error/error_reporter.dart';
import 'package:get_it/get_it.dart';

/// Adds typed error routing to any [Bloc]/[Cubit].
extension BlocErrorHandling<E, S> on Bloc<E, S> {
  /// Runs [action], routing an expected [AppException] to [onFailure].
  ///
  /// Only [AppException]s are handled here (they are the expected, typed
  /// failures). Anything else propagates out of the event handler so it reaches
  /// the global `AppBlocObserver` (and reporter) instead of being swallowed.
  ///
  /// A handled failure is still breadcrumbed to the app's [ErrorReporter]: the
  /// user sees a sentence, and the crash sink sees that it happened. That is
  /// the instance `bootstrap` registered — the same one the crash lane uses.
  Future<void> handleBlocAction(
    Future<void> Function() action, {
    required void Function(AppException failure) onFailure,
  }) async {
    // Two captures, because they answer two questions. This one, before the
    // await, still has the whole synchronous caller chain — the call that
    // set the action off. An async trace keeps only awaiting frames, so by
    // the catch that caller is usually gone.
    final invokedAt = StackTrace.current;
    try {
      await action();
    } on AppException catch (failure) {
      // And this one, inside the catch: frame 0 is this block, the code that
      // handles the failure.
      unawaited(
        _reporter.reportHandled(
          failure,
          handledAt: StackTrace.current,
          invokedAt: invokedAt,
        ),
      );
      onFailure(failure);
    }
  }

  /// The app's reporter, or a no-op when nothing has registered one.
  ///
  /// Resolved rather than injected so no bloc has to carry a reporter it does
  /// not otherwise use. Guarded because `core`'s own tests and the component
  /// demo never run `bootstrap`: an unguarded lookup would throw from inside
  /// the failure path, turning a handled failure into a crash.
  ErrorReporter get _reporter {
    final locator = GetIt.instance;
    return locator.isRegistered<ErrorReporter>()
        ? locator<ErrorReporter>()
        : const NoopErrorReporter();
  }
}
