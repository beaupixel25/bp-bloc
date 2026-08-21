/// The client-side rules an email and password pair must pass
/// before the app spends a round trip on either form.
///
/// Pure Dart, deliberately: the login and sign-up forms both call it, and a
/// test can exercise every rule without a widget or a container.
///
/// Validate on submit, not on blur — telling someone their half-typed email
/// is wrong while they are still typing it punishes them mid-thought.
abstract final class CredentialValidator {
  /// The shortest password the app accepts. Matches the floor
  /// `PasswordStrengthMeterViewModel` uses, so the rule and the meter never
  /// disagree about what counts as long enough.
  static const int minimumPasswordLength = 8;

  /// Deliberately permissive: `something@something.something`. A stricter
  /// pattern rejects addresses that are perfectly valid (new TLDs, plus
  /// tagging, unicode locals), and the real check is the confirmation mail.
  static final RegExp _emailPattern =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Returns what to fix about [email], or null once it is ready to submit.
  static String? email(String email) {
    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Add an email in the form name@example.com';
    }
    return null;
  }

  /// Returns what to fix about [password], or null once it is ready to
  /// submit.
  static String? password(String password) {
    if (password.length < minimumPasswordLength) {
      return 'Use at least $minimumPasswordLength characters';
    }
    return null;
  }
}
