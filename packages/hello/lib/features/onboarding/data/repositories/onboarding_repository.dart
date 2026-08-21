// Placeholder repository: real remote/cache calls are not wired yet, so every
// method throws inside `guard`, which maps the failure to an UnknownException.
// Replace the bodies with real data-source calls, keeping the `guard(...)`
// wrapper so raw errors are always translated to typed AppExceptions.

// core also exports an `Environment` enum; hide it so the injectable
// `Environment` (used by @LazySingleton's env) resolves unambiguously.
import 'package:core/core.dart' hide Environment;
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';
import 'package:hello/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(
  as: IOnboardingRepository,
  env: [
    Environment.dev,
    'staging',
    Environment.prod,
  ],
)
class OnboardingRepository extends BaseRepository
    implements IOnboardingRepository {
  /// Creates the repository against [_api].
  ///
  /// `ApiClient` comes from `core` and is registered for you — from a
  /// `@module` in `inject.dart` under get_it, or from `apiClientProvider`
  /// under Riverpod. Take it here rather than calling `http` directly: it is
  /// what turns a non-2xx status and the backend's own error code into a
  /// typed `AppException`.
  ///
  /// Not `const`: `BaseRepository` has no const constructor.
  OnboardingRepository(this._api);

  // Unused only until you replace the two placeholder bodies below with the
  // real calls, which is the first thing you are meant to do here.
  // ignore: unused_field
  final ApiClient _api;

  @override
  Future<AuthToken> login(Credentials credentials) => guard(() async {
        // Replace with the real call, keeping the `guard(...)` wrapper:
        //
        //   final json = await _api.post(
        //     '/auth/login',
        //     body: CredentialsModel.fromEntity(credentials).toJson(),
        //   );
        //   return AuthTokenModel.fromJson(json);
        //
        // A 401 arrives here already typed, carrying whatever code the
        // backend sent — see `OnboardingErrorCodes`.
        throw UnimplementedError();
      });

  @override
  Future<AuthToken> signUp(EmailSignup emailSignup) => guard(() async {
        // Replace with the real call, keeping the `guard(...)` wrapper:
        //
        //   final json = await _api.post(
        //     '/auth/signup',
        //     body: EmailSignupModel.fromEntity(emailSignup).toJson(),
        //   );
        //   return AuthTokenModel.fromJson(json);
        throw UnimplementedError();
      });
}
