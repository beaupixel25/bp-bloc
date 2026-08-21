import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt_link.freezed.dart';

/// {@template prompt_link}
/// A lead-in sentence with a tappable action at the end of it — "Already have
/// an account? **Log in**".
///
/// Two details are contractual and are what an inline `TextSpan` with a
/// `TapGestureRecognizer` gets wrong:
///
/// * **The whole line is the tap target.** An inline link at body size is well
///   under the minimum touch target, and a two-word action is a hard thing to
///   hit. [prompt] included, the row is comfortably tappable.
/// * **It announces once, as one button.** The prompt and the action are a
///   single sentence; exposing them as two spans makes a screen reader offer
///   two controls, only one of which does anything.
///
/// Write [action] as the thing that happens — "Log in", not "here".
/// {@endtemplate}
class PromptLink extends StatelessWidget {
  /// {@macro prompt_link}
  const PromptLink({
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
    this.theme,
  });

  /// The plain lead-in. Write it without a trailing space — this widget puts
  /// exactly one between the prompt and [action], and trims whatever it is
  /// given so a caller that adds its own does not produce two.
  ///
  /// It used to be the caller's job to remember the space. Every call site
  /// forgot, and the line rendered as `Already have an account?Log in`.
  final String prompt;

  /// The tappable part.
  final String action;

  /// Invoked when the line is tapped.
  final VoidCallback onPressed;

  /// Styling. Defaults to the nearest [PromptLinkTheme], then to
  /// [PromptLinkThemeData.fallback] for the ambient theme.
  final PromptLinkThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? PromptLinkTheme.of(context);
    final lead = prompt.trimRight();

    return Semantics(
      button: true,
      label: '$lead $action',
      child: ExcludeSemantics(
        // The Semantics above already announces the whole line; letting the
        // spans announce themselves too reads it twice.
        child: GestureDetector(
          onTap: onPressed,
          // The whole line is the target, not just the coloured span.
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: theme.padding,
            child: Text.rich(
              TextSpan(
                text: '$lead ',
                children: [
                  TextSpan(text: action, style: theme.actionStyle),
                ],
              ),
              textAlign: theme.textAlign,
              style: theme.promptStyle,
            ),
          ),
        ),
      ),
    );
  }
}

/// The styling contract for [PromptLink].
@freezed
sealed class PromptLinkThemeData with _$PromptLinkThemeData {
  /// Creates a fully specified prompt style.
  factory PromptLinkThemeData({
    required TextStyle promptStyle,
    required TextStyle actionStyle,
    required EdgeInsets padding,
    @Default(TextAlign.center) TextAlign textAlign,
  }) = _PromptLinkThemeData;

  /// Derives the prompt style from the ambient theme.
  factory PromptLinkThemeData.fallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = ColorExtension.of(context);
    final dimensions = DimensionExtension.of(context);

    final promptStyle = theme.textTheme.bodyMedium!.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return PromptLinkThemeData(
      promptStyle: promptStyle,
      // `link`, not `primary`: the action is a navigation affordance, and a
      // primary-coloured run of text next to a primary-filled button reads as
      // a second call to action competing with it.
      actionStyle: promptStyle.copyWith(
        color: colors.link,
        fontWeight: FontWeight.w600,
      ),
      // Vertical padding is what lifts the line to a comfortable target — the
      // text itself is roughly 20pt tall.
      padding: EdgeInsets.symmetric(vertical: dimensions.space12),
    );
  }
}

/// The [InheritedWidget] that propagates a [PromptLinkThemeData] to descendant
/// [PromptLink]s.
class PromptLinkTheme extends InheritedWidget {
  /// Creates a [PromptLinkTheme] exposing [data] to its subtree.
  const PromptLinkTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final PromptLinkThemeData data;

  @override
  bool updateShouldNotify(PromptLinkTheme oldWidget) => data != oldWidget.data;

  /// Resolves the nearest [PromptLinkThemeData], falling back to
  /// [PromptLinkThemeData.fallback] when none is in scope.
  static PromptLinkThemeData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<PromptLinkTheme>();

    return result?.data ?? PromptLinkThemeData.fallback(context);
  }
}
