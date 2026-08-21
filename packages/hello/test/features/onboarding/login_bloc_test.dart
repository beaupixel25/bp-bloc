import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/features/onboarding/data/repositories/mock/onboarding_repository.dart';
import 'package:hello/features/onboarding/domain/use_cases/login_uc.dart';
import 'package:hello/features/onboarding/presentation/view/pages/login/login_bloc.dart';

void main() {
  group('LoginBloc', () {
    // Proves the full flow: the mock repository throws an UnauthorizedException
    // inside guard() (data), LoginUseCase.execute rethrows it as-is (domain),
    // and the bloc surfaces it as a typed LoginFailure (presentation).
    blocTest<LoginBloc, LoginState>(
      'emits [InProgress, Failure(UnauthorizedException)] when login is denied',
      build: () => LoginBloc(LoginUseCase(MockOnboardingRepository())),
      act: (bloc) => bloc.submit(email: 'a@b.com', password: 'secret'),
      // The mock sleeps `mockRepositoryLatency` (declared alongside
      // MockOnboardingRepository) before rejecting an unknown email, so the
      // second state does not arrive until after that. Sized off the same
      // constant plus a wide margin rather than a second bare number, so a
      // future change to the mock's latency cannot silently leave this wait
      // too short: without one long enough, this test would only ever
      // observe LoginInProgress.
      wait: mockRepositoryLatency + const Duration(milliseconds: 1300),
      expect: () => [
        isA<LoginInProgress>(),
        isA<LoginFailure>().having(
          (s) => s.failure,
          'failure',
          isA<UnauthorizedException>(),
        ),
      ],
    );
  });
}
