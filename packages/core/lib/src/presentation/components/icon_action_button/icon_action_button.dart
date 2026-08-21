import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'icon_action_button.freezed.dart';

/// {@template icon_action_button}
/// A circular tap target wrapping one [AppIcons] glyph — a back chevron, a
/// show/hide toggle, a dismiss.
///
/// [semanticLabel] is **required**, and it is the only thing a screen reader
/// has to go on: an icon button has no text. For a toggle, pass the label for
/// the action the tap performs and change it with the state ("Show password"
/// while hidden, "Hide password" while shown) — a static label leaves the user
/// unable to tell which way the switch is currently set.
///
/// The default [IconActionButtonThemeData.size] is 44 even when the glyph
/// inside is 22: 44pt is the minimum comfortable touch target, and a visual
/// metric should never shrink a target below it. Pad, do not scale.
/// {@endtemplate}
class IconActionButton extends StatelessWidget {
  /// {@macro icon_action_button}
  const IconActionButton({
    required this.icon,
    required this.semanticLabel,
    super.key,
    this.onPressed,
    this.theme,
  });

  /// One of the [AppIcons] constants.
  final String icon;

  /// What the tap does, phrased as an action. Required — see the class doc.
  final String semanticLabel;

  /// Invoked on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// Styling. Defaults to the nearest [IconActionButtonTheme], then to
  /// [IconActionButtonThemeData.fallback] for the ambient theme.
  final IconActionButtonThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? IconActionButtonTheme.of(context);

    return SizedBox.square(
      dimension: theme.size,
      child: Material(
        color: theme.background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          hoverColor: theme.hoverColor,
          highlightColor: theme.highlightColor,
          child: Center(
            child: AppIcon(
              icon,
              size: theme.iconSize,
              color: onPressed == null
                  ? theme.disabledIconColor
                  : theme.iconColor,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// The styling contract for [IconActionButton].
@freezed
sealed class IconActionButtonThemeData with _$IconActionButtonThemeData {
  /// Creates a fully specified icon-button style.
  factory IconActionButtonThemeData({
    required Color background,
    required Color iconColor,
    required Color disabledIconColor,
    required Color hoverColor,
    required Color highlightColor,
    // 44 spelled out, not `defaultSize`: freezed copies an `@Default`
    // expression into the generated file verbatim, so a reference to a static
    // on the class being generated emits a bare `defaultSize` that no longer
    // resolves there. `dart analyze` does not catch it — only codegen does.
    @Default(44) double size,
    @Default(22) double iconSize,
  }) = _IconActionButtonThemeData;

  /// Derives the icon-button style from the ambient theme.
  factory IconActionButtonThemeData.fallback(
    BuildContext context, {
    double? size,
    double? iconSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = ColorExtension.of(context);

    return IconActionButtonThemeData(
      // Transparent by default: these sit on a plain surface or inside a text
      // field, and a filled circle in either place reads as a second control.
      background: colors.transparentColor,
      iconColor: colorScheme.onSurface,
      disabledIconColor: colorScheme.onSurfaceVariant,
      hoverColor: colorScheme.surfaceContainerHigh,
      highlightColor: colorScheme.surfaceContainerHigh,
      size: size ?? defaultSize,
      iconSize: iconSize ?? 22,
    );
  }

  /// The minimum comfortable touch target.
  static const double defaultSize = 44;
}

/// The [InheritedWidget] that propagates an [IconActionButtonThemeData] to
/// descendant [IconActionButton]s.
class IconActionButtonTheme extends InheritedWidget {
  /// Creates an [IconActionButtonTheme] exposing [data] to its subtree.
  const IconActionButtonTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final IconActionButtonThemeData data;

  @override
  bool updateShouldNotify(IconActionButtonTheme oldWidget) =>
      data != oldWidget.data;

  /// Resolves the nearest [IconActionButtonThemeData], falling back to
  /// [IconActionButtonThemeData.fallback] when none is in scope.
  static IconActionButtonThemeData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<IconActionButtonTheme>();

    return result?.data ?? IconActionButtonThemeData.fallback(context);
  }
}
