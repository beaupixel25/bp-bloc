import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello/features/onboarding/presentation/view/pages/landing/landing_page.dart';
import 'package:hello/features/onboarding/presentation/view/pages/login/login_page.dart';
import 'package:hello/features/onboarding/presentation/view/pages/signup/signup_page.dart';

part 'onboarding_routes.g.dart';

/// Typed route for [LandingPage].
///
/// **No transition, deliberately.** The launch page cuts straight here at its
/// sync point, handing over a frame this page is built to inherit unchanged:
/// the same lockup, at the same size, on the same alignment. The platform
/// default would scale and fade that lockup on its way in — turning the one
/// element that is supposed to hold still into the most obvious movement on
/// screen, on top of the sheet animation this page runs itself.
@TypedGoRoute<LandingRoute>(path: '/landing')
class LandingRoute extends GoRouteData with $LandingRoute {
  /// Creates the landing route.
  const LandingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage<void>(child: LandingPage());
}

/// Typed route for [LoginPage].
///
/// Fades and lifts in rather than sliding: log in and sign up sit on one
/// continuous ground, and a horizontal slide would read as a change of place
/// rather than a change of content.
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  /// Creates the login route.
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
      );
}

/// Typed route for [SignupPage]. See [LoginRoute] for the transition.
@TypedGoRoute<SignupRoute>(path: '/signup')
class SignupRoute extends GoRouteData with $SignupRoute {
  /// Creates the signup route.
  const SignupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SignupPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
      );
}

/// Every route this feature owns. The app aggregates this list, so adding a
/// page here never touches `routing/routes.dart`.
///
final List<RouteBase> onboardingRoutes = [
  $landingRoute,
  $loginRoute,
  $signupRoute,
];
