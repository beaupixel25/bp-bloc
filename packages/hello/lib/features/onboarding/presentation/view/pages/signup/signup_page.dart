import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hello/common/error/app_error_messages.dart';
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';
import 'package:hello/features/onboarding/domain/use_cases/signup_uc.dart';
import 'package:hello/features/onboarding/domain/validation/credential_validator.dart';
import 'package:hello/features/onboarding/presentation/routing/onboarding_routes.dart';
import 'package:hello/features/onboarding/presentation/state/credential_draft_cubit.dart';
import 'package:hello/features/onboarding/presentation/view/widgets/onboarding_scaffold.dart';
import 'package:hello/inject.dart';
import 'package:hello/l10n/l10n.dart';
import 'package:hello/routing/routes.dart';
import 'package:injectable/injectable.dart';

part 'signup_bloc.dart';
part 'signup_page.freezed.dart';

/// {@template signup_page}
/// Email and password, built from `core`'s form components: a
/// [LabeledTextField], a [PasswordField] with its strength meter switched
/// on, and a "Create account" [PillButton] pinned under them, with a
/// [PromptLink] to log in instead.
///
/// See `LoginPage` for why the typed values and the last error live in
/// [CredentialDraftCubit] rather than in [SignupBloc]'s own state.
/// {@endtemplate}
class SignupPage extends StatefulWidget {
  /// {@macro signup_page}
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  /// Resolves the [SignupBloc] at construction time. An instance can be
  /// injected directly (e.g. in tests); otherwise it comes from the
  /// [injector].
  _SignupPageState({SignupBloc? bloc}) : _bloc = bloc ?? injector<SignupBloc>();

  final SignupBloc _bloc;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    // Seeded from the draft — see LoginPage.
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

    return BlocProvider<SignupBloc>.value(
      value: _bloc,
      child: BlocConsumer<SignupBloc, SignupState>(
        listener: (context, state) {
          final draftCubit = context.read<CredentialDraftCubit>();
          switch (state) {
            case _SignupFailure(:final failure):
              draftCubit.setError(
                failure.toUserMessage(AppErrorMessages(context.l10n)),
              );
            case _SignupSuccess():
              // A password must not outlive the session that typed it — see
              // CredentialDraftCubit.clearCredentials.
              draftCubit.clearCredentials();
              // Sign-up authenticates too, so it lands on /main directly.
              const HomeRoute().go(context);
            case _SignupInitial():
            case _SignupInProgress():
              break;
          }
        },
        builder: (context, state) {
          final isBusy = state is _SignupInProgress;
          final draft = context.watch<CredentialDraftCubit>().state;
          final draftCubit = context.read<CredentialDraftCubit>();

          final emailError = CredentialValidator.email(draft.email);
          final passwordError = CredentialValidator.password(draft.password);
          final canSubmit = emailError == null && passwordError == null;

          // The single choke point for submitting — see LoginPage for why
          // the busy guard lives here rather than at each call site.
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

          // See LoginPage for why the error clears on every keystroke and on
          // the way out: the draft is shared, so an uncleared error would
          // otherwise greet whichever form the user opens next.
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

          void goToLogin() {
            draftCubit.clearError();
            unawaited(const LoginRoute().push<void>(context));
          }

          return OnboardingScaffold(
            title: 'Create account',
            subtitle: "Let's get you set up in a minute.",
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
                  labelText: 'Create a password',
                  showPasswordLabel: l10n.onboardingShowPassword,
                  hidePasswordLabel: l10n.onboardingHidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  // Scoring a password someone already has is pointless
                  // advice — only sign-up shows the meter.
                  showStrength: true,
                  onChanged: onPasswordChanged,
                  onSubmitted: (_) => onSubmit(),
                ),
                if (draft.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  FormMessage(message: draft.errorMessage!),
                ],
                const SizedBox(height: 24),
                PillButton(
                  label: 'Create account',
                  isBusy: isBusy,
                  // Dimmed, not disabled — see LoginPage.
                  isDimmed: !canSubmit,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: 12),
                PromptLink(
                  prompt: 'Already have an account?',
                  action: 'Log in',
                  onPressed: goToLogin,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
