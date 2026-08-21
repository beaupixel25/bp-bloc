import 'package:core/src/presentation/icons/app_icon.dart';
import 'package:flutter/material.dart';

/// The design system's raster art.
///
/// Vectors live in [AppIcons] and should be preferred — this is for artwork
/// that genuinely is a bitmap. `core` bundles none of its own; brand artwork
/// lives in the app package instead. [path] and [provider] exist so a
/// component that needs one builds its address the same way [AppIcons] builds
/// an icon path, rather than hand-writing the `packages/core/lib/assets`
/// prefix a second time.
abstract final class AppImages {
  /// Prefixes [name] with `$kCoreAssetRoot/illustrations/`, the shape any
  /// raster asset added to `core` follows.
  static String path(String name) => '$kCoreAssetRoot/illustrations/$name';

  /// Builds an [ImageProvider] for a path built by [path].
  static ImageProvider provider(String asset) => AssetImage(asset);
}
