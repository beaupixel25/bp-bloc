part of 'color_scheme.dart';

/// A [ThemeExtension] that carries the app's custom colors.
///
/// Material's [ColorScheme] (see [AppColorScheme]) only has slots for a fixed
/// set of roles. [ColorExtension] holds the extra aliases and variants the
/// design system needs but that don't fit those slots — `*Variant` tints,
/// [link], [transparentColor], and the explicit dark-mode overrides.
///
/// Register it on `ThemeData.extensions` and read it in widgets with
/// `Theme.of(context).extension<ColorExtension>()`. Being a [ThemeExtension],
/// it participates in theme animations via [lerp] and supports non-destructive
/// updates via [copyWith]. Values default to the [_SemanticColors] aliases.
@immutable
class ColorExtension extends ThemeExtension<ColorExtension> {
  /// Creates a [ColorExtension] populated from the default [_SemanticColors]
  /// aliases. This is the instance registered on the app theme.
  factory ColorExtension() {
    return const ColorExtension._(
      primaryVariant: _SemanticColors.primaryVariant,
      primaryVariantContainerColor: _SemanticColors.primaryContainer,
      primaryVariantDarkColor: _SemanticColors.primaryVariant,
      primaryVariantLightColor: _SemanticColors.primaryVariant,
      onPrimaryVariantColor: _SemanticColors.onPrimary,
      onPrimaryVariantContainerColor: _SemanticColors.onPrimary,
      transparentColor: Color(0x00000000),
      primaryContainerVariant: _SemanticColors.primaryContainerVariant,
      onPrimaryContainerVariant: _SemanticColors.onPrimaryContainerVariant,
      secondaryVariant: _SemanticColors.secondaryVariant,
      secondaryContainerVariant: _SemanticColors.secondaryContainerVariant,
      onSecondaryContainerVariant: _SemanticColors.onSecondaryContainerVariant,
      tertiaryVariant: _SemanticColors.tertiaryVariant,
      onTertiary: _SemanticColors.onTertiary,
      tertiaryContainerVariant: _SemanticColors.tertiaryContainerVariant,
      onTertiaryContainer: _SemanticColors.onTertiaryContainer,
      onTertiaryContainerVariant: _SemanticColors.onTertiaryContainerVariant,
      errorVariant: _SemanticColors.errorVariant,
      errorContainer: _SemanticColors.errorContainer,
      onErrorContainer: _SemanticColors.onErrorContainer,
      errorContainerVariant: _SemanticColors.errorContainerVariant,
      onErrorContainerVariant: _SemanticColors.onErrorContainerVariant,
      surfaceVariant: _SemanticColors.surfaceVariant,
      shadowVariant: _SemanticColors.shadowVariant,
      link: _SemanticColors.link,
      surfaceVariantDark: _SemanticColorsDark.surfaceVariant,
      onSurfaceVariantDark: _SemanticColorsDark.onSurfaceVariant,
      inverseSurfaceDark: _SemanticColorsDark.inverseSurface,
      onInverseSurfaceDark: _SemanticColorsDark.onInverseSurface,
    );
  }

  const ColorExtension._({
    required this.primaryVariant,
    required this.primaryVariantContainerColor,
    required this.primaryVariantDarkColor,
    required this.primaryVariantLightColor,
    required this.onPrimaryVariantColor,
    required this.onPrimaryVariantContainerColor,
    required this.transparentColor,
    required this.primaryContainerVariant,
    required this.onPrimaryContainerVariant,
    required this.secondaryVariant,
    required this.secondaryContainerVariant,
    required this.onSecondaryContainerVariant,
    required this.tertiaryVariant,
    required this.onTertiary,
    required this.tertiaryContainerVariant,
    required this.onTertiaryContainer,
    required this.onTertiaryContainerVariant,
    required this.errorVariant,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.errorContainerVariant,
    required this.onErrorContainerVariant,
    required this.surfaceVariant,
    required this.shadowVariant,
    required this.link,
    required this.surfaceVariantDark,
    required this.onSurfaceVariantDark,
    required this.inverseSurfaceDark,
    required this.onInverseSurfaceDark,
  });

  /// The nearest [ColorExtension], or a default-constructed one when no theme
  /// registers it.
  ///
  /// Falling back rather than throwing keeps a component usable outside a full
  /// app theme — a widget test that pumps a bare [MaterialApp], for instance.
  /// The fallback is the same palette the app theme registers, so it changes
  /// nothing visible.
  // A lookup, not a constructor: `X.of(context)` is the framework's own idiom
  // (`Theme.of`, `MediaQuery.of`) and reads as one at every call site.
  // ignore: prefer_constructors_over_static_methods
  static ColorExtension of(BuildContext context) =>
      Theme.of(context).extension<ColorExtension>() ?? ColorExtension();

  // Other custom colors not defined in the [ColorScheme].

  /// A tonal variant of the primary color.
  final Color primaryVariant;

  /// Container surface tint paired with the primary variant.
  final Color primaryVariantContainerColor;

