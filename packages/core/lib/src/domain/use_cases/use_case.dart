import 'package:core/src/domain/exceptions/app_exception.dart';

/// A single, self-contained unit of business logic.
///
/// Each implementation performs exactly one operation, exposed through [call]
/// so that instances can be invoked like a function
/// (`await myUseCase(input: ...)`). [P] is the input type and [R] the result.
///
/// BLoCs should invoke [execute] rather than [call]: it guarantees that any
/// error leaving the use case is a typed [AppException] whose original cause
/// and stack trace are preserved. Override [execute] to apply domain
/// re-mapping (e.g. translate a `ServerException` with code `409` into a
/// business-specific [AppException]) before calling `super.execute`.
abstract class UseCase<P, R> {
  /// Runs the use case with an optional [input] and returns its [R] result.
  ///
  /// Implementations put their business logic here. Callers should prefer
  /// [execute], which wraps this in typed error handling.
  Future<R> call({P? input});

  /// Runs [call] and normalizes any failure to an [AppException].
  ///
  /// An [AppException] thrown by [call] is rethrown unchanged; anything else is
  /// wrapped in an [UnknownException] with the original stack trace preserved.
  Future<R> execute({P? input}) async {
    try {
      return await call(input: input);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        UnknownException(cause: error, stackTrace: stackTrace),
        stackTrace,
      );
    }
  }
}
