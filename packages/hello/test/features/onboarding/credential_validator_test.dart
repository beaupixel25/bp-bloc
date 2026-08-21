import 'package:flutter_test/flutter_test.dart';
import 'package:hello/features/onboarding/domain/validation/credential_validator.dart';

void main() {
  group('CredentialValidator.email', () {
    test('accepts an ordinary address', () {
      expect(CredentialValidator.email('sam@example.com'), isNull);
    });

    test('rejects an empty value and one with no @', () {
      expect(CredentialValidator.email(''), isNotNull);
      expect(CredentialValidator.email('sam.example.com'), isNotNull);
    });

    test('names the fix rather than the failure', () {
      // The copy rule, asserted where a reader can see it break.
      final message = CredentialValidator.email('nope')!;
      expect(message, isNot(contains('!')));
      expect(message.toLowerCase(), isNot(contains('invalid')));
    });
  });

  group('CredentialValidator.password', () {
    test('accepts a password at the minimum length', () {
      final atMinimum = 'a' * CredentialValidator.minimumPasswordLength;
      expect(CredentialValidator.password(atMinimum), isNull);
    });

    test('rejects one character short of the minimum', () {
      // The boundary, not an arbitrary short string: an off-by-one here is
      // the difference between the form and the strength meter disagreeing.
      final tooShort = 'a' * (CredentialValidator.minimumPasswordLength - 1);
      expect(CredentialValidator.password(tooShort), isNotNull);
    });

    test('rejects an empty value', () {
      expect(CredentialValidator.password(''), isNotNull);
    });
  });
}
