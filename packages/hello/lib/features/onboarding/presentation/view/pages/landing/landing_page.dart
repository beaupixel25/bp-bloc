import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hello/features/onboarding/presentation/routing/onboarding_routes.dart';

/// {@template landing_page}
/// The first screen an unauthenticated user sees: the brand lockup, and a
/// sheet carrying the welcome copy and the two calls to action.
///
/// This is the launch sequence's third stage, and it is deliberately *not* a
/// new composition. The lockup arrives already at rest — same mark, same
/// wordmark, same size, anchored to the same alignment the launch page uses
/// (`LaunchPage.lockupAlignment`, mirrored below) — so the route change from
/// `/` to `/landing` moves nothing that was already on screen. Fading it up
/// from zero here, against a launch that ended at full opacity, is a blink
/// rather than a reveal; that is why the lockup has no beat of its own.
///
/// What does animate is everything the launch never drew: the ambient wash
/// settling out of a 1.05 scale, then the sheet lifting 26 logical pixels
/// from the bottom edge with its five rows staggering in behind it on a
/// 90ms stride. 1450ms end to end, matching the design's stage-3 window.
///
/// The timeline starts fresh every time this page is built — never a
/// continuation of the launch page's controller. Arriving here from the
/// launch and arriving via the home page's "Start over" both build a new
/// [LandingPage], and both should look the same.
/// {@endtemplate}
class LandingPage extends StatefulWidget {
  /// {@macro landing_page}
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  static const int _totalMs = 1450;

  /// Where the brand lockup sits.
  ///
  /// **This must equal `LaunchPage.lockupAlignment`.** It is duplicated
  /// rather than imported so the onboarding feature does not reach up into
  /// `app/view/` for one constant — deleting this feature has to stay a
  /// feature-local operation, and it cannot be if the launch page is on the
  /// other end of an import.
  ///
  /// Nothing in the generated project enforces the equality, because the two
  /// files are meant to be independently deletable. Move one and the mark
  /// jumps at the hand-off; the symptom is subtle and the cause is here.
  static const Alignment _lockupAlignment = Alignment(0, -0.22);

  /// Placeholder. Swap for `package_info_plus` when the app needs a real
  /// build label — the row exists so the layout already has a slot for it.
  static const String _versionLabel = 'v1.0.0 · release';

  late final AnimationController _controller;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroSettle;
  late final Animation<double> _sheetFade;
  late final Animation<double> _sheetLift;
  late final Animation<double> _revealTitle;
  late final Animation<double> _revealBody;
  late final Animation<double> _revealLogin;
  late final Animation<double> _revealSignup;
  late final Animation<double> _revealVersion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // The wash arrives faster than it stops moving, so it is fully painted
    // while still settling — the same relationship the launch's bento tiles
    // have between their fade and their growth.
    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        60 / _totalMs,
        500 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );
    _heroSettle = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        60 / _totalMs,
        860 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );

    _sheetFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        140 / _totalMs,
        700 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );
    _sheetLift = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        140 / _totalMs,
        920 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );

    // One beat per row, on a 90ms stride, in the order they are drawn. The
    // stagger has to run top-to-bottom: assign it the other way round and the
    // sheet reads as settling backwards.
    Animation<double> row(int fromMs) => CurvedAnimation(
          parent: _controller,
          curve: Interval(
            fromMs / _totalMs,
            (fromMs + 380) / _totalMs,
            curve: Curves.easeOutCubic,
          ),
        );
    _revealTitle = row(520);
    _revealBody = row(610);
    _revealLogin = row(700);
    _revealSignup = row(790);
    _revealVersion = row(880);

    unawaited(_controller.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion collapses the reveal to its resting state instead of
    // compressing it: nothing external waits on a beat boundary here the
    // way the launch page's onResolved does, so there is no timing to keep.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fades [child] in with [reveal], lifting it up from [dy] logical pixels
  /// below its resting position as the animation runs.
  Widget _fadeAndLift(Animation<double> reveal, double dy, Widget child) {
    return FadeTransition(
      opacity: reveal,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, dy * (1 - reveal.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dimensions = DimensionExtension.of(context);

    return Scaffold(
      // The launch page's ground, painted before anything else moves, so the
      // frame this page opens on is the frame the launch page closed on. The
      // wash below fades in on top of it and therefore cannot flash.
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // The design's full-bleed hero photograph, rendered as the ambient
          // wash instead: same job in the composition, with nothing to ship
          // and nothing to re-license per brand. It grounds on
          // `colorScheme.surface` as well, so the fade is wash-over-ground,
          // never wash-over-nothing.
          RepaintBoundary(
            child: FadeTransition(
              opacity: _heroFade,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.05,
                  end: 1,
                ).animate(_heroSettle),
                child: const AmbientBackdrop(child: SizedBox.expand()),
              ),
            ),
          ),
          // At rest from the first frame — no fade, no lift. See the class
          // dartdoc: this is the one thing the launch page hands over still,
          // and animating it is what turns a hand-off into a blink.
          RepaintBoundary(
            child: SafeArea(
              child: Align(
                alignment: _lockupAlignment,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tinted to match the launch page exactly — see the note
                    // there. An untinted black mark disappears on a dark
                    // surface, and the two pages have to agree anyway.
                    SvgPicture.asset(
                      'assets/brand/brand_logo.svg',
                      height: 88,
                      colorFilter: ColorFilter.mode(
                        colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                      semanticsLabel: 'The app icon',
                    ),
                    SizedBox(height: dimensions.space24),
                    SvgPicture.asset(
                      'assets/brand/wordmark.svg',
                      height: 28,
                      colorFilter: ColorFilter.mode(
                        colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                      semanticsLabel: 'The app name',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // The sheet: lifts 26 logical pixels off the bottom edge while its
          // five rows stagger in behind it.
          Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _sheetFade,
                child: AnimatedBuilder(
                  animation: _sheetLift,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 26 * (1 - _sheetLift.value)),
                    child: child,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        dimensions.space24,
                        0,
                        dimensions.space24,
                        dimensions.space24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fadeAndLift(
                            _revealTitle,
                            12,
                            Text(
                              'Ready when you are.',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(height: dimensions.space12),
                          _fadeAndLift(
                            _revealBody,
                            12,
                            Text(
                              'Your account carries your projects, timelines '
                              'and files across every device. No setup, no '
                              'guesswork.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(height: dimensions.space24),
                          // "Log in" above "Create account", following the
                          // design: the returning user is the common case, so
                          // the quieter treatment sits on top and the stagger
                          // reaches it first.
                          _fadeAndLift(
                            _revealLogin,
                            12,
                            PillButton(
                              label: 'Log in',
                              theme: PillButtonThemeData.fallback(
                                context,
                                variant: PillButtonVariant.secondary,
                              ),
                              onPressed: () =>
                                  const LoginRoute().push<void>(context),
                            ),
                          ),
                          SizedBox(height: dimensions.space12),
                          _fadeAndLift(
                            _revealSignup,
                            12,
                            PillButton(
                              label: 'Create account',
                              onPressed: () =>
                                  const SignupRoute().push<void>(context),
                            ),
                          ),
                          SizedBox(height: dimensions.space16),
                          _fadeAndLift(
                            _revealVersion,
                            12,
                            Text(
                              _versionLabel,
                              textAlign: TextAlign.center,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
