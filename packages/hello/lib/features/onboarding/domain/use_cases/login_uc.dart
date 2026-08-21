import 'package:core/core.dart';
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginUseCase extends UseCase<Credentials, AuthToken> {
  LoginUseCase(this.onboardingRepository);

  final IOnboardingRepository onboardingRepository;

  @override
  Future<AuthToken> call({Credentials? input}) async {
    return onboardingRepository.login(input!);
  }
}
