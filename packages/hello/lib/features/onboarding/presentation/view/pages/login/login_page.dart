import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hello/common/error/app_error_messages.dart';
import 'package:hello/features/onboarding/domain/validation/credential_validator.dart';
import 'package:hello/features/onboarding/presentation/routing/onboarding_routes.dart';
import 'package:hello/features/onboarding/presentation/state/credential_draft_cubit.dart';
import 'package:hello/features/onboarding/presentation/view/pages/login/login_bloc.dart';
import 'package:hello/features/onboarding/presentation/view/widgets/onboarding_scaffold.dart';
import 'package:hello/inject.dart';
import 'package:hello/l10n/l10n.dart';
import 'package:hello/routing/routes.dart';

/// {@template login_page}
/// Email and password, built from `core`'s form components: a
/// [LabeledTextField], a [PasswordField], and a "Log in" [PillButton]
/// pinned under them, with a [PromptLink] to sign up instead.
///
/// Two pieces of state, with deliberately different lifetimes: the
/// *outcome* of submitting is [LoginBloc]'s and is transient — the bloc is
/// resolved per page and closed on dispose — while what the user *typed*,
/// plus the last error shown, lives in [CredentialDraftCubit] and outlives
/// this page, so going back and returning costs nothing, and neither does
/// switching to sign up.
/// {@endtemplate}
class LoginPage extends StatefulWidget {
  /// {@macro login_page}
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Resolves the [LoginBloc] at construction time. An instance can be
  /// injected directly (e.g. in tests); otherwise it comes from the
  /// [injector].
  _LoginPageState({LoginBloc? bloc}) : _bloc = bloc ?? injector<LoginBloc>();

  final LoginBloc _bloc;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    // Seeded from the draft, which outlives this page: returning to the form
    // has to find the fields as they were. `read` takes no dependency on the
    // cubit, so it is safe this early.
    final draft = context.read<CredentialDraftCubit>().state;
    _emailController = TextEditingController(text: draft.email);
    _passwordController = TextEditingController(text: draft.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider<LoginBloc>.value(
      value: _bloc,
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          final draftCubit = context.read<CredentialDraftCubit>();
          switch (state) {
            case LoginFailure(:final failure):
              draftCubit.setError(
                failure.toUserMessage(AppErrorMessages(context.l10n)),
              );
            case LoginSuccess():
              // A password must not outlive the session that typed it — see
              // CredentialDraftCubit.clearCredentials.
              draftCubit.clearCredentials();
              // Sign-up and login both authenticate, so both land on /main.
              const HomeRoute().go(context);
            case LoginInitial():
            case LoginInProgress():
              break;
          }
        },
        builder: (context, state) {
          final isBusy = state is LoginInProgress;
          final draft = context.watch<CredentialDraftCubit>().state;
          final draftCubit = context.read<CredentialDraftCubit>();

          final emailError = CredentialValidator.email(draft.email);
          final passwordError = CredentialValidator.password(draft.password);
          final canSubmit = emailError == null && passwordError == null;

          // The single choke point for submitting: also reached from the
          // password field's keyboard action, so the busy guard has to live
          // here rather than at each call site — `PasswordField` has no
          // `enabled` parameter to lock it during a submit the way the email
          // field does.
          void onSubmit() {
            if (isBusy) return;
            final formError = emailError ?? passwordError;
            if (formError != null) {
              draftCubit.setError(formError);
              return;
            }
            _bloc.submit(
              email: draft.email.trim(),
              password: draft.password,
            );
          }

          // The error clears on the next keystroke in either field — the fix
          // is often the other one — and on the way out, because the draft
          // (and its error) is shared with sign up: leaving without clearing
          // it would greet that form with a stale login failure.
          void onEmailChanged(String value) {
            draftCubit
              ..clearError()
              ..setEmail(value);
          }

          void onPasswordChanged(String value) {
            draftCubit
              ..clearError()
              ..setPassword(value);
          }

          void goToSignup() {
            draftCubit.clearError();
            unawaited(const SignupRoute().push<void>(context));
          }

          return OnboardingScaffold(
            title: 'Log in',
            subtitle: 'Welcome back. Enter your details to continue.',
            onBack: () {
              draftCubit.clearError();
              Navigator.of(context).pop();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  enabled: !isBusy,
                  onChanged: onEmailChanged,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _passwordController,
                  labelText: 'Password',
                  showPasswordLabel: l10n.onboardingShowPassword,
                  hidePasswordLabel: l10n.onboardingHidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onChanged: onPasswordChanged,
                  onSubmitted: (_) => onSubmit(),
                ),
                if (draft.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  FormMessage(message: draft.errorMessage!),
                ],
                const SizedBox(height: 24),
                PillButton(
                  label: 'Log in',
                  isBusy: isBusy,
                  // Dimmed, not disabled: tapping it still validates, so a
                  // person is told what is missing rather than tapping a
                  // dead control.
                  isDimmed: !canSubmit,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: 12),
                PromptLink(
                  prompt: "Don't have an account?",
                  action: 'Sign up',
                  onPressed: goToSignup,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
