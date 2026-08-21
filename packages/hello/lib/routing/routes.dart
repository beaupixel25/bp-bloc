import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/app/view/home_page.dart';
import 'package:hello/app/view/launch_page.dart';
import 'package:hello/app/view/notifications_page.dart';
import 'package:hello/app/view/settings_page.dart';
import 'package:hello/common/widgets/main_nav_bar/main_nav_bar.dart';
import 'package:hello/features/onboarding/presentation/routing/onboarding_routes.dart';

part 'routes.g.dart';

/// Typed route for [LaunchPage], the app's cold start.
///
/// The destination arrives as a callback rather than being named here, so
/// `launch_page.dart` imports no route and deleting a feature cannot reach
/// it. Landing is reached by path (`context.go('/landing')`), never by
/// naming `LandingRoute`: that class lives in the onboarding feature, and
/// the BLoC variant has no `LandingRoute` at all — only a redirect at that
/// path. [HomeRoute] is app-owned, so it stays typed.
@TypedGoRoute<LaunchRoute>(path: '/')
class LaunchRoute extends GoRouteData with $LaunchRoute {
  /// Creates the launch route.
  const LaunchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => LaunchPage(
        onResolved: (isSignedIn) => isSignedIn
            ? const HomeRoute().go(context)
            : context.go('/landing'),
      );
}

/// Chrome for the signed-in shell: [MainNavBar] over the branch content in
/// a [Stack], built once outside the branch subtree so switching tabs never
/// rebuilds the bar — only the active branch's own content responds.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            navigationShell,
            MainNavBar(
              selectedIndex: navigationShell.currentIndex,
              onSelected: (index) => navigationShell.goBranch(
                index,
                // Re-tapping the active tab pops it to its branch root.
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ],
        ),
      );
}

/// Shell hosting the signed-in experience: three tabs, each keeping its own
/// navigation stack across switches. App-wide chrome (the bottom nav bar)
/// lives in [_MainShell], built once outside the branch subtree.
///
/// Branch order is the bar's order. [MainNavBar] hands `goBranch` the index
/// it was tapped with and nothing reconciles the two lists, so inserting a
/// destination in one without the other silently routes a tab to its
/// neighbour's page.
final StatefulShellRoute $mainRoute = StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      _MainShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [$homeRoute]),
    StatefulShellBranch(routes: [$notificationsRoute]),
    StatefulShellBranch(routes: [$settingsRoute]),
  ],
);

/// Typed route for [HomePage], hosted inside the main shell route.
@TypedGoRoute<HomeRoute>(path: '/main')
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// Typed route for [NotificationsPage], hosted inside the main shell route.
@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  /// Creates the notifications route.
  const NotificationsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationsPage();
}

/// Typed route for [SettingsPage], hosted inside the main shell route.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates the settings route.
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

/// Every route in the app. `app.dart` reads this and nothing else, so adding
/// or removing a feature never touches the app root.
final List<RouteBase> appRoutes = [
  $launchRoute,
  ...onboardingRoutes, // ← delete this line with the onboarding feature
  $mainRoute,
];
