import 'package:hello/features/onboarding/domain/entities/user.dart';

class AuthToken {
  const AuthToken({
    required this.user,
    required this.expiresAt,
  });

  final User user;
  final int expiresAt;
}
