import 'package:flutter/material.dart';
part 'color_palette.dart';
part 'color_extension.dart';

/// The application's Material [ColorScheme].
///
/// [AppColorScheme] is the single source of truth for the semantic colors that
/// Material widgets consume (`primary`, `surface`, `error`, and so on). It is
/// assembled from the raw design tokens in [_ColorPalette] and the semantic
/// aliases in [_SemanticColors], which are stitched in via `part` files.
///
/// Colors that don't map onto a standard Material [ColorScheme] slot (custom
/// variants, links, dark-mode overrides) live in [ColorExtension] instead.
///
/// Prefer the [AppColorScheme.light] and [AppColorScheme.dark] factories over
/// the private constructor; each parameter falls back to the corresponding
/// [_SemanticColors] token, so overrides are opt-in.
class AppColorScheme extends ColorScheme {
  const AppColorScheme._({
    required super.brightness,
    required super.primary,
    required super.onPrimary,
    required super.primaryContainer,
    required super.onPrimaryContainer,
    required super.secondary,
    required super.onSecondary,
    required super.secondaryContainer,
    required super.onSecondaryContainer,
    required super.onSecondaryFixed,
    required super.tertiary,
    required super.onTertiary,
    required super.tertiaryContainer,
    required super.onTertiaryContainer,
    required super.error,
    required super.onError,
    required super.errorContainer,
    required super.onErrorContainer,
    required super.surface,
    required super.onSurface,
    required super.onSurfaceVariant,
    required super.outline,
    required super.surfaceDim,
    required super.surfaceBright,
    required super.surfaceContainerLowest,
    required super.surfaceContainerLow,
    required super.surfaceContainer,
    required super.surfaceContainerHigh,
    required super.surfaceContainerHighest,
    required super.outlineVariant,
    required super.shadow,
    super.inversePrimary,
    super.inverseSurface,
    super.onInverseSurface,
    super.onPrimaryFixedVariant,
    super.onSecondaryFixedVariant,
    super.onTertiaryFixedVariant,
    super.scrim,
    super.surfaceTint,
    super.primaryFixed,
    super.primaryFixedDim,
    super.tertiaryFixed,
    super.tertiaryFixedDim,
    super.onPrimaryFixed,
    super.secondaryFixed,
    super.secondaryFixedDim,
    super.onTertiaryFixed,
  });

