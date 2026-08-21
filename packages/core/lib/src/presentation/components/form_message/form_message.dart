import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_message.freezed.dart';

/// What a [FormMessage] is telling the user.
enum FormMessageTone {
  /// Something needs fixing before the form can be submitted.
  error,

  /// Something worked.
  success,
}

/// {@template form_message}
/// A block of feedback attached to a form: an icon, then a sentence.
///
/// **The icon is not decoration.** Colour never carries the meaning on its own
/// — a red panel is invisible to a red-blind reader and to anyone glancing at a
/// screen in sunlight. Every tone therefore has a mandatory glyph, and the
/// widget has no way to render without one.
///
/// The message is announced when it appears — it is a semantic live region —
/// so a screen-reader user learns about a validation failure without
/// re-traversing the form.
///
/// Write the [message] to name the fix, not the failure: "That email doesn't
/// look quite right — mind checking it?", never "Invalid email".
/// {@endtemplate}
class FormMessage extends StatelessWidget {
  /// {@macro form_message}
  const FormMessage({
    required this.message,
    super.key,
    this.tone = FormMessageTone.error,
    this.theme,
  });

  /// The sentence shown beside the icon.
  final String message;

  /// Which feedback this is. Drives the default colours and glyph.
  final FormMessageTone tone;

  /// Styling. Defaults to the nearest [FormMessageTheme], then to
  /// [FormMessageThemeData.fallback] for [tone].
  final FormMessageThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? FormMessageTheme.of(context, tone: tone);

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(theme.radius),
        ),
        child: Padding(
          padding: theme.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Nudged down so the glyph optically centres on the first line
                // of text rather than on its ascender.
                padding: EdgeInsets.only(top: theme.iconBaselineOffset),
                child: AppIcon(
                  theme.icon,
                  size: theme.iconSize,
                  color: theme.foreground,
                ),
              ),
              SizedBox(width: theme.iconGap),
              Expanded(
                child: Text(message, style: theme.messageStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The styling contract for [FormMessage].
@freezed
sealed class FormMessageThemeData with _$FormMessageThemeData {
  /// Creates a fully specified message style.
  factory FormMessageThemeData({
    required Color background,
    required Color foreground,
    required TextStyle messageStyle,

    /// One of the [AppIcons] constants. Required, and there is deliberately no
    /// null path: a tone that renders as colour alone is unreadable to a
    /// red-blind user, so the component cannot express one.
    required String icon,
    required double radius,
    required EdgeInsets padding,
    @Default(16) double iconSize,
    @Default(9) double iconGap,
    @Default(3) double iconBaselineOffset,
  }) = _FormMessageThemeData;

  /// Derives the message style for [tone] from the ambient theme.
  factory FormMessageThemeData.fallback(
    BuildContext context, {
    FormMessageTone tone = FormMessageTone.error,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = ColorExtension.of(context);
    final dimensions = DimensionExtension.of(context);

    final (Color background, Color foreground, String icon) = switch (tone) {
      FormMessageTone.error => (
          colors.errorContainer,
          colors.onErrorContainer,
          AppIcons.alertTriangle,
        ),
      FormMessageTone.success => (
          colorScheme.tertiaryContainer,
          colors.onTertiaryContainer,
          AppIcons.check,
        ),
    };

    return FormMessageThemeData(
      background: background,
      foreground: foreground,
      icon: icon,
      messageStyle: theme.textTheme.bodyMedium!.copyWith(
        color: foreground,
        fontWeight: FontWeight.w500,
      ),
      radius: dimensions.radiusMd,
      padding: EdgeInsets.symmetric(
        // Two past the 12 step: the glyph column sits against a rounded corner
        // and reads as cramped on the token value exactly.
        horizontal: dimensions.space12 + 2,
        vertical: dimensions.space12,
      ),
    );
  }
}

/// The [InheritedWidget] that propagates a [FormMessageThemeData] to descendant
/// [FormMessage]s.
class FormMessageTheme extends InheritedWidget {
  /// Creates a [FormMessageTheme] exposing [data] to its subtree.
  const FormMessageTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final FormMessageThemeData data;

  @override
  bool updateShouldNotify(FormMessageTheme oldWidget) => data != oldWidget.data;

  /// Resolves the nearest [FormMessageThemeData], falling back to
  /// [FormMessageThemeData.fallback] for [tone] when none is in scope.
  ///
  /// An ancestor override wins over [tone], because an override is a deliberate
  /// statement about this subtree — so scope one to a subtree whose messages
  /// share a tone, not to a whole form that shows both.
  static FormMessageThemeData of(
    BuildContext context, {
    FormMessageTone tone = FormMessageTone.error,
  }) {
    final result =
        context.dependOnInheritedWidgetOfExactType<FormMessageTheme>();

    return result?.data ?? FormMessageThemeData.fallback(context, tone: tone);
  }
}
