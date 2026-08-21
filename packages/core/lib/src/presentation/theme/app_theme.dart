import 'dart:math';

import 'package:core/src/presentation/theme/color_scheme.dart';
import 'package:core/src/presentation/theme/dimension_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_theme.freezed.dart';

/// The app's theme configuration: light/dark themes, theme mode, and
/// text scaling.
@freezed
sealed class AppThemeData with _$AppThemeData {
  /// Creates an [AppThemeData].
  const factory AppThemeData({
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required ThemeMode themeMode,
    required double currentDeviceTextScaleFactor,
    required TextScaler textScaler,
    @Default(true) bool isDarkModeEnabled,
  }) = _AppThemeData;

  /// Creates an [AppThemeData] with sensible defaults, using the provided
  /// [extensions] list if given (empty otherwise).
  factory AppThemeData.fallback(
    BuildContext context, {
    List<ThemeExtension<dynamic>>? extensions,
    ThemeMode? themeMode,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
  }) {
    final currentDeviceToBaseRatio =
        MediaQuery.of(context).size.width / _baseFormFactorWidth;

    // Constrain how much scaling happens on smaller devices to prevent the
    // UI from breaking when a large text size causes certain UI elements to
    // overflow (e.g. fixed-width or horizontally laid out UIs).
    final maxTextScaleFactor = currentDeviceToBaseRatio >= 1.05 ? 1.3 : 1.2;
    final currentDeviceTextScaleFactor =
        min(currentDeviceToBaseRatio, maxTextScaleFactor);
    final textScaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: currentDeviceTextScaleFactor,
          maxScaleFactor: maxTextScaleFactor,
        );

    return AppThemeData(
      themeMode: themeMode ?? ThemeMode.system,
      lightTheme: _initializeDefaultThemeData(
        context,
        extensions: extensions,
        colorScheme: lightColorScheme ?? AppColorScheme.light(),
      ),
      darkTheme: _initializeDefaultThemeData(
        context,
        isDark: true,
        extensions: extensions,
        colorScheme: darkColorScheme ?? AppColorScheme.dark(),
      ),
      currentDeviceTextScaleFactor: currentDeviceTextScaleFactor,
      textScaler: textScaler,
    );
  }

  /// The handset base width the design is based on.
  static const double _baseFormFactorWidth = 375;

  static ThemeData _initializeDefaultThemeData(
    BuildContext context, {
    required ColorScheme colorScheme,
    bool isDark = false,
    List<ThemeExtension<dynamic>>? extensions,
  }) {
    final baseTheme = Theme.of(context);
    // The design-system ThemeExtensions are always registered so widgets can
    // read them via Theme.of(context).extension<...>(). Any extra extensions
    // passed in are appended (and win, being later in the list).
    //
    // Built via List.empty()..add() rather than a list literal on purpose.
    // ThemeExtension is F-bounded (T extends ThemeExtension<T>), so a list
    // literal with concrete entries makes the CFE infer the element type as the
    // LUB ThemeExtension<ThemeExtension<dynamic>> (overriding the explicit
    // <ThemeExtension<dynamic>>), which then rejects addAll of a
    // List<ThemeExtension<dynamic>>. The List.empty() constructor pins the
    // element type so the concrete adds can't widen it. dart analyze does not
    // catch this (analyzer is not the CFE); theme_smoke_test.dart guards it.
    final themeExtensions = List<ThemeExtension<dynamic>>.empty(growable: true)
      ..add(ColorExtension())
      ..add(DimensionExtension.defaults());
    if (extensions != null) {
      themeExtensions.addAll(extensions);
    }
    final textTheme = baseTheme.textTheme
        .copyWith(
          displayLarge: baseTheme.textTheme.displayLarge!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 57,
            height: 1.12,
            letterSpacing: -0.25,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: baseTheme.textTheme.displayMedium!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 45,
            height: 1.16,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: baseTheme.textTheme.displaySmall!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 36,
            height: 1.22,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: baseTheme.textTheme.headlineLarge!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 32,
            height: 1.25,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: baseTheme.textTheme.headlineMedium!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 28,
            height: 1.29,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: baseTheme.textTheme.headlineSmall!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque',
            fontSize: 24,
            height: 1.33,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: baseTheme.textTheme.titleLarge!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 22,
            height: 1.27,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: baseTheme.textTheme.titleMedium!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.15,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: baseTheme.textTheme.titleSmall!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 14,
            height: 1.43,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w600,
          ),
          labelLarge: baseTheme.textTheme.labelLarge!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 14,
            height: 1.43,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: baseTheme.textTheme.labelMedium!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 12,
            height: 1.33,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: baseTheme.textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Basis Grotesque Mono',
            fontSize: 11,
            height: 1.45,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseTheme.textTheme.bodyLarge!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.15,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 14,
            height: 1.43,
            letterSpacing: 0.25,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: baseTheme.textTheme.bodySmall!.copyWith(
            color: colorScheme.onSurface,
            fontFamily: 'packages/core/Neue Haas Grotesk Display',
            fontSize: 12,
            height: 1.33,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w400,
          ),
        )
        .apply(
          decorationColor: colorScheme.tertiary,
        );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      extensions: themeExtensions,
      textTheme: textTheme,
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? colorScheme.surfaceContainerLowest : colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: colorScheme.surface,
          size: 20,
          opacity: 1,
        ),
        shadowColor: colorScheme.shadow,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge!.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? colorScheme.surfaceContainerLowest : colorScheme.primary,
        selectedItemColor:
            isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        unselectedItemColor:
            isDark ? colorScheme.outline : colorScheme.onSurfaceVariant,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(
            color: colorScheme.outline,
            width: isDark ? 0.2 : 1.0,
          ),
        ),
        elevation: isDark ? 2 : 0,
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        hintStyle: textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.secondaryContainer,
        ),
        labelStyle: textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.outline,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11.5),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(color: colorScheme.secondary),
      radioTheme: baseTheme.radioTheme.copyWith(
        fillColor: WidgetStatePropertyAll<Color?>(
          colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Provides the [AppThemeData] to the widget tree.
class AppTheme extends InheritedWidget {
  /// Creates an [AppTheme].
  const AppTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme configuration exposed to descendants.
  final AppThemeData data;

  /// Whether the app should currently render in light mode.
  static bool isLightThemeMode(
    BuildContext context, {
    bool respondToDarkMode = true,
  }) {
    final appTheme = AppTheme.of(context);

    if (!appTheme.isDarkModeEnabled || !respondToDarkMode) {
      return true;
    } else {
      return MediaQuery.of(context).platformBrightness == Brightness.light;
    }
  }

  /// The standard box shadows used by elevated components.
  static List<BoxShadow> getComponentBoxShadows(
    BuildContext context, {
    bool respondToDarkMode = false,
    bool isBottom = true,
    Color? color,
  }) {
    final shadowColor = color ?? Theme.of(context).colorScheme.shadow;

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.05),
        offset: const Offset(0, 1),
        blurRadius: 10,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.1),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }

  /// Scales [value] by the current text scaler.
  static double textScale(BuildContext context, double value) =>
      MediaQuery.of(context).textScaler.scale(value);

  /// The nearest [AppThemeData], or a fallback if none is provided.
  static AppThemeData of(
    BuildContext context, {
    bool respondToDarkMode = false,
  }) {
    final result = context.dependOnInheritedWidgetOfExactType<AppTheme>();

    return result?.data ?? AppThemeData.fallback(context);
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return data != oldWidget.data;
  }
}