  /// Darker shade of the primary variant.
  final Color primaryVariantDarkColor;

  /// Lighter shade of the primary variant.
  final Color primaryVariantLightColor;

  /// Foreground color used on top of [primaryVariant].
  final Color onPrimaryVariantColor;

  /// Foreground color used on the primary-variant container.
  final Color onPrimaryVariantContainerColor;

  /// A fully transparent color token.
  final Color transparentColor;

  /// A tonal variant of the primary container color.
  final Color primaryContainerVariant;

  /// Foreground color used on [primaryContainerVariant].
  final Color onPrimaryContainerVariant;

  /// A tonal variant of the secondary color.
  final Color secondaryVariant;

  /// A tonal variant of the secondary container color.
  final Color secondaryContainerVariant;

  /// Foreground color used on [secondaryContainerVariant].
  final Color onSecondaryContainerVariant;

  /// A tonal variant of the tertiary color.
  final Color tertiaryVariant;

  /// Foreground color used on top of the tertiary color.
  final Color onTertiary;

  /// A tonal variant of the tertiary container color.
  final Color tertiaryContainerVariant;

  /// Foreground color used on the tertiary container.
  final Color onTertiaryContainer;

  /// Foreground color used on [tertiaryContainerVariant].
  final Color onTertiaryContainerVariant;

  /// A tonal variant of the error color.
  final Color errorVariant;

  /// Container surface tint for error states.
  final Color errorContainer;

  /// Foreground color used on [errorContainer].
  final Color onErrorContainer;

  /// A tonal variant of the error container color.
  final Color errorContainerVariant;

  /// Foreground color used on [errorContainerVariant].
  final Color onErrorContainerVariant;

  /// A tonal variant of the surface color.
  final Color surfaceVariant;

  /// A tonal variant of the shadow color.
  final Color shadowVariant;

  /// Color used for hyperlinks and link-styled text.
  final Color link;

  /// Dark-mode override for [surfaceVariant].
  final Color surfaceVariantDark;

  /// Dark-mode override for the on-surface-variant color.
  final Color onSurfaceVariantDark;

  /// Dark-mode override for the inverse surface color.
  final Color inverseSurfaceDark;

  /// Dark-mode override for the on-inverse-surface color.
  final Color onInverseSurfaceDark;

  /// Returns a copy of this extension with the given colors replaced.
  ///
  /// Any argument left `null` keeps its current value, so callers only override
  /// the colors they intend to change.
  @override
  ThemeExtension<ColorExtension> copyWith({
    Color? primaryVariant,
    Color? primaryVariantContainerColor,
    Color? primaryVariantDarkColor,
    Color? primaryVariantLightColor,
    Color? onPrimaryVariantColor,
    Color? onPrimaryVariantContainerColor,
    Color? transparentColor,
    Color? primaryContainerVariant,
    Color? onPrimaryContainerVariant,
    Color? secondaryVariant,
    Color? secondaryContainerVariant,
    Color? onSecondaryContainerVariant,
    Color? tertiaryVariant,
    Color? onTertiary,
    Color? tertiaryContainerVariant,
    Color? onTertiaryContainer,
    Color? onTertiaryContainerVariant,
    Color? errorVariant,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? errorContainerVariant,
    Color? onErrorContainerVariant,
    Color? surfaceVariant,
    Color? shadowVariant,
    Color? link,
    Color? surfaceVariantDark,
    Color? onSurfaceVariantDark,
    Color? inverseSurfaceDark,
    Color? onInverseSurfaceDark,
  }) {
    return ColorExtension._(
      primaryVariant: primaryVariant ?? this.primaryVariant,
      primaryVariantContainerColor:
          primaryVariantContainerColor ?? this.primaryVariantContainerColor,
      primaryVariantDarkColor:
          primaryVariantDarkColor ?? this.primaryVariantDarkColor,
      primaryVariantLightColor:
          primaryVariantLightColor ?? this.primaryVariantLightColor,
      onPrimaryVariantColor:
          onPrimaryVariantColor ?? this.onPrimaryVariantColor,
      onPrimaryVariantContainerColor:
          onPrimaryVariantContainerColor ?? this.onPrimaryVariantContainerColor,
      transparentColor: transparentColor ?? this.transparentColor,
      primaryContainerVariant:
          primaryContainerVariant ?? this.primaryContainerVariant,
      onPrimaryContainerVariant:
          onPrimaryContainerVariant ?? this.onPrimaryContainerVariant,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      secondaryContainerVariant:
          secondaryContainerVariant ?? this.secondaryContainerVariant,
      onSecondaryContainerVariant:
          onSecondaryContainerVariant ?? this.onSecondaryContainerVariant,
      tertiaryVariant: tertiaryVariant ?? this.tertiaryVariant,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainerVariant:
          tertiaryContainerVariant ?? this.tertiaryContainerVariant,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      onTertiaryContainerVariant:
          onTertiaryContainerVariant ?? this.onTertiaryContainerVariant,
      errorVariant: errorVariant ?? this.errorVariant,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      errorContainerVariant:
          errorContainerVariant ?? this.errorContainerVariant,
      onErrorContainerVariant:
          onErrorContainerVariant ?? this.onErrorContainerVariant,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      shadowVariant: shadowVariant ?? this.shadowVariant,
      link: link ?? this.link,
      surfaceVariantDark: surfaceVariantDark ?? this.surfaceVariantDark,
      onSurfaceVariantDark: onSurfaceVariantDark ?? this.onSurfaceVariantDark,
      inverseSurfaceDark: inverseSurfaceDark ?? this.inverseSurfaceDark,
      onInverseSurfaceDark: onInverseSurfaceDark ?? this.onInverseSurfaceDark,
    );
  }

