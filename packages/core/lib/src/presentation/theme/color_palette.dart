// _SemanticColorsDark defines the full symmetric member set so
// any token can be referenced by overrides; consumers usually
// read only a subset, so suppress unused_field here.
// ignore_for_file: unused_field
part of 'color_scheme.dart';

abstract class _ColorPalette {
  static const Color black = Color(0xFF141414);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lime10 = Color(0xFF2E3808);
  static const Color lime30 = Color(0xFF7A9421);
  static const Color lime50 = Color(0xFFC7E034);
  static const Color lime70 = Color(0xFFE4EFA8);
  static const Color lime90 = Color(0xFFF5F9E0);
  static const Color neutral10 = Color(0xFF141414);
  static const Color neutral30 = Color(0xFF5B5B5B);
  static const Color neutral50 = Color(0xFF8F8F8F);
  static const Color neutral70 = Color(0xFFC7C7C7);
  static const Color neutral90 = Color(0xFFF4F4F4);
  static const Color coral40 = Color(0xFFE85A45);
  static const Color coral70 = Color(0xFFFFD8CF);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkOutline = Color(0xFF3A3A3A);
}

/// Light semantic aliases over [_ColorPalette].
abstract class _SemanticColors {
  static const Color inversePrimary = _ColorPalette.lime30;
  static const Color primary = _ColorPalette.lime50;
  static const Color primaryVariant = _ColorPalette.lime50;
  static const Color onPrimary = _ColorPalette.black;
  static const Color primaryContainer = _ColorPalette.lime90;
  static const Color primaryContainerVariant = _ColorPalette.lime90;
  static const Color onPrimaryContainerVariant = _ColorPalette.lime10;
  static const Color onPrimaryContainer = _ColorPalette.lime10;
  static const Color secondary = _ColorPalette.neutral30;
  static const Color secondaryVariant = _ColorPalette.neutral30;
  static const Color onSecondary = _ColorPalette.white;
  static const Color secondaryContainer = _ColorPalette.neutral90;
  static const Color secondaryContainerVariant = _ColorPalette.neutral90;
  static const Color onSecondaryContainer = _ColorPalette.neutral10;
  static const Color onSecondaryContainerVariant = _ColorPalette.neutral10;
  static const Color tertiary = _ColorPalette.coral40;
  static const Color tertiaryVariant = _ColorPalette.coral40;
  static const Color onTertiary = _ColorPalette.white;
  static const Color tertiaryContainer = _ColorPalette.coral70;
  static const Color tertiaryContainerVariant = _ColorPalette.coral70;
  static const Color onTertiaryContainer = _ColorPalette.black;
  static const Color onTertiaryContainerVariant = _ColorPalette.black;
  static const Color error = _ColorPalette.coral40;
  static const Color errorVariant = _ColorPalette.coral40;
  static const Color errorContainer = _ColorPalette.coral70;
  static const Color onErrorContainer = _ColorPalette.black;
  static const Color errorContainerVariant = _ColorPalette.coral70;
  static const Color onErrorContainerVariant = _ColorPalette.black;
  static const Color onError = _ColorPalette.white;
  static const Color surface = _ColorPalette.white;
  static const Color surfaceDim = _ColorPalette.neutral90;
  static const Color surfaceBright = _ColorPalette.white;
  static const Color onSurface = _ColorPalette.black;
  static const Color surfaceVariant = _ColorPalette.white;
  static const Color onSurfaceVariant = _ColorPalette.neutral30;
  static const Color surfaceContainerLowest = _ColorPalette.white;
  static const Color surfaceContainerLow = _ColorPalette.neutral90;
  static const Color surfaceContainer = _ColorPalette.neutral90;
  static const Color surfaceContainerHigh = _ColorPalette.neutral70;
  static const Color surfaceContainerHighest = _ColorPalette.neutral70;
  static const Color outline = _ColorPalette.neutral70;
  static const Color outlineVariant = _ColorPalette.neutral90;
  static const Color inverseSurface = _ColorPalette.black;
  static const Color onInverseSurface = _ColorPalette.white;
  static const Color shadow = _ColorPalette.black;
  static const Color shadowVariant = _ColorPalette.black;
  static const Color scrim = _ColorPalette.black;
  static const Color link = _ColorPalette.lime50;
}


/// Dark semantic aliases; each defaults to the light value.
abstract class _SemanticColorsDark {
  static const Color inversePrimary = _ColorPalette.lime30;
  static const Color primary = _ColorPalette.lime50;
  static const Color primaryVariant = _ColorPalette.lime50;
  static const Color onPrimary = _ColorPalette.black;
  static const Color primaryContainer = _ColorPalette.lime10;
  static const Color primaryContainerVariant = _ColorPalette.lime10;
  static const Color onPrimaryContainerVariant = _ColorPalette.lime70;
  static const Color onPrimaryContainer = _ColorPalette.lime70;
  static const Color secondary = _ColorPalette.neutral30;
  static const Color secondaryVariant = _ColorPalette.neutral30;
  static const Color onSecondary = _ColorPalette.white;
  static const Color secondaryContainer = _ColorPalette.darkCard;
  static const Color secondaryContainerVariant = _ColorPalette.darkCard;
  static const Color onSecondaryContainer = _ColorPalette.neutral70;
  static const Color onSecondaryContainerVariant = _ColorPalette.neutral70;
  static const Color tertiary = _ColorPalette.coral40;
  static const Color tertiaryVariant = _ColorPalette.coral40;
  static const Color onTertiary = _ColorPalette.white;
  static const Color tertiaryContainer = _ColorPalette.coral70;
  static const Color tertiaryContainerVariant = _ColorPalette.coral70;
  static const Color onTertiaryContainer = _ColorPalette.black;
  static const Color onTertiaryContainerVariant = _ColorPalette.black;
  static const Color error = _ColorPalette.coral40;
  static const Color errorVariant = _ColorPalette.coral40;
  static const Color errorContainer = _ColorPalette.coral70;
  static const Color onErrorContainer = _ColorPalette.black;
  static const Color errorContainerVariant = _ColorPalette.coral70;
  static const Color onErrorContainerVariant = _ColorPalette.black;
  static const Color onError = _ColorPalette.white;
  static const Color surface = _ColorPalette.darkSurface;
  static const Color surfaceDim = _ColorPalette.darkSurface;
  static const Color surfaceBright = _ColorPalette.darkCard;
  static const Color onSurface = _ColorPalette.white;
  static const Color surfaceVariant = _ColorPalette.darkSurface;
  static const Color onSurfaceVariant = _ColorPalette.neutral50;
  static const Color surfaceContainerLowest = _ColorPalette.black;
  static const Color surfaceContainerLow = _ColorPalette.darkSurface;
  static const Color surfaceContainer = _ColorPalette.darkCard;
  static const Color surfaceContainerHigh = _ColorPalette.darkCard;
  static const Color surfaceContainerHighest = _ColorPalette.darkOutline;
  static const Color outline = _ColorPalette.darkOutline;
  static const Color outlineVariant = _ColorPalette.neutral30;
  static const Color inverseSurface = _ColorPalette.white;
  static const Color onInverseSurface = _ColorPalette.black;
  static const Color shadow = _ColorPalette.black;
  static const Color shadowVariant = _ColorPalette.black;
  static const Color scrim = _ColorPalette.black;
  static const Color link = _ColorPalette.lime50;
}
