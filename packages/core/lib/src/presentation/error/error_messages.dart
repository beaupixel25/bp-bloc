import 'package:core/src/domain/exceptions/app_exception.dart';

/// The localized strings an app supplies so [AppExceptionL10n.toUserMessage]
/// can turn a typed [AppException] into user-facing text.
///
/// `core` stays localization-agnostic: an app implements this interface backed
/// by its own generated `AppLocalizations`, keeping the mapping in one place.
abstract class ErrorMessages {
  /// Generic fallback for unclassified or internal errors.
  String get errorGeneric;

  /// Message for a connectivity/timeout failure.
  String get errorNetwork;

  /// Message shown when the session has expired / auth is required.
  String get errorSessionExpired;

  /// Message shown when the user is not permitted to perform the action.
  String get errorForbidden;

  /// Message shown when a requested resource was not found.
  String get errorNotFound;

  /// Message shown when input fails validation.
  String get errorValidation;

  /// The message for a backend error [code], or null to fall back to the
  /// exception's type.
  ///
  /// Backend codes are app-specific, so `core` supplies no mapping. An app
  /// overrides this against its own generated localizations, which is what
  /// lets a 409 "email already registered" read differently from a 422
  /// "password too weak" even though both arrive as a `ValidationException`.
  ///
  /// The body here does **not** spare implementers: every one in a generated
  /// project uses `implements`, and Dart requires each member of an
  /// implemented interface whether or not the interface supplies one.
  String? forCode(String code) => null;
}

/// Resolves a typed [AppException] to a localized, user-facing string.
extension AppExceptionL10n on AppException {
  /// Maps this exception to a user-facing message using [messages].
  ///
  /// The backend's own [code] is consulted first, so a coded failure gets copy
  /// about *that* failure; anything uncoded, or coded in a way the app does not
  /// recognise, falls back to the exception's type.
  ///
  /// Raw messages on [ServerException]/[CacheException]/[UnknownException] are
  /// intentionally NOT surfaced (they are for logs only); a generic message is
  /// shown instead. A [DisplayableException] carries an already-localized
  /// message and is shown directly.
  String toUserMessage(ErrorMessages messages) {
    final coded = code == null ? null : messages.forCode(code!);
    if (coded != null) return coded;
    return switch (this) {
      NetworkException() => messages.errorNetwork,
      UnauthorizedException() => messages.errorSessionExpired,
      ForbiddenException() => messages.errorForbidden,
      NotFoundException() => messages.errorNotFound,
      ValidationException() => messages.errorValidation,
      DisplayableException(:final message) => message ?? messages.errorGeneric,
      ServerException() ||
      CacheException() ||
      UnknownException() =>
        messages.errorGeneric,
    };
  }
}
