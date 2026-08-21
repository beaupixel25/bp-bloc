/// The error codes `/auth/*` returns, as agreed with the backend.
///
/// Domain, because both layers that need them are on opposite sides of it:
/// `data/` throws them (the mock repository does, and a real one relays
/// whatever the backend sent) and `presentation/` resolves them to a sentence
/// through `AppErrorMessages.forCode`. Domain is the only layer both may
/// import.
///
/// Pure Dart constants, so adding a code is a one-line change here plus one
/// ARB entry per locale — never a new exception subtype. The typed
/// `AppException` vocabulary answers "what kind of failure"; a code answers
/// "which one", and those are different questions.
abstract final class OnboardingErrorCodes {
  /// Sign-up was rejected because the email already has an account.
  static const emailAlreadyRegistered = 'EMAIL_ALREADY_REGISTERED';

  /// Login was rejected: the email is unknown or the password is wrong.
  ///
  /// One code for both, deliberately — telling someone *which* half was wrong
  /// tells an attacker whether an address has an account here.
  static const invalidCredentials = 'INVALID_CREDENTIALS';
}
