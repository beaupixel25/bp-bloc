import 'dart:ui';

import 'package:flutter/material.dart';

/// A [ThemeExtension] providing the design system's spacing, corner-radius, and
/// elevation tokens. These are the non-color primitives of the design system;
/// colors live in `ColorExtension` / the [ColorScheme].
///
/// Access via [DimensionExtension.of], or
/// `Theme.of(context).extension<DimensionExtension>()`.
@immutable
class DimensionExtension extends ThemeExtension<DimensionExtension> {
  /// Creates a [DimensionExtension] with explicit token values.
  const DimensionExtension({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space24,
    required this.space32,
    required this.space40,
    required this.space48,
    required this.space56,
    required this.space64,
    required this.space72,
    required this.space80,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.elevationNone,
    required this.elevationLow,
    required this.elevationMedium,
    required this.elevationHigh,
  });

  /// The default token scale (a 4pt spacing grid). The `import-design-system`
  /// skill rewrites these values when a design-system bundle is applied.
  factory DimensionExtension.defaults() {
    return const DimensionExtension(
      space4: 4,
      space8: 8,
      space12: 12,
      space16: 16,
      space24: 24,
      space32: 32,
      space40: 40,
      space48: 48,
      space56: 56,
      space64: 64,
      space72: 72,
      space80: 80,
      radiusXs: 8,
      radiusSm: 12,
      radiusMd: 16,
      radiusLg: 24,
      radiusXl: 32,
      radiusPill: 9999,
      elevationNone: 0,
      elevationLow: 1,
      elevationMedium: 3,
      elevationHigh: 6,
    );
  }

  /// The nearest [DimensionExtension], or [DimensionExtension.defaults] when no
  /// theme registers it.
  ///
  /// Falling back rather than throwing keeps a component usable outside a full
  /// app theme — a widget test that pumps a bare [MaterialApp], for instance.
  // A lookup, not a constructor: `X.of(context)` is the framework's own idiom
  // (`Theme.of`, `MediaQuery.of`) and reads as one at every call site.
  // ignore: prefer_constructors_over_static_methods
  static DimensionExtension of(BuildContext context) =>
      Theme.of(context).extension<DimensionExtension>() ??
      DimensionExtension.defaults();

  /// Spacing token: 4dp.
  final double space4;

  /// Spacing token: 8dp.
  final double space8;

  /// Spacing token: 12dp.
  final double space12;

  /// Spacing token: 16dp.
  final double space16;

  /// Spacing token: 24dp.
  final double space24;

  /// Spacing token: 32dp.
  final double space32;

  /// Spacing token: 40dp.
  final double space40;

  /// Spacing token: 48dp.
  final double space48;

  /// Spacing token: 56dp.
  final double space56;

  /// Spacing token: 64dp.
  final double space64;

  /// Spacing token: 72dp.
  final double space72;

  /// Spacing token: 80dp.
  final double space80;

  /// Corner radius token: extra small.
  final double radiusXs;

  /// Corner radius token: small.
  final double radiusSm;

  /// Corner radius token: medium.
  final double radiusMd;

  /// Corner radius token: large.
  final double radiusLg;

  /// Corner radius token: extra large.
  final double radiusXl;

  /// Corner radius token: fully rounded (pill / circular).
  final double radiusPill;

  /// Elevation token: none (flat).
  final double elevationNone;

  /// Elevation token: low.
  final double elevationLow;

  /// Elevation token: medium.
  final double elevationMedium;

  /// Elevation token: high.
  final double elevationHigh;

  @override
  DimensionExtension copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space24,
    double? space32,
    double? space40,
    double? space48,
    double? space56,
    double? space64,
    double? space72,
    double? space80,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
    double? elevationNone,
    double? elevationLow,
    double? elevationMedium,
    double? elevationHigh,
  }) {
    return DimensionExtension(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space40: space40 ?? this.space40,
      space48: space48 ?? this.space48,
      space56: space56 ?? this.space56,
      space64: space64 ?? this.space64,
      space72: space72 ?? this.space72,
      space80: space80 ?? this.space80,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusPill: radiusPill ?? this.radiusPill,
      elevationNone: elevationNone ?? this.elevationNone,
      elevationLow: elevationLow ?? this.elevationLow,
      elevationMedium: elevationMedium ?? this.elevationMedium,
      elevationHigh: elevationHigh ?? this.elevationHigh,
    );
  }

  @override
  DimensionExtension lerp(
    covariant ThemeExtension<DimensionExtension>? other,
    double t,
  ) {
    if (other is! DimensionExtension) return this;
    return DimensionExtension(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      space32: lerpDouble(space32, other.space32, t)!,
      space40: lerpDouble(space40, other.space40, t)!,
      space48: lerpDouble(space48, other.space48, t)!,
      space56: lerpDouble(space56, other.space56, t)!,
      space64: lerpDouble(space64, other.space64, t)!,
      space72: lerpDouble(space72, other.space72, t)!,
      space80: lerpDouble(space80, other.space80, t)!,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      elevationNone: lerpDouble(elevationNone, other.elevationNone, t)!,
      elevationLow: lerpDouble(elevationLow, other.elevationLow, t)!,
      elevationMedium: lerpDouble(elevationMedium, other.elevationMedium, t)!,
      elevationHigh: lerpDouble(elevationHigh, other.elevationHigh, t)!,
    );
  }
}
