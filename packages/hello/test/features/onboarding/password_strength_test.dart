import 'package:core/core.dart'
    show PasswordStrength, PasswordStrengthMeterViewModel;
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/features/onboarding/domain/validation/credential_validator.dart';

void main() {
  group('the meter and the form agree on the floor', () {
    test('the two minimums are the same number', () {
      // The assertion this file exists for. Both are `= 8` today, written
      // independently in `core` and in the feature — this is what keeps one
      // from being changed without the other.
      expect(
        PasswordStrengthMeterViewModel.minimumLength,
        CredentialValidator.minimumPasswordLength,
      );
    });

    test('one character short scores short, however varied', () {
      // `Ab1!` satisfies mixed case AND digit-and-symbol — two of the four
      // rules. Without the length floor it would read "Good", one rung below
      // a password the form actually accepts.
      final short = 'Ab1!'.padRight(
        CredentialValidator.minimumPasswordLength - 1,
        'x',
      );
      expect(CredentialValidator.password(short), isNotNull);
      expect(
        PasswordStrengthMeterViewModel.evaluate(short).strength,
        PasswordStrength.short,
      );
    });

    test('at the minimum the form accepts and the meter moves off short', () {
      final atMinimum = 'Ab1!'.padRight(
        CredentialValidator.minimumPasswordLength,
        'x',
      );
      expect(CredentialValidator.password(atMinimum), isNull);
      expect(
        PasswordStrengthMeterViewModel.evaluate(atMinimum).strength,
        isNot(PasswordStrength.short),
      );
    });
  });

  group('the ramp', () {
    test('an empty password is empty, not short', () {
      // Nothing typed is not a failing grade. The meter draws a bare track
      // and says nothing, rather than opening with criticism.
      final empty = PasswordStrengthMeterViewModel.evaluate('');
      expect(empty.strength, PasswordStrength.empty);
      expect(empty.fraction, 0);
      expect(empty.label, isEmpty);
    });

    test('every strength but empty has a caption and some fill', () {
      // A page draws `label` beside the track, so a blank one mid-typing
      // reads as the meter having broken.
      for (final password in ['abc', 'abcdefgh', 'abcdefghijkl', 'Ab1!efgh']) {
        final vm = PasswordStrengthMeterViewModel.evaluate(password);
        expect(vm.strength, isNot(PasswordStrength.empty), reason: password);
        expect(vm.label, isNotEmpty, reason: password);
        expect(vm.fraction, greaterThan(0), reason: password);
        expect(vm.fraction, lessThanOrEqualTo(1), reason: password);
      }
    });

    test('more of a password never scores less', () {
      // The ramp is monotonic in length for a fixed character set. A curve
      // that dips would tell someone that typing more made things worse.
      var previous = -1;
      for (var length = 8; length <= 20; length++) {
        final index = PasswordStrengthMeterViewModel.evaluate(
          'a' * length,
        ).strength.index;
        expect(index, greaterThanOrEqualTo(previous), reason: '$length');
        previous = index;
      }
    });
  });
}
