import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Names this app's three signed-in destinations and positions `core`'s
/// [NavBar] pill clear of the system gesture area.
///
/// App-level, not part of the onboarding feature: deleting
/// `lib/features/onboarding/` must not take the signed-in experience with
/// it, so this file imports nothing from there.
///
/// A plain widget, not a page: no [Scaffold] and no route. The shell that
/// owns the signed-in tabs places this directly inside a [Stack], over the
/// active branch's content — [selectedIndex] and [onSelected] come from
/// whatever owns that [Stack], since this widget reads no state of its own.
///
/// [NavBar] is the pill only and does not position itself, because how far
/// it must sit above the system gesture area is a property of the screen,
/// not of the bar. This is that property: [MediaQuery.viewPaddingOf] reads
/// the real inset rather than a hardcoded one, so a device reporting zero
/// bottom padding (no home indicator) does not leave the pill floating
/// clear of nothing.
class MainNavBar extends StatelessWidget {
  /// Creates the main nav bar.
  const MainNavBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// The index of the active destination: 0 for Home, 1 for
  /// Notifications, 2 for Settings.
  final int selectedIndex;

  /// Called with the tapped destination's index.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dimensions = DimensionExtension.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + dimensions.space16,
      child: Center(
        child: NavBar(
          items: const [
            NavBarItem(icon: AppIcons.home, semanticLabel: 'Home'),
            NavBarItem(
              icon: AppIcons.notifications,
              semanticLabel: 'Notifications',
            ),
            NavBarItem(icon: AppIcons.settings, semanticLabel: 'Settings'),
          ],
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ),
    );
  }
}
