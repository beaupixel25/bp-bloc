// Mock repository used in the `test` flavor: a small in-memory account
// store, not a repository that always succeeds or always fails. `signUp`
// registers a new account and `login` checks it against what was stored, so
// the two forms finally relate to each other. Both fail the same way on a bad
// login: an unknown email and a wrong password return the identical
// UnauthorizedException, so neither leaks which one was wrong. The email
// `offline@example.com` is reserved to exercise the one path nothing else in
// a generated app reaches: `guard` mapping a SocketException to a
// NetworkException.

import 'dart:io';

// core also exports an `Environment` enum; hide it so the injectable
// `Environment` (used by @LazySingleton's env) resolves unambiguously.
import 'package:core/core.dart' hide Environment;
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';
import 'package:hello/features/onboarding/domain/entities/user.dart';
import 'package:hello/features/onboarding/domain/errors/onboarding_error_codes.dart';
import 'package:hello/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:injectable/injectable.dart';

/// How long the mock waits before resolving, so a running app visibly shows
/// its busy state instead of flashing straight to a result.
///
/// `login_bloc_test.dart` (`authLoginBlocTest` in app.dart) sizes its
/// `wait:` off this same constant plus margin, so the two values cannot
/// silently drift apart — change this one and that test's wait grows with
/// it automatically.
const mockRepositoryLatency = Duration(milliseconds: 700);

/// One stored account: the password held as typed (never hashed — this is a
/// fake backend, and pretending otherwise would be worse) plus the User it
/// signed up.
class _Account {
  const _Account({required this.password, required this.user});

  final String password;
  final User user;
}

@LazySingleton(
  as: IOnboardingRepository,
  env: [Environment.test],
)
class MockOnboardingRepository extends BaseRepository
    implements IOnboardingRepository {
  MockOnboardingRepository();

  /// Keyed by the normalized email, so a lookup does not care how the caller
  /// capitalized or spaced what they typed.
  ///
  /// An instance field, not `static`: a running app keeps one store for its
  /// lifetime, while a test that builds a fresh container gets a fresh store
  /// seeded from scratch, never leaking one test's accounts into the next.
  final Map<String, _Account> _accounts = {
    _normalize('demo@example.com'): _Account(
      password: 'Passw0rd!',
      user: User(
        id: 'demo@example.com',
        firstName: 'Demo',
        lastName: 'User',
        email: 'demo@example.com',
      ),
    ),
  };

  static String _normalize(String email) => email.trim().toLowerCase();

  @override
  Future<AuthToken> login(Credentials credentials) => guard(() async {
        final email = _normalize(credentials.email);
        if (email == 'offline@example.com') {
          throw const SocketException('No internet');
        }
        await Future<void>.delayed(mockRepositoryLatency);

        final account = _accounts[email];
        if (account == null || account.password != credentials.password) {
          // One throw for both branches, and the message is developer-facing:
          // saying which half was wrong tells an attacker whether an address
          // has an account here. The sentence the user reads is resolved from
          // the code by AppErrorMessages.forCode.
          throw const UnauthorizedException(
            message: 'unknown email or wrong password',
            code: OnboardingErrorCodes.invalidCredentials,
          );
        }
        return _tokenFor(account.user);
      });

  @override
  Future<AuthToken> signUp(EmailSignup emailSignup) => guard(() async {
        final email = _normalize(emailSignup.email);
        if (email == 'offline@example.com') {
          throw const SocketException('No internet');
        }
        await Future<void>.delayed(mockRepositoryLatency);

        if (_accounts.containsKey(email)) {
          // A code, not a sentence. This used to be a DisplayableException
          // carrying user-facing copy, because that was the only type the
          // feature's own copy layer forwarded verbatim — copy living in the
          // data layer purely for want of another channel. The code is that
          // channel, and it is what a real backend would send.
          throw const ValidationException(
            message: 'duplicate signup',
            code: OnboardingErrorCodes.emailAlreadyRegistered,
          );
        }

        // EmailSignup carries no name, so there is nothing to put in
        // lastName; firstName borrows the email's local part as a stand-in.
        //
        // Built from the normalized address, not the typed one: the account
        // is keyed by the normalized form, so storing `Sam@Example.com ` as
        // the user's email would render a trailing space and disagree with
        // the key that found it.
        final user = User(
          id: email,
          firstName: email.split('@').first,
          lastName: '',
          email: email,
        );
        _accounts[email] =
            _Account(password: emailSignup.password, user: user);
        return _tokenFor(user);
      });

  AuthToken _tokenFor(User user) => AuthToken(
        user: user,
        expiresAt: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      );
}
