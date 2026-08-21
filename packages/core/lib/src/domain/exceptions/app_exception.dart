// toString includes the runtime type on purpose: it only feeds logs/crash
// reports, never user-facing text.
// ignore_for_file: no_runtimetype_tostring

/// Typed, domain-level error vocabulary shared across every layer.
///
/// Raw errors are translated to an [AppException] subtype at the data-layer
/// boundary (see `BaseRepository.handleException`), may be re-mapped by domain
/// rules, and are surfaced to the UI as typed state. The original [cause] and
/// [stackTrace] are always preserved so crash reporting keeps the real trace.
///
/// Apps may add business-specific exceptions by extending [AppException].
sealed class AppException implements Exception {
  /// Creates an [AppException].
  const AppException({this.message, this.code, this.cause, this.stackTrace});

  /// Developer-facing message, for logs. Not shown to users verbatim.
  final String? message;

  /// Optional machine-readable code (e.g. an HTTP status or backend code).
  final String? code;

  /// The original error this exception wraps, if any.
  final Object? cause;

  /// The stack trace captured where [cause] was thrown.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      '$runtimeType(message: $message, code: $code, cause: $cause)';
}

/// No connectivity, socket failure, or a request that timed out.
final class NetworkException extends AppException {
  /// Creates a [NetworkException].
  const NetworkException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The server returned an error, typically an HTTP status of 500 or above.
final class ServerException extends AppException {
  /// Creates a [ServerException].
  const ServerException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Authentication is missing or expired, typically an HTTP 401.
final class UnauthorizedException extends AppException {
  /// Creates an [UnauthorizedException].
  const UnauthorizedException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The caller is authenticated but not permitted, typically an HTTP 403.
final class ForbiddenException extends AppException {
  /// Creates a [ForbiddenException].
  const ForbiddenException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The requested resource does not exist, typically an HTTP 404.
final class NotFoundException extends AppException {
  /// Creates a [NotFoundException].
  const NotFoundException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Input failed validation, or a response could not be parsed.
final class ValidationException extends AppException {
  /// Creates a [ValidationException].
  const ValidationException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// A local cache or storage read/write failed.
final class CacheException extends AppException {
  /// Creates a [CacheException].
  const CacheException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// An error that could not be classified into any other subtype.
final class UnknownException extends AppException {
  /// Creates an [UnknownException].
  const UnknownException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// An error whose [message] is ALREADY localized at the throw site and may be
/// shown to the user directly.
final class DisplayableException extends AppException {
  /// Creates a [DisplayableException].
  const DisplayableException({
    super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
