part of 'signup_page.dart';

/// {@template signup_event}
/// Base type for all events consumed by the [SignupBloc].
/// {@endtemplate}
@immutable
sealed class SignupEvent {
  /// {@macro signup_event}
  const SignupEvent();
}

/// Dispatched when the user submits the sign up form.
@immutable
final class SignupSubmitted extends SignupEvent {
  /// Creates a [SignupSubmitted] event carrying the entered credentials.
  const SignupSubmitted({
    required this.email,
    required this.password,
  });

  /// The user's email address.
  final String email;

  /// The user's chosen password.
  final String password;
}

/// {@template signup_state}
/// State emitted by the [SignupBloc].
///
/// Every variant carries the entered [email] so the form can preserve the
/// user's input across submissions and failures.
/// {@endtemplate}
@freezed
sealed class SignupState with _$SignupState {
  /// The initial, idle state before any submission.
  const factory SignupState.initial({
    String? email,
  }) = _SignupInitial;

  /// Emitted while the sign up request is in flight.
  const factory SignupState.inProgress({
    String? email,
  }) = _SignupInProgress;

  /// Emitted when the sign up request succeeds, carrying the returned [token].
  const factory SignupState.success({
    required AuthToken token,
    String? email,
  }) = _SignupSuccess;

  /// Emitted when the sign up request fails, carrying the typed [failure].
  const factory SignupState.failure({
    required AppException failure,
    String? email,
  }) = _SignupFailure;
}

/// {@template signup_bloc}
/// Manages the state of the sign up flow by delegating to [SignupUseCase].
/// {@endtemplate}
@injectable
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  /// {@macro signup_bloc}
  SignupBloc(this._signupUseCase) : super(const SignupState.initial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  final SignupUseCase _signupUseCase;

  /// Convenience helper that dispatches a [SignupSubmitted] event so callers
  /// can simply invoke `bloc.submit(...)`.
  void submit({
    required String email,
    required String password,
  }) {
    add(SignupSubmitted(email: email, password: password));
  }

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupState.inProgress(email: event.email));

    await handleBlocAction(
      () async {
        final emailSignup = EmailSignup(
          email: event.email,
          password: event.password,
        );

        final token = await _signupUseCase.execute(input: emailSignup);

        emit(SignupState.success(token: token, email: event.email));
      },
      onFailure: (failure) => emit(
        SignupState.failure(failure: failure, email: event.email),
      ),
    );
  }
}
