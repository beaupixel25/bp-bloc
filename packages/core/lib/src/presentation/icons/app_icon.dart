import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Where `core`'s bundled assets live, as Flutter addresses them.
///
/// **The `lib/` is not a mistake.** `core/pubspec.yaml` declares its assets as
/// `lib/assets/…`, and Flutter prefixes a package's declared path with
/// `packages/<name>/` **without stripping `lib/`** — so this constant spells
/// out that full runtime key below. Doing that means every asset path built
/// from it resolves directly against the default asset bundle — no second
/// `package:` argument, and no second place to keep in sync. Dropping the
/// `lib/` segment produces "Unable to load asset" at runtime and a red box in
/// the UI, with nothing in the analyzer or the build to warn you. If these
/// ever move out of `lib/`, change this one constant and the pubspec
/// together.
const String kCoreAssetRoot = 'packages/core/lib/assets';

/// The design system's icon set.
///
/// Every icon is an SVG authored at a 1.5px stroke and filled with
/// `currentColor`, so [AppIcon] can recolour it from the theme. There is no
/// Material glyph fallback and no unicode arrow, chevron, check or emoji
/// anywhere in `core` — an icon that is not in this list has to be added to
/// `lib/assets/icons/` first.
abstract final class AppIcons {
  /// A check mark. Confirmation and success states.
  static const String check = '$kCoreAssetRoot/icons/check.svg';

  /// A single left-pointing chevron. Back affordance in an app bar.
  static const String chevronLeft = '$kCoreAssetRoot/icons/chevron_left.svg';

  /// An open eye. "Show password" in its hidden state.
  static const String eye = '$kCoreAssetRoot/icons/eye.svg';

  /// A crossed-out eye. "Hide password" in its shown state.
  static const String eyeOff = '$kCoreAssetRoot/icons/eye_off.svg';

  /// A warning triangle. Required beside every error message — colour alone
  /// never carries the meaning.
  static const String alertTriangle =
      '$kCoreAssetRoot/icons/alert_triangle.svg';

  /// A house. The primary tab of the floating nav bar.
  static const String home = '$kCoreAssetRoot/icons/home.svg';

  /// A bell. The notifications tab of the floating nav bar.
  static const String notifications = '$kCoreAssetRoot/icons/bell.svg';

  /// A gear. The settings tab / entry point.
  static const String settings = '$kCoreAssetRoot/icons/settings.svg';
}

/// {@template app_icon}
/// Renders one [AppIcons] entry, tinted [color].
///
/// The SVGs are authored with `fill="currentColor"`, which SVG itself cannot
/// resolve outside a document — this widget is what supplies the "current"
/// colour, via a [ColorFilter]. Leaving [color] null inherits from the ambient
/// [IconTheme], so an icon inside a button picks up that button's foreground
/// without being told.
///
/// Size by **either** [size] (a height) **or** [width], never both; the other
/// dimension follows the asset's aspect ratio. The design's glyphs are not all
/// square — the chevron is roughly 1:2 — so forcing a square box would
/// distort it.
/// {@endtemplate}
class AppIcon extends StatelessWidget {
  /// {@macro app_icon}
  const AppIcon(
    this.asset, {
    super.key,
    this.size,
    this.width,
    this.color,
    this.semanticLabel,
  }) : assert(
          size == null || width == null,
          'Give AppIcon a height (size) or a width, not both — the other '
          'dimension comes from the asset.',
        );

  /// One of the [AppIcons] constants.
  final String asset;

  /// The icon's height in logical pixels. Defaults to the ambient
  /// [IconThemeData.size], then to 24. Ignored when [width] is given.
  final double? size;

  /// The icon's width in logical pixels. Use for anything measured by width.
  final double? width;

  /// The tint. Defaults to the ambient [IconThemeData.color], then to
  /// `colorScheme.onSurface`.
  final Color? color;

  /// Announced by screen readers. Leave null for a decorative icon that sits
  /// beside text already saying the same thing.
  final String? semanticLabel;

  /// Decodes [asset] into `flutter_svg`'s picture cache ahead of first paint.
  ///
  /// A cold [SvgPicture.asset] parses on the frame that first shows it. That is
  /// fine anywhere the frame is cheap, and not fine during a launch sequence,
  /// where the parse lands mid-motion and reads as a stutter — so the launch
  /// awaits this before starting its clock.
  ///
  /// The cache key is built the same way [build] builds it, so a warmed asset
  /// really is the one the widget then finds. Give it the same [BuildContext]
  /// the widget will use: the key includes the ambient [DefaultAssetBundle].
  static Future<void> precache(String asset, BuildContext context) =>
      SvgAssetLoader(asset).loadBytes(context);

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      asset,
      width: width,
      height: width == null ? (size ?? iconTheme.size ?? 24) : null,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
