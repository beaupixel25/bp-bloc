import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';

abstract class IOnboardingRepository {
  Future<AuthToken> login(Credentials credentials);
  Future<AuthToken> signUp(EmailSignup emailSignup);
}