  /// Builds the light [AppColorScheme].
  ///
  /// Every parameter is optional and defaults to the matching [_SemanticColors]
  /// token, so callers only pass the slots they want to override.
  factory AppColorScheme.light({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? primaryContainerColor,
    Color? onPrimaryContainerColor,
    Color? secondaryColor,
    Color? onSecondaryColor,
    Color? secondaryContainerColor,
    Color? onSecondaryContainerColor,
    Color? onSecondaryFixedColor,
    Color? tertiaryColor,
    Color? onTertiaryColor,
    Color? tertiaryContainerColor,
    Color? onTertiaryContainerColor,
    Color? errorColor,
    Color? onErrorColor,
    Color? errorContainerColor,
    Color? onErrorContainerColor,
    Color? surfaceColor,
    Color? onSurfaceColor,
    Color? surfaceDimColor,
    Color? surfaceBrightColor,
    Color? surfaceContainerLowestColor,
    Color? surfaceContainerLowColor,
    Color? surfaceContainerColor,
    Color? surfaceContainerHighColor,
    Color? surfaceContainerHighestColor,
    Color? onSurfaceVariantColor,
    Color? outelineColor,
    Color? outlineVariantColor,
    Color? shadowColor,
    Color? inversePrimaryColor,
    Color? inverseSurfaceColor,
    Color? onInverseSurfaceColor,
    Color? onPrimaryFixedVariantColor,
    Color? onSecondaryFixedVariantColor,
    Color? onTertiaryFixedVariantColor,
    Color? scrimColor,
    Color? surfaceTintColor,
    Color? primaryFixedColor,
    Color? primaryFixedDimColor,
    Color? tertiaryFixedColor,
    Color? tertiaryFixedDimColor,
    Color? onPrimaryFixedColor,
    Color? secondaryFixedColor,
    Color? secondaryFixedDimColor,
    Color? onTertiaryFixedColor,
  }) => AppColorScheme._(
    brightness: Brightness.light,
    primary: primaryColor ?? _SemanticColors.primary,
    onPrimary: onPrimaryColor ?? _SemanticColors.onPrimary,
    primaryContainer: primaryContainerColor ?? _SemanticColors.primaryContainer,
    onPrimaryContainer:
        onPrimaryContainerColor ?? _SemanticColors.onPrimaryContainer,
    secondary: secondaryColor ?? _SemanticColors.secondary,
    onSecondary: onSecondaryColor ?? _SemanticColors.onSecondary,
    secondaryContainer:
        secondaryContainerColor ?? _SemanticColors.secondaryContainer,
    onSecondaryContainer:
        onSecondaryContainerColor ?? _SemanticColors.onSecondaryContainer,
    onSecondaryFixed: onSecondaryFixedColor ?? _SemanticColors.onSecondary,
    tertiary: tertiaryColor ?? _SemanticColors.tertiary,
    onTertiary: onTertiaryColor,
    tertiaryContainer:
        tertiaryContainerColor ?? _SemanticColors.tertiaryContainer,
    onTertiaryContainer: onTertiaryContainerColor,
    error: errorColor ?? _SemanticColors.error,
    onError: onErrorColor ?? _SemanticColors.onError,
    errorContainer: errorContainerColor,
    onErrorContainer: onErrorContainerColor,
    surface: surfaceColor ?? _SemanticColors.surface,
    onSurface: onSurfaceColor ?? _SemanticColors.onSurface,
    surfaceDim: surfaceDimColor ?? _SemanticColors.surfaceDim,
    surfaceBright: surfaceBrightColor ?? _SemanticColors.surfaceBright,
    surfaceContainerLowest:
        surfaceContainerLowestColor ?? _SemanticColors.surfaceContainerLowest,
    surfaceContainerLow:
        surfaceContainerLowColor ?? _SemanticColors.surfaceContainerLow,
    surfaceContainer: surfaceContainerColor ?? _SemanticColors.surfaceContainer,
    surfaceContainerHigh:
        surfaceContainerHighColor ?? _SemanticColors.surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighestColor ??
        _SemanticColors.surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariantColor ?? _SemanticColors.onSurfaceVariant,
    outline: outelineColor ?? _SemanticColors.outline,
    outlineVariant: outlineVariantColor ?? _SemanticColors.outlineVariant,
    shadow: shadowColor ?? _SemanticColors.shadow,
    inversePrimary: inversePrimaryColor ?? _SemanticColors.inversePrimary,
    inverseSurface: inverseSurfaceColor ?? _SemanticColors.inverseSurface,
    onInverseSurface: onInverseSurfaceColor ?? _SemanticColors.onInverseSurface,
    onPrimaryFixedVariant: onPrimaryFixedVariantColor,
    onSecondaryFixedVariant: onSecondaryFixedVariantColor,
    onTertiaryFixedVariant: onTertiaryFixedVariantColor,
    scrim: scrimColor ?? _SemanticColors.scrim,
    surfaceTint: surfaceTintColor,
    primaryFixed: primaryFixedColor,
    primaryFixedDim: primaryFixedDimColor,
    tertiaryFixed: tertiaryFixedColor,
    tertiaryFixedDim: tertiaryFixedDimColor,
    onPrimaryFixed: onPrimaryFixedColor,
    secondaryFixed: secondaryFixedColor,
    secondaryFixedDim: secondaryFixedDimColor,
    onTertiaryFixed: onTertiaryFixedColor,
  );

