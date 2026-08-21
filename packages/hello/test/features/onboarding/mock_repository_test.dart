import 'package:core/core.dart'
    show NetworkException, UnauthorizedException, ValidationException;
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/features/onboarding/data/repositories/mock/onboarding_repository.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';

void main() {
  late MockOnboardingRepository repository;

  setUp(() {
    // A fresh store per test. The provider is keepAlive in a running app, so
    // constructing one here is what keeps tests from leaking accounts into
    // each other.
    repository = MockOnboardingRepository();
  });

  group('the seeded account', () {
    test('logs in with the documented credentials', () async {
      final token = await repository.login(
        const Credentials(email: 'demo@example.com', password: 'Passw0rd!'),
      );
      expect(token.user.email, 'demo@example.com');
    });

    test('rejects the seeded email with the wrong password', () async {
      await expectLater(
        repository.login(
          const Credentials(email: 'demo@example.com', password: 'nope1234'),
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('sign up', () {
    test('registers an account and returns a token', () async {
      final token = await repository.signUp(
        const EmailSignup(email: 'new@example.com', password: 'hunter2xy'),
      );
      // An hour out, per the account store's contract.
      expect(token.expiresAt, greaterThan(0));
    });

    test('a second signup for the same email is refused', () async {
      const signup = EmailSignup(
        email: 'twice@example.com',
        password: 'hunter2xy',
      );
      await repository.signUp(signup);
      await expectLater(
        repository.signUp(signup),
        // Validation carrying a code, not a sentence: the copy the user
        // reads is resolved from that code by the app's error messages.
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'EMAIL_ALREADY_REGISTERED',
          ),
        ),
      );
    });
  });

  group('log in', () {
    test('an unknown email and a wrong password are indistinguishable',
        () async {
      await repository.signUp(
        const EmailSignup(email: 'known@example.com', password: 'hunter2xy'),
      );

      Object? unknownEmail;
      Object? wrongPassword;
      try {
        await repository.login(
          const Credentials(email: 'nobody@example.com', password: 'hunter2xy'),
        );
      } on Object catch (error) {
        unknownEmail = error;
      }
      try {
        await repository.login(
          const Credentials(email: 'known@example.com', password: 'wrongpass'),
        );
      } on Object catch (error) {
        wrongPassword = error;
      }

      // Same type for both. A backend that leaks which one failed teaches an
      // enumeration bug, and the generated copy would have to lie about it.
      expect(unknownEmail, isA<UnauthorizedException>());
      expect(wrongPassword, isA<UnauthorizedException>());
      expect(unknownEmail.runtimeType, wrongPassword.runtimeType);
    });
  });

  group('email normalization', () {
    test('the typed address is not the identity', () async {
      await repository.signUp(
        const EmailSignup(email: 'Sam@Example.com ', password: 'hunter2xy'),
      );
      // Signing up as Sam@Example.com and logging in as sam@example.com is
      // the same person.
      final token = await repository.login(
        const Credentials(email: 'sam@example.com', password: 'hunter2xy'),
      );
      expect(token.user.email, 'sam@example.com');
    });

    test('a differently-cased duplicate is still a duplicate', () async {
      const email = 'Case@Example.com';
      await repository.signUp(
        const EmailSignup(email: email, password: 'hunter2xy'),
      );
      await expectLater(
        repository.signUp(
          EmailSignup(email: email.toUpperCase(), password: 'hunter2xy'),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'EMAIL_ALREADY_REGISTERED',
          ),
        ),
      );
    });
  });

  group('the reserved address', () {
    test('offline@example.com surfaces as a network failure', () async {
      // The SocketException -> NetworkException mapping in
      // BaseRepository.guard is the most load-bearing thing in the data
      // layer, and nothing else in a generated app exercises it.
      await expectLater(
        repository.login(
          const Credentials(
            email: 'offline@example.com',
            password: 'hunter2xy',
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
