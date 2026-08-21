// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:core/core.dart' as _i494;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hello/app/bloc/app_bloc.dart' as _i1031;
import 'package:hello/features/onboarding/data/repositories/mock/onboarding_repository.dart'
    as _i107;
import 'package:hello/features/onboarding/data/repositories/onboarding_repository.dart'
    as _i840;
import 'package:hello/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i955;
import 'package:hello/features/onboarding/domain/use_cases/login_uc.dart'
    as _i466;
import 'package:hello/features/onboarding/domain/use_cases/signup_uc.dart'
    as _i458;
import 'package:hello/features/onboarding/presentation/state/credential_draft_cubit.dart'
    as _i300;
import 'package:hello/features/onboarding/presentation/view/pages/login/login_bloc.dart'
    as _i1034;
import 'package:hello/features/onboarding/presentation/view/pages/signup/signup_page.dart'
    as _i38;
import 'package:hello/inject.dart' as _i263;
import 'package:injectable/injectable.dart' as _i526;

const String _test = 'test';
const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.factory<_i1031.AppBloc>(() => _i1031.AppBloc());
    gh.lazySingleton<_i300.CredentialDraftCubit>(
      () => _i300.CredentialDraftCubit(),
    );
    gh.lazySingleton<_i494.ApiClient>(() => networkModule.apiClient());
    gh.lazySingleton<_i955.IOnboardingRepository>(
      () => _i107.MockOnboardingRepository(),
      registerFor: {_test},
    );
    gh.lazySingleton<_i955.IOnboardingRepository>(
      () => _i840.OnboardingRepository(gh<_i494.ApiClient>()),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i466.LoginUseCase>(
      () => _i466.LoginUseCase(gh<_i955.IOnboardingRepository>()),
    );
    gh.factory<_i458.SignupUseCase>(
      () => _i458.SignupUseCase(gh<_i955.IOnboardingRepository>()),
    );
    gh.factory<_i1034.LoginBloc>(
      () => _i1034.LoginBloc(gh<_i466.LoginUseCase>()),
    );
    gh.factory<_i38.SignupBloc>(
      () => _i38.SignupBloc(gh<_i458.SignupUseCase>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i263.NetworkModule {}
