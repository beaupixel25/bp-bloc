import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:hello/features/onboarding/domain/use_cases/login_uc.dart';
import 'package:injectable/injectable.dart';

/// {@template login_event}
/// Base class for all events handled by [LoginBloc].
/// {@endtemplate}
sealed class LoginEvent {
  /// {@macro login_event}
  const LoginEvent();
}

/// Emitted when the user submits the login form.
///
/// Carries the [email] and [password] entered by the user.
final class LoginSubmitted extends LoginEvent {
  /// Creates a [LoginSubmitted] event.
  const LoginSubmitted({required this.email, required this.password});

  /// The email entered by the user.
  final String email;

  /// The password entered by the user.
  final String password;
}

/// {@template login_state}
/// Base class for all states emitted by [LoginBloc].
/// {@endtemplate}
sealed class LoginState {
  /// {@macro login_state}
  const LoginState();
}

/// The initial, idle state before any login attempt.
final class LoginInitial extends LoginState {
  /// Creates a [LoginInitial] state.
  const LoginInitial();
}

/// The state while a login request is in flight.
final class LoginInProgress extends LoginState {
  /// Creates a [LoginInProgress] state.
  const LoginInProgress();
}

/// The state emitted when login succeeds.
final class LoginSuccess extends LoginState {
  /// Creates a [LoginSuccess] state carrying the resolved [token].
  const LoginSuccess(this.token);

  /// The authentication token returned by the use case.
  final AuthToken token;
}

/// The state emitted when login fails.
///
/// Carries the typed [AppException] (not a raw string) so the page can resolve
/// it to a localized message via `failure.toUserMessage(...)`.
final class LoginFailure extends LoginState {
  /// Creates a [LoginFailure] state carrying the typed [failure].
  const LoginFailure(this.failure);

  /// The typed error describing why login failed.
  final AppException failure;
}

/// {@template login_bloc}
/// Manages the state of the login page.
///
/// On [LoginSubmitted] it runs [LoginUseCase] via `execute()` and maps the
/// result to [LoginSuccess]; an expected [AppException] becomes [LoginFailure]
/// while anything unexpected propagates to the global observer.
/// {@endtemplate}
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// {@macro login_bloc}
  LoginBloc(this._loginUseCase) : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final LoginUseCase _loginUseCase;

  /// Convenience helper so the page can call `bloc.submit(...)` directly.
  ///
  /// Dispatches a [LoginSubmitted] event; the registered handler remains the
  /// single source of truth for the login flow.
  void submit({required String email, required String password}) {
    add(LoginSubmitted(email: email, password: password));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginInProgress());
    await handleBlocAction(
      () async {
        final credentials =
            Credentials(email: event.email, password: event.password);
        final token = await _loginUseCase.execute(input: credentials);
        emit(LoginSuccess(token));
      },
      onFailure: (failure) => emit(LoginFailure(failure)),
    );
  }
}
