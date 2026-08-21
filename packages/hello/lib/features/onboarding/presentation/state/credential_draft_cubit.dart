import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// What the user has typed into the onboarding forms so far, plus any error
/// surfaced by the last submit attempt.
class CredentialDraft {
  /// Creates a draft. Both fields default to empty — a fresh install.
  const CredentialDraft({
    this.email = '',
    this.password = '',
    this.errorMessage,
  });

  /// The email as typed, untrimmed. Trimming happens at submit.
  final String email;

  /// The password as typed.
  final String password;

  /// The message from the last failed submit, or null between attempts.
  final String? errorMessage;

  /// Returns a copy with [email] or [password] replaced. Any existing
  /// [errorMessage] is preserved — use [CredentialDraftCubit.setError] or
  /// [CredentialDraftCubit.clearError] to change it.
  CredentialDraft copyWith({String? email, String? password}) =>
      CredentialDraft(
        email: email ?? this.email,
        password: password ?? this.password,
        errorMessage: errorMessage,
      );
}

/// {@template credential_draft_cubit}
/// The email, password and error shared by the log-in and sign-up forms.
///
/// A singleton for the app's lifetime — the BLoC counterpart of Riverpod's
/// `keepAlive` — provided above the router rather than per page, for two
/// reasons that are really the same reason:
///
/// * **Back must not throw away what was typed.** Going back to landing and
///   returning to a form has to find the fields as they were. The pages are
///   routes, so they are disposed on pop; the draft outliving them is what
///   makes that work.
/// * **Switching form must not either.** Someone who types their email on
///   log in and then realises they need an account should not retype it on
///   sign up.
///
/// The error lives here too, rather than in each page's own bloc, because a
/// route pop does not reliably dispose that bloc before the next visit
/// builds — a stale error would otherwise greet the user as a fresh
/// failure. [clearError] is how a page disowns it instead.
///
/// Nothing persists this. It is in memory for the life of the process,
/// which is the whole point: a password must not outlive the session that
/// typed it.
/// {@endtemplate}
@lazySingleton
class CredentialDraftCubit extends Cubit<CredentialDraft> {
  /// {@macro credential_draft_cubit}
  CredentialDraftCubit() : super(const CredentialDraft());

  /// Records the email as typed.
  void setEmail(String email) => emit(state.copyWith(email: email));

  /// Records the password as typed.
  void setPassword(String password) => emit(state.copyWith(password: password));

  /// Records the message from a failed submit.
  void setError(String message) => emit(
    CredentialDraft(
      email: state.email,
      password: state.password,
      errorMessage: message,
    ),
  );

  /// Drops the error without touching the draft. Call when a page that
  /// showed it is leaving, so the next visit starts clean.
  void clearError() =>
      emit(CredentialDraft(email: state.email, password: state.password));

  /// Drops the email, password, and any error — the whole draft, not just
  /// the error [clearError] disowns.
  ///
  /// Call this from a successful submit, never from a route pop: the reason
  /// this cubit is a singleton is so back-navigation finds the draft as it
  /// was, but success routes forward, past the flow entirely, so nothing is
  /// lost by clearing here. A password must not outlive the session that
  /// typed it.
  void clearCredentials() => emit(const CredentialDraft());
}
