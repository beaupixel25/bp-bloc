import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:core/src/error/error_reporter.dart';

/// Adds typed error routing to any [Bloc]/[Cubit].
extension BlocErrorHandling<E, S> on Bloc<E, S> {
  /// Runs [action], routing an expected [AppException] to [onFailure].
  ///
  /// Only [AppException]s are handled here (they are the expected, typed
  /// failures). Anything else propagates out of the event handler so it reaches
  /// the global `AppBlocObserver` (and reporter) instead of being swallowed.
  ///
  /// A handled failure is still breadcrumbed to `appErrorReporter`: the user
  /// sees a sentence, and the crash sink sees that it happened.
  Future<void> handleBlocAction(
    Future<void> Function() action, {
    required void Function(AppException failure) onFailure,
  }) async {
    try {
      await action();
    } on AppException catch (failure) {
      unawaited(appErrorReporter.reportHandled(failure));
      onFailure(failure);
    }
  }
}
