import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// {@template password_field}
/// A [LabeledTextField] that masks its content, with a show/hide toggle pinned
/// inside it and an optional strength meter beneath.
///
/// Both authentication forms use it, so the toggle's accessible label — which
/// has to change with the state, not describe the icon — is written once here
/// instead of once per page.
///
/// [showPasswordLabel] and [hidePasswordLabel] are required rather than
/// defaulted, because `core` ships no UI strings: an English default here
/// would be a localization bug that ships silently, and requiring them makes
/// it a compile error in an app that forgot to translate.
/// {@endtemplate}
class PasswordField extends StatefulWidget {
  /// {@macro password_field}
  const PasswordField({
    required this.controller,
    required this.labelText,
    required this.showPasswordLabel,
    required this.hidePasswordLabel,
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.showStrength = false,
  });

  /// Holds the typed password.
  final TextEditingController controller;

  /// The caption above the field.
  final String labelText;

  /// Announced for the toggle while the password is hidden — the action the
  /// tap performs, e.g. "Show password".
  final String showPasswordLabel;

  /// Announced for the toggle while the password is shown, e.g. "Hide
  /// password".
  final String hidePasswordLabel;

  /// An example, never the only label.
  final String? hintText;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Autofill hints, e.g. `[AutofillHints.newPassword]`.
  final List<String>? autofillHints;

  /// Whether to draw a [PasswordStrengthMeter] under the field. Sign-up only:
  /// scoring a password someone already has is pointless advice, and a meter
  /// under a log-in field reads as a judgement of a password they cannot
  /// change here.
  final bool showStrength;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return LabeledTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      obscureText: !_isVisible,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      trailing: IconActionButton(
        icon: _isVisible ? AppIcons.eyeOff : AppIcons.eye,
        // Names the action the tap performs, and flips with the state — a
        // fixed "Toggle password visibility" leaves a screen-reader user
        // unable to tell which way it is currently set.
        semanticLabel: _isVisible
            ? widget.hidePasswordLabel
            : widget.showPasswordLabel,
        // Slightly under the 44 default so the circle clears the field's
        // 52pt inner height without touching the border.
        theme: IconActionButtonThemeData.fallback(context, size: 42),
        onPressed: () => setState(() => _isVisible = !_isVisible),
      ),
      footer: widget.showStrength
          ? ValueListenableBuilder<TextEditingValue>(
              // Listens to the controller rather than rebuilding from
              // onChanged, so the meter is correct after a paste, an autofill
              // or a programmatic clear — none of which fire onChanged.
              valueListenable: widget.controller,
              builder: (context, value, _) => PasswordStrengthMeter(
                viewModel: PasswordStrengthMeterViewModel.evaluate(value.text),
              ),
            )
          : null,
    );
  }
}
