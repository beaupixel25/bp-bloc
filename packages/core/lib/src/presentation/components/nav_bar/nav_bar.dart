import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nav_bar.freezed.dart';

/// One destination in a [NavBar].
class NavBarItem {
  /// Creates a destination showing [icon] and announcing [semanticLabel].
  const NavBarItem({required this.icon, required this.semanticLabel});

  /// One of the [AppIcons] constants.
  final String icon;

  /// What this destination is, e.g. "Home". Required: the destination is an
  /// icon with no text, so this is all a screen reader has.
  final String semanticLabel;
}

/// {@template nav_bar}
/// A floating pill of destination icons. The active destination reads as a
/// filled icon button; the rest stay transparent with muted icons.
///
/// **This is the pill only.** It does not position itself, add a safe area, or
/// know about a [Scaffold] — the app-level wrapper places it, because how far
/// it must sit above the system gesture area is a property of the screen, not
/// of the bar. A component that pins itself to the bottom cannot be used
/// anywhere else, including in this package's own gallery.
///
/// ```dart
/// NavBar(
///   items: const [
///     NavBarItem(icon: AppIcons.home, semanticLabel: 'Home'),
///     NavBarItem(icon: AppIcons.settings, semanticLabel: 'Settings'),
///   ],
///   selectedIndex: 0,
///   onSelected: (index) {},
/// )
/// ```
/// {@endtemplate}
class NavBar extends StatelessWidget {
  /// {@macro nav_bar}
  const NavBar({
    required this.items,
    required this.selectedIndex,
    super.key,
    this.onSelected,
    this.theme,
  });

  /// The destinations, in leading-to-trailing order.
  final List<NavBarItem> items;

  /// The index of the active destination.
  final int selectedIndex;

  /// Called with the tapped destination's index.
  final ValueChanged<int>? onSelected;

  /// Styling. Defaults to the nearest [NavBarTheme], then to
  /// [NavBarThemeData.fallback] for the ambient theme.
  final NavBarThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? NavBarTheme.of(context);

    return Container(
      padding: theme.containerPadding,
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(theme.radius),
        boxShadow: theme.boxShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavBarDestination(
              item: items[i],
              isSelected: i == selectedIndex,
              onTapped: onSelected == null ? null : () => onSelected!(i),
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _NavBarDestination extends StatelessWidget {
  const _NavBarDestination({
    required this.item,
    required this.isSelected,
    required this.onTapped,
    required this.theme,
  });

  final NavBarItem item;
  final bool isSelected;
  final VoidCallback? onTapped;
  final NavBarThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pill = BorderRadius.circular(theme.radius);

    return Semantics(
      label: item.semanticLabel,
      button: true,
      // Each destination reports its own state. A bar that knows which tab is
      // active while the tabs do not leaves a screen-reader user counting.
      selected: isSelected,
      child: Material(
        color: theme.itemBackground,
        child: InkWell(
          onTap: onTapped,
          borderRadius: pill,
          // The tap target. The fill is inset within it, so the selected pill
          // reads as a contained highlight rather than edge-to-edge.
          child: Padding(
            padding: theme.itemPadding,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    isSelected ? theme.selectedFill : theme.itemBackground,
                borderRadius: pill,
              ),
              child: Padding(
                padding: theme.selectedFillPadding,
                child: AppIcon(
                  item.icon,
                  size: theme.iconSize,
                  color: isSelected ? theme.activeColor : theme.inactiveColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The styling contract for [NavBar].
@freezed
sealed class NavBarThemeData with _$NavBarThemeData {
  /// Creates a fully specified nav-bar style.
  factory NavBarThemeData({
    required Color background,
    required Color itemBackground,
    required Color activeColor,
    required Color inactiveColor,
    required Color selectedFill,
    required List<BoxShadow> boxShadow,
    required double radius,
    required EdgeInsets containerPadding,
    required EdgeInsets itemPadding,
    required EdgeInsets selectedFillPadding,
    @Default(24) double iconSize,
  }) = _NavBarThemeData;

  /// Derives the nav-bar style from the ambient theme.
  factory NavBarThemeData.fallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = ColorExtension.of(context);
    final dimensions = DimensionExtension.of(context);

    return NavBarThemeData(
      background: colorScheme.surfaceContainerLowest,
      itemBackground: colors.transparentColor,
      selectedFill: colorScheme.primaryContainer,
      // Paired with the fill, not taken from the surface: `onSurface` over
      // primaryContainer is the classic dark-mode contrast failure, because
      // the container is the one colour that does not flip with the theme.
      activeColor: colorScheme.onPrimaryContainer,
      inactiveColor: colorScheme.onSurfaceVariant,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.12),
          offset: const Offset(0, 6),
          blurRadius: 24,
        ),
      ],
      radius: dimensions.radiusPill,
      containerPadding: EdgeInsets.symmetric(
        horizontal: dimensions.space12 + 2,
        vertical: dimensions.space8,
      ),
      // The gap between the fill and the tap-target edge — keeps it inset.
      itemPadding: EdgeInsets.symmetric(
        horizontal: dimensions.space4 + 2,
        vertical: dimensions.space4,
      ),
      // Inner padding around the icon. With a 24 icon this makes a fill of
      // roughly 48x40 inside a tap target of roughly 60x48.
      selectedFillPadding: EdgeInsets.symmetric(
        horizontal: dimensions.space12,
        vertical: dimensions.space8,
      ),
    );
  }
}

/// The [InheritedWidget] that propagates a [NavBarThemeData] to descendant
/// [NavBar]s.
class NavBarTheme extends InheritedWidget {
  /// Creates a [NavBarTheme] exposing [data] to its subtree.
  const NavBarTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final NavBarThemeData data;

  @override
  bool updateShouldNotify(NavBarTheme oldWidget) => data != oldWidget.data;

  /// Resolves the nearest [NavBarThemeData], falling back to
  /// [NavBarThemeData.fallback] when none is in scope.
  static NavBarThemeData of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<NavBarTheme>();

    return result?.data ?? NavBarThemeData.fallback(context);
  }
}
