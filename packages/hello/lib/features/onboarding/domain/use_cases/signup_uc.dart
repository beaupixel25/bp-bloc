import 'package:core/core.dart';
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';
import 'package:hello/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignupUseCase extends UseCase<EmailSignup, AuthToken> {
  SignupUseCase(this.onboardingRepository);

  final IOnboardingRepository onboardingRepository;

  @override
  Future<AuthToken> call({EmailSignup? input}) async {
    if (input == null) {
      throw const ValidationException(message: 'SignupUseCase requires input');
    }

    return onboardingRepository.signUp(input);
  }
}
