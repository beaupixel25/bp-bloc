import 'package:core/core.dart';
import 'package:hello/features/onboarding/domain/errors/onboarding_error_codes.dart';
import 'package:hello/l10n/l10n.dart';

/// Adapts the app's generated [AppLocalizations] to core's [ErrorMessages],
/// so a typed [AppException] can be resolved to a localized string via
/// `exception.toUserMessage(AppErrorMessages(context.l10n))`.
///
/// This is the ONLY exception-to-copy mapper in the app. A feature that needs
/// its own wording adds a backend code and an ARB entry rather than a second
/// mapper — an earlier version of this scaffold had two, and the localized one
/// was the one that never ran.
class AppErrorMessages implements ErrorMessages {
  /// Creates an [AppErrorMessages] backed by [l10n].
  const AppErrorMessages(this.l10n);

  /// The app's generated localizations.
  final AppLocalizations l10n;

  @override
  String get errorGeneric => l10n.errorGeneric;

  @override
  String get errorNetwork => l10n.errorNetwork;

  @override
  String get errorSessionExpired => l10n.errorSessionExpired;

  @override
  String get errorForbidden => l10n.errorForbidden;

  @override
  String get errorNotFound => l10n.errorNotFound;

  @override
  String get errorValidation => l10n.errorValidation;

  /// Resolves a backend error code to copy, or null to fall back to the
  /// exception's type.
  ///
  /// Declared even though `ErrorMessages` supplies a body: `implements` takes
  /// the interface, never the implementation.
  ///
  /// Every string here names the fix, never the failure — someone hitting one
  /// of these is usually mid-something difficult, and the form's job is to be
  /// the easy part.
  @override
  String? forCode(String code) => switch (code) {
        OnboardingErrorCodes.emailAlreadyRegistered =>
          l10n.errorEmailAlreadyRegistered,
        OnboardingErrorCodes.invalidCredentials =>
          l10n.errorInvalidCredentials,
        _ => null,
      };
}
