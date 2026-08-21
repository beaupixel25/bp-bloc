import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ambient_backdrop.freezed.dart';

/// {@template ambient_backdrop}
/// A soft, artwork-free wash of colour for a page to sit on.
///
/// Three radial gradients in the scheme's `primary`, `secondary` and
/// `tertiary` roles, at low alpha over a plain ground. It is deliberately
/// **not** an image: an illustrated backdrop has to be redrawn for every brand
/// and every aspect ratio, whereas this one restyles itself the moment a
/// design-system bundle changes the colour scheme, and costs nothing to ship.
///
/// It fills its parent and paints [child] on top, so give it a whole page —
/// usually as a [Scaffold]'s `body`. It sets no padding and no safe area of
/// its own: it is a background, and layout is the page's business.
///
/// Every wash fades to fully transparent at its edge. A gradient that stops at
/// a non-zero alpha draws a visible disc rim, which is the one way this effect
/// looks cheap.
/// {@endtemplate}
class AmbientBackdrop extends StatelessWidget {
  /// {@macro ambient_backdrop}
  const AmbientBackdrop({
    required this.child,
    super.key,
    this.theme,
  });

  /// Painted on top of the wash, filling the same box.
  final Widget child;

  /// Styling. Defaults to the nearest [AmbientBackdropTheme], then to
  /// [AmbientBackdropThemeData.fallback] for the ambient theme.
  final AmbientBackdropThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AmbientBackdropTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.groundColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final wash in theme.washes)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: wash.center,
                  radius: wash.radius,
                  colors: [
                    wash.color.withValues(alpha: wash.alpha),
                    wash.color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// One radial bloom of colour in an [AmbientBackdrop].
@freezed
sealed class AmbientWash with _$AmbientWash {
  /// Creates a wash of [color] centred on [center].
  const factory AmbientWash({
    required Color color,
    required Alignment center,
    @Default(0.9) double radius,
    @Default(0.22) double alpha,
  }) = _AmbientWash;
}

/// The styling contract for [AmbientBackdrop].
@freezed
sealed class AmbientBackdropThemeData with _$AmbientBackdropThemeData {
  /// Creates a fully specified backdrop style.
  ///
  /// [washes] paint in order, so a later one blooms over an earlier one.
  factory AmbientBackdropThemeData({
    required Color groundColor,
    required List<AmbientWash> washes,
  }) = _AmbientBackdropThemeData;

  /// Derives the backdrop from the ambient theme.
  ///
  /// The three washes are placed off-centre and off-balance — two high, one
  /// low and opposite — because three blooms on a symmetric grid read as a
  /// pattern rather than as light.
  factory AmbientBackdropThemeData.fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AmbientBackdropThemeData(
      groundColor: colorScheme.surface,
      washes: [
        AmbientWash(
          color: colorScheme.primary,
          center: const Alignment(-0.8, -0.9),
        ),
        AmbientWash(
          color: colorScheme.tertiary,
          center: const Alignment(0.9, -0.5),
          radius: 0.8,
          alpha: 0.18,
        ),
        AmbientWash(
          color: colorScheme.secondary,
          center: const Alignment(0.2, 1),
          radius: 1.1,
          alpha: 0.14,
        ),
      ],
    );
  }
}

/// The [InheritedWidget] that propagates an [AmbientBackdropThemeData] to
/// descendant [AmbientBackdrop]s.
class AmbientBackdropTheme extends InheritedWidget {
  /// Creates an [AmbientBackdropTheme] exposing [data] to its subtree.
  const AmbientBackdropTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final AmbientBackdropThemeData data;

  @override
  bool updateShouldNotify(AmbientBackdropTheme oldWidget) =>
      data != oldWidget.data;

  /// Resolves the nearest [AmbientBackdropThemeData], falling back to
  /// [AmbientBackdropThemeData.fallback] when none is in scope.
  static AmbientBackdropThemeData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<AmbientBackdropTheme>();

    return result?.data ?? AmbientBackdropThemeData.fallback(context);
  }
}