  /// Builds the dark [AppColorScheme].
  ///
  /// Every parameter is optional and defaults to the matching
  /// [_SemanticColorsDark] token, so callers only pass the slots they want to
  /// override.
  factory AppColorScheme.dark({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? primaryContainerColor,
    Color? onPrimaryContainerColor,
    Color? secondaryColor,
    Color? onSecondaryColor,
    Color? secondaryContainerColor,
    Color? onSecondaryContainerColor,
    Color? onSecondaryFixedColor,
    Color? tertiaryColor,
    Color? onTertiaryColor,
    Color? tertiaryContainerColor,
    Color? onTertiaryContainerColor,
    Color? errorColor,
    Color? onErrorColor,
    Color? errorContainerColor,
    Color? onErrorContainerColor,
    Color? surfaceColor,
    Color? onSurfaceColor,
    Color? surfaceDimColor,
    Color? surfaceBrightColor,
    Color? surfaceContainerLowestColor,
    Color? surfaceContainerLowColor,
    Color? surfaceContainerColor,
    Color? surfaceContainerHighColor,
    Color? surfaceContainerHighestColor,
    Color? onSurfaceVariantColor,
    Color? outelineColor,
    Color? outlineVariantColor,
    Color? shadowColor,
    Color? inversePrimaryColor,
    Color? inverseSurfaceColor,
    Color? onInverseSurfaceColor,
    Color? onPrimaryFixedVariantColor,
    Color? onSecondaryFixedVariantColor,
    Color? onTertiaryFixedVariantColor,
    Color? scrimColor,
    Color? surfaceTintColor,
    Color? primaryFixedColor,
    Color? primaryFixedDimColor,
    Color? tertiaryFixedColor,
    Color? tertiaryFixedDimColor,
    Color? onPrimaryFixedColor,
    Color? secondaryFixedColor,
    Color? secondaryFixedDimColor,
    Color? onTertiaryFixedColor,
  }) => AppColorScheme._(
    brightness: Brightness.dark,
    primary: primaryColor ?? _SemanticColorsDark.primary,
    onPrimary: onPrimaryColor ?? _SemanticColorsDark.onPrimary,
    primaryContainer:
        primaryContainerColor ?? _SemanticColorsDark.primaryContainer,
    onPrimaryContainer:
        onPrimaryContainerColor ?? _SemanticColorsDark.onPrimaryContainer,
    secondary: secondaryColor ?? _SemanticColorsDark.secondary,
    onSecondary: onSecondaryColor ?? _SemanticColorsDark.onSecondary,
    secondaryContainer:
        secondaryContainerColor ?? _SemanticColorsDark.secondaryContainer,
    onSecondaryContainer:
        onSecondaryContainerColor ?? _SemanticColorsDark.onSecondaryContainer,
    onSecondaryFixed: onSecondaryFixedColor ?? _SemanticColorsDark.onSecondary,
    tertiary: tertiaryColor ?? _SemanticColorsDark.tertiary,
    onTertiary: onTertiaryColor,
    tertiaryContainer:
        tertiaryContainerColor ?? _SemanticColorsDark.tertiaryContainer,
    onTertiaryContainer: onTertiaryContainerColor,
    error: errorColor ?? _SemanticColorsDark.error,
    onError: onErrorColor ?? _SemanticColorsDark.onError,
    errorContainer: errorContainerColor,
    onErrorContainer: onErrorContainerColor,
    surface: surfaceColor ?? _SemanticColorsDark.surface,
    onSurface: onSurfaceColor ?? _SemanticColorsDark.onSurface,
    surfaceDim: surfaceDimColor ?? _SemanticColorsDark.surfaceDim,
    surfaceBright: surfaceBrightColor ?? _SemanticColorsDark.surfaceBright,
    surfaceContainerLowest: surfaceContainerLowestColor ??
        _SemanticColorsDark.surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLowColor ??
        _SemanticColorsDark.surfaceContainerLow,
    surfaceContainer:
        surfaceContainerColor ?? _SemanticColorsDark.surfaceContainer,
    surfaceContainerHigh: surfaceContainerHighColor ??
        _SemanticColorsDark.surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighestColor ??
        _SemanticColorsDark.surfaceContainerHighest,
    onSurfaceVariant:
        onSurfaceVariantColor ?? _SemanticColorsDark.onSurfaceVariant,
    outline: outelineColor ?? _SemanticColorsDark.outline,
    outlineVariant: outlineVariantColor ?? _SemanticColorsDark.outlineVariant,
    shadow: shadowColor ?? _SemanticColorsDark.shadow,
    inversePrimary: inversePrimaryColor ?? _SemanticColorsDark.inversePrimary,
    inverseSurface: inverseSurfaceColor ?? _SemanticColorsDark.inverseSurface,
    onInverseSurface:
        onInverseSurfaceColor ?? _SemanticColorsDark.onInverseSurface,
    onPrimaryFixedVariant: onPrimaryFixedVariantColor,
    onSecondaryFixedVariant: onSecondaryFixedVariantColor,
    onTertiaryFixedVariant: onTertiaryFixedVariantColor,
    scrim: scrimColor ?? _SemanticColorsDark.scrim,
    surfaceTint: surfaceTintColor,
    primaryFixed: primaryFixedColor,
    primaryFixedDim: primaryFixedDimColor,
    tertiaryFixed: tertiaryFixedColor,
    tertiaryFixedDim: tertiaryFixedDimColor,
    onPrimaryFixed: onPrimaryFixedColor,
    secondaryFixed: secondaryFixedColor,
    secondaryFixedDim: secondaryFixedDimColor,
    onTertiaryFixed: onTertiaryFixedColor,
  );
}
