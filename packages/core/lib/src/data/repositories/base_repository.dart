import 'dart:async';
import 'dart:io';

import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:flutter/foundation.dart';

/// Base class for every data-layer repository.
///
/// Concrete repositories extend this and wrap each remote/cache call in
/// [guard], so any low-level error is translated to a typed [AppException]
/// before it leaves the data layer. Never use a bare `catch (_)` that discards
/// the original error.
abstract class BaseRepository {
  /// Maps a low-level [error] to a typed [AppException].
  ///
  /// If [error] is already an [AppException] it is returned unchanged. Generic
  /// `dart:io`/`dart:async` failures are mapped to their nearest domain type;
  /// anything else becomes an [UnknownException].
  ///
  /// Override this to map client-specific error types (e.g. `DioException`,
  /// `http` `ClientException`, or a GraphQL `OperationException`) — branch on
  /// HTTP status (401 -> [UnauthorizedException], 403 -> [ForbiddenException],
  /// 404 -> [NotFoundException], >= 500 -> [ServerException]) and delegate the
  /// rest to `super.handleException(error, st)`.
  @protected
  AppException handleException(Object error, StackTrace st) {
    if (error is AppException) return error;
    if (error is SocketException) {
      return NetworkException(cause: error, stackTrace: st);
    }
    if (error is TimeoutException) {
      return NetworkException(cause: error, stackTrace: st);
    }
    if (error is HttpException) {
      return ServerException(cause: error, stackTrace: st);
    }
    // A FormatException reaching here came from decoding a payload, never from
    // user input: input is validated before the call, and a rejected field
    // arrives as a ValidationException from ApiClient's 400/422 branch. So this
    // is a broken client/server contract. Mapping it to ValidationException
    // instead told someone to "check your input" about a response they cannot
    // influence, and filed the breadcrumb under user error rather than ours.
    if (error is FormatException) {
      return ServerException(cause: error, stackTrace: st);
    }
    return UnknownException(cause: error, stackTrace: st);
  }

  /// Runs [body] and rethrows any failure as a typed [AppException].
  ///
  /// The mapped exception is rethrown with [Error.throwWithStackTrace] so the
  /// original stack trace is preserved all the way to the crash reporter.
  @protected
  Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, st) {
      Error.throwWithStackTrace(handleException(error, st), st);
    }
  }
}
