import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meter.freezed.dart';

/// {@template password_strength_meter}
/// A hairline track that fills and warms as a password gets stronger, with a
/// one-word caption beside it.
///
/// Drive it from [PasswordStrengthMeterViewModel.evaluate]; that factory owns
/// the scoring and this widget owns only the drawing.
///
/// The fill and the colour both animate over
/// [PasswordStrengthMeterThemeData.duration], so a keystroke that changes the
/// score reads as the bar growing rather than jumping. The caption is announced
/// as a live region — a screen-reader user hears "Good" when it changes without
/// having to go looking for it.
/// {@endtemplate}
class PasswordStrengthMeter extends StatelessWidget {
  /// {@macro password_strength_meter}
  const PasswordStrengthMeter({
    required this.viewModel,
    super.key,
    this.theme,
  });

  /// The scored state to draw.
  final PasswordStrengthMeterViewModel viewModel;

  /// Styling. Defaults to the nearest [PasswordStrengthMeterTheme], then to
  /// [PasswordStrengthMeterThemeData.fallback] for the ambient theme.
  final PasswordStrengthMeterThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? PasswordStrengthMeterTheme.of(context);
    final fill = theme.fillFor(viewModel.strength);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.trackHeight),
            child: SizedBox(
              height: theme.trackHeight,
              child: ColoredBox(
                color: theme.trackColor,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    widthFactor: viewModel.fraction,
                    duration: theme.duration,
                    curve: theme.curve,
                    child: AnimatedContainer(
                      duration: theme.duration,
                      curve: theme.curve,
                      color: fill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: theme.labelGap),
        SizedBox(
          // Fixed so the track does not resize as the caption changes from
          // "Okay" to "Strong" — a bar that shortens when the password gets
          // better is exactly backwards.
          width: theme.labelWidth,
          child: Semantics(
            liveRegion: true,
            child: Text(
              viewModel.label.toUpperCase(),
              style: theme.labelStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// The styling contract for [PasswordStrengthMeter].
@freezed
sealed class PasswordStrengthMeterThemeData
    with _$PasswordStrengthMeterThemeData {
  /// Creates a fully specified meter style.
  factory PasswordStrengthMeterThemeData({
    required Color trackColor,
    required Color shortColor,
    required Color okayColor,
    required Color goodColor,
    required Color strongColor,
    required TextStyle labelStyle,
    @Default(4) double trackHeight,
    @Default(8) double labelGap,
    @Default(58) double labelWidth,
    @Default(Duration(milliseconds: 240)) Duration duration,
    @Default(Cubic(0.22, 0.61, 0.36, 1)) Curve curve,
  }) = _PasswordStrengthMeterThemeData;

  const PasswordStrengthMeterThemeData._();

  /// Derives the meter style from the ambient theme.
  factory PasswordStrengthMeterThemeData.fallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = ColorExtension.of(context);

    return PasswordStrengthMeterThemeData(
      trackColor: colorScheme.outline,
      // The ramp climbs variant -> variant -> primary -> tertiary. It
      // deliberately does NOT start at `error`: a short password is not a
      // mistake, and painting it like one scolds someone still typing.
      shortColor: colors.primaryVariant,
      okayColor: colors.primaryVariant,
      goodColor: colorScheme.primary,
      strongColor: colorScheme.tertiary,
      labelStyle: theme.textTheme.labelSmall!.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  /// The bar colour for [strength]. Empty keeps the track colour so nothing
  /// appears to be filled.
  Color fillFor(PasswordStrength strength) => switch (strength) {
        PasswordStrength.empty => trackColor,
        PasswordStrength.short => shortColor,
        PasswordStrength.okay => okayColor,
        PasswordStrength.good => goodColor,
        PasswordStrength.strong => strongColor,
      };
}

/// The [InheritedWidget] that propagates a [PasswordStrengthMeterThemeData] to
/// descendant [PasswordStrengthMeter]s.
class PasswordStrengthMeterTheme extends InheritedWidget {
  /// Creates a [PasswordStrengthMeterTheme] exposing [data] to its subtree.
  const PasswordStrengthMeterTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final PasswordStrengthMeterThemeData data;

  @override
  bool updateShouldNotify(PasswordStrengthMeterTheme oldWidget) =>
      data != oldWidget.data;

  /// Resolves the nearest [PasswordStrengthMeterThemeData], falling back to
  /// [PasswordStrengthMeterThemeData.fallback] when none is in scope.
  static PasswordStrengthMeterThemeData of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<PasswordStrengthMeterTheme>();

    return result?.data ?? PasswordStrengthMeterThemeData.fallback(context);
  }
}