  /// Linearly interpolates between this extension and [other] by [t].
  ///
  /// Called by the framework to animate color changes when the theme
  /// transitions. Returns `this` unchanged if [other] is not a
  /// [ColorExtension].
  @override
  ThemeExtension<ColorExtension> lerp(
    covariant ThemeExtension<ColorExtension>? other,
    double t,
  ) {
    if (other is! ColorExtension) return this;
    return ColorExtension._(
      primaryVariant: Color.lerp(
        primaryVariant,
        other.primaryVariant,
        t,
      )!,
      primaryVariantContainerColor: Color.lerp(
        primaryVariantContainerColor,
        other.primaryVariantContainerColor,
        t,
      )!,
      primaryVariantDarkColor: Color.lerp(
        primaryVariantDarkColor,
        other.primaryVariantDarkColor,
        t,
      )!,
      primaryVariantLightColor: Color.lerp(
        primaryVariantLightColor,
        other.primaryVariantLightColor,
        t,
      )!,
      onPrimaryVariantColor: Color.lerp(
        onPrimaryVariantColor,
        other.onPrimaryVariantColor,
        t,
      )!,
      onPrimaryVariantContainerColor: Color.lerp(
        onPrimaryVariantContainerColor,
        other.onPrimaryVariantContainerColor,
        t,
      )!,
      transparentColor: Color.lerp(
        transparentColor,
        other.transparentColor,
        t,
      )!,
      primaryContainerVariant: Color.lerp(
        primaryContainerVariant,
        other.primaryContainerVariant,
        t,
      )!,
      onPrimaryContainerVariant: Color.lerp(
        onPrimaryContainerVariant,
        other.onPrimaryContainerVariant,
        t,
      )!,
      secondaryVariant: Color.lerp(
        secondaryVariant,
        other.secondaryVariant,
        t,
      )!,
      secondaryContainerVariant: Color.lerp(
        secondaryContainerVariant,
        other.secondaryContainerVariant,
        t,
      )!,
      onSecondaryContainerVariant: Color.lerp(
        onSecondaryContainerVariant,
        other.onSecondaryContainerVariant,
        t,
      )!,
      tertiaryVariant: Color.lerp(
        tertiaryVariant,
        other.tertiaryVariant,
        t,
      )!,
      onTertiary: Color.lerp(
        onTertiary,
        other.onTertiary,
        t,
      )!,
      tertiaryContainerVariant: Color.lerp(
        tertiaryContainerVariant,
        other.tertiaryContainerVariant,
        t,
      )!,
      onTertiaryContainer: Color.lerp(
        onTertiaryContainer,
        other.onTertiaryContainer,
        t,
      )!,
      onTertiaryContainerVariant: Color.lerp(
        onTertiaryContainerVariant,
        other.onTertiaryContainerVariant,
        t,
      )!,
      errorVariant: Color.lerp(
        errorVariant,
        other.errorVariant,
        t,
      )!,
      errorContainer: Color.lerp(
        errorContainer,
        other.errorContainer,
        t,
      )!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      errorContainerVariant: Color.lerp(
        errorContainerVariant,
        other.errorContainerVariant,
        t,
      )!,
      onErrorContainerVariant: Color.lerp(
        onErrorContainerVariant,
        other.onErrorContainerVariant,
        t,
      )!,
      surfaceVariant: Color.lerp(
        surfaceVariant,
        other.surfaceVariant,
        t,
      )!,
      shadowVariant: Color.lerp(
        shadowVariant,
        other.shadowVariant,
        t,
      )!,
      link: Color.lerp(
        link,
        other.link,
        t,
      )!,
      surfaceVariantDark: Color.lerp(
        surfaceVariantDark,
        other.surfaceVariantDark,
        t,
      )!,
      onSurfaceVariantDark: Color.lerp(
        onSurfaceVariantDark,
        other.onSurfaceVariantDark,
        t,
      )!,
      inverseSurfaceDark: Color.lerp(
        inverseSurfaceDark,
        other.inverseSurfaceDark,
        t,
      )!,
      onInverseSurfaceDark: Color.lerp(
        onInverseSurfaceDark,
        other.onInverseSurfaceDark,
        t,
      )!,
    );
  }
}
