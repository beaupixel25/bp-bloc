import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hello/app/bloc/app_bloc.dart';

/// {@template launch_page}
/// The app's cold start, shown at `/`.
///
/// Composes the brand mark while the app-wide state holder resolves whether
/// a session can be restored. It dissolves the instant the destination is
/// ready, and [onResolved] fires exactly once, at that same frame — not at
/// the end of the sequence, so the dissolve never plays against a page that
/// has not been built yet.
///
/// This page owns no destination: it takes one as a callback, so deleting a
/// feature can never reach it — see the routing comment on `LaunchRoute`.
/// {@endtemplate}
class LaunchPage extends StatefulWidget {
  /// {@macro launch_page}
  const LaunchPage({required this.onResolved, super.key});

  /// The brand mark's key, so the timeline test has a handle on it that
  /// does not depend on Material's own widget tree.
  @visibleForTesting
  static const Key markKey = Key('launchMark');

  /// The bento layer's key. The cluster is four tiles that come and go on
  /// overlapping beats, so the test asserts against the layer rather than
  /// trying to name a tile that may already have cleared.
  @visibleForTesting
  static const Key bentoKey = Key('launchBento');

  /// Where the brand lockup sits, on this page and on the landing page.
  ///
  /// Above centre, not on it, because the landing anchors the same lockup in
  /// the same place and needs the lower third for its sheet — centred, the
  /// sheet would sit on the mark on a small phone. Both pages read this one
  /// constant so the mark does not move across the route change; change it
  /// here and `LandingPage` follows, which is the point.
  static const Alignment lockupAlignment = Alignment(0, -0.22);

  /// Called once, with whether a previous session was restored.
  final ValueChanged<bool> onResolved;

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage>
    with SingleTickerProviderStateMixin {
  static const int _totalMs = 3400;
  static const int _syncPointMs = 2950;

  /// Reduced motion holds the settled frame rather than compressing to a
  /// blink: the sequence still runs, at roughly a quarter speed, so the
  /// hand-off lands near 780ms.
  static const int _reducedMotionMs = 900;

  /// How long the hand-off will wait for the startup load past the sync point
  /// before going anyway. Equal to `_totalMs` so the wait can never outlast the
  /// animation the user is watching: past this the brand has fully dissolved
  /// and there is nothing left on screen to justify holding.
  static const int _maxWaitMs = _totalMs;
  static const String _markAsset = 'assets/brand/brand_logo.svg';
  static const String _wordmarkAsset = 'assets/brand/wordmark.svg';

  /// The line the hold reads out, one word at a time.
  ///
  /// Its length drives the stagger: the last word starts at
  /// `_taglineFromMs + (length - 1) * _taglineStrideMs` and runs for
  /// `_taglineSpanMs`, so a longer line finishes later. At five words the
  /// last one lands on 2390ms, comfortably before `_taglineOut` begins.
  /// Add words and that headroom is what you spend.
  static const List<String> _taglineWords = <String>[
    'Built',
    'right',
    'from',
    'the',
    'start.',
  ];
  static const int _taglineFromMs = 1490;
  static const int _taglineStrideMs = 130;
  static const int _taglineSpanMs = 380;

  /// The bento cluster: four tiles that scale up from their bottom-left
  /// corners, three of which recede again, leaving the one the mark
  /// resolves inside.
  ///
  /// Positions are fractions of the safe area, not the logical pixels the
  /// design measured on a 390x844 canvas — those do not survive a small
  /// phone or a tablet, and this is the one composition on screen with
  /// nothing else to anchor against.
  static const List<_BentoTile> _bentoTiles = <_BentoTile>[
    _BentoTile(
      left: 0.062,
      top: 0.185,
      width: 0.354,
      height: 0.140,
      radius: 20,
      inFromMs: 20,
      outFromMs: 480,
      outToMs: 840,
    ),
    _BentoTile(
      left: 0.585,
      top: 0.220,
      width: 0.354,
      height: 0.114,
      radius: 20,
      inFromMs: 100,
      outFromMs: 540,
      outToMs: 900,
      isDim: true,
    ),
    _BentoTile(
      left: 0.118,
      top: 0.554,
      width: 0.431,
      height: 0.128,
      radius: 20,
      inFromMs: 180,
      outFromMs: 600,
      outToMs: 960,
    ),
    // The centre tile. It holds under the mark for another 260ms after its
    // three neighbours have gone, then clears — that overlap is the whole
    // point of the variant, so retiming it to match the others collapses
    // the assembly into a plain fade.
    _BentoTile(
      left: 0.305,
      top: 0.338,
      width: 0.390,
      height: 0.180,
      radius: 30,
      inFromMs: 180,
      outFromMs: 860,
      outToMs: 1120,
      isDim: true,
    ),
  ];

  late final AnimationController _controller;
  late final List<Animation<double>> _bentoIn;
  late final List<Animation<double>> _bentoGrow;
  late final List<Animation<double>> _bentoOut;
  late final Animation<double> _markIn;
  late final Animation<double> _wordmarkIn;
  late final List<Animation<double>> _taglineIn;
  late final Animation<double> _taglineOut;
  late final Animation<double> _surfaceIn;

  bool _started = false;
  bool _handedOff = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addListener(_onTick);

    // Stage one, the bento assembly. Each tile fades over 260ms while it
    // grows over 440ms, so it is fully opaque a little before it stops
    // moving — collapsing the two into one interval is what makes the
    // cluster read as a fade instead of an assembly.
    _bentoIn = <Animation<double>>[
      for (final tile in _bentoTiles)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            tile.inFromMs / _totalMs,
            (tile.inFromMs + 260) / _totalMs,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];
    _bentoGrow = <Animation<double>>[
      for (final tile in _bentoTiles)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            tile.inFromMs / _totalMs,
            (tile.inFromMs + 440) / _totalMs,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];
    _bentoOut = <Animation<double>>[
      for (final tile in _bentoTiles)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            tile.outFromMs / _totalMs,
            tile.outToMs / _totalMs,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];

    // 520-1000: the mark resolves inside the centre tile while that tile is
    // still up, which is what ties the two together.
    _markIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        520 / _totalMs,
        1000 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );
    // 700-1140: starts while the mark is still settling, so the two read as
    // one gesture rather than two. Its own beat, because the spec names it.
    _wordmarkIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        700 / _totalMs,
        1140 / _totalMs,
        curve: Curves.easeOut,
      ),
    );

    // Stage two, the hold. One beat per word on a 130ms stride: reading the
    // line is what the hold is for, so the words are the beat, not decoration
    // on top of one.
    _taglineIn = <Animation<double>>[
      for (var i = 0; i < _taglineWords.length; i++)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (_taglineFromMs + i * _taglineStrideMs) / _totalMs,
            (_taglineFromMs + i * _taglineStrideMs + _taglineSpanMs) /
                _totalMs,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];
    // Clears with 20ms to spare before the sync point, so the frame the
    // landing page inherits carries the lockup and nothing else.
    _taglineOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        2610 / _totalMs,
        2930 / _totalMs,
        curve: Curves.easeOutCubic,
      ),
    );

    // Ends *on* the sync point, never after it: this is the clock the
    // hand-off reads, and a destination that is not ready by the frame the
    // brand stops moving is the seam every rule here exists to prevent.
    _surfaceIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        2600 / _totalMs,
        _syncPointMs / _totalMs,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not initState: MediaQuery is not reachable until dependencies
    // have been hooked up.
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    unawaited(_start());
  }

  /// Warms up, then starts the controller — compressed to
  /// `_reducedMotionMs` when the platform asks for reduced motion, so the
  /// same three beats still run, just fast enough to read as immediate.
  Future<void> _start() async {
    await _warmUp().timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () {},
    );
    if (!mounted) return;

    if (_reduceMotion) {
      _controller.duration = const Duration(
        milliseconds: _reducedMotionMs,
      );
    }
    unawaited(_controller.forward());
  }

  /// Precaches the brand mark, best-effort. A missing or corrupt asset must
  /// cost this beat, never the whole launch — [_start] caps the wait.
  Future<void> _warmUp() async {
    try {
      // Both futures are created before either is awaited, so `context` is
      // read once, synchronously — awaiting one and then touching context
      // again trips use_build_context_synchronously.
      await Future.wait([
        AppIcon.precache(_markAsset, context),
        AppIcon.precache(_wordmarkAsset, context),
      ]);
    } on Object {
      // A mark that failed to decode simply paints late, or not at all.
    }
  }

  /// Fires [LaunchPage.onResolved] once, the frame the destination is
  /// ready — never at [AnimationStatus.completed]: waiting for the
  /// dissolve to finish would show it against a page that has not been
  /// built yet.
  ///
  /// Two conditions, not one. The sync point says the destination is opaque;
  /// the startup load says the answer to *which* destination is final. Reading
  /// the flag on the animation clock alone means a slow session restore has
  /// not answered yet, and a signed-in user is sent to the signed-out
  /// destination with nothing to indicate it went wrong.
  ///
  /// `_maxWaitMs` caps that wait, in the same spirit as the asset warm-up: a
  /// startup that never settles must cost a beat, not the whole app. When it
  /// trips, the launch hands off with whatever the flag says — which is the
  /// signed-out default, the safe direction to be wrong in.
  void _onTick() {
    if (_handedOff || _surfaceIn.value < 1) return;
    final waitedTooLong = _controller.lastElapsedDuration != null &&
        _controller.lastElapsedDuration!.inMilliseconds >= _maxWaitMs;
    // Wrapped: the BLoC expression is 86 characters on one line, and the
    // generated project lints anything over 80.
    final startupSettled =
        context.read<AppBloc>().state.status != BlocStatus.loading;
    if (!startupSettled && !waitedTooLong) return;
    _handedOff = true;
    widget.onResolved(context.read<AppBloc>().state.isSignedIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// One bento tile, positioned against [constraints] and driven by its own
  /// three beats.
  ///
  /// Opacity is the *minimum* of arriving and leaving rather than a single
  /// value, because a tile's in and out windows are independent — the centre
  /// one is still fading up long after its neighbours have started to go.
  Widget _bentoTileAt(
    int index,
    BoxConstraints constraints,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tile = _bentoTiles[index];
    final fade = _bentoIn[index];
    final grow = _bentoGrow[index];
    final clear = _bentoOut[index];
    // The design's own two-step wash, read off the theme rather than the
    // literal white it used: a light launch frame needs the darker pair or
    // the cluster is invisible.
    final alpha =
        isDark ? (tile.isDim ? 0.07 : 0.10) : (tile.isDim ? 0.05 : 0.08);

    return Positioned(
      left: tile.left * constraints.maxWidth,
      top: tile.top * constraints.maxHeight,
      width: tile.width * constraints.maxWidth,
      height: tile.height * constraints.maxHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final arriving = fade.value;
          final leaving = 1 - clear.value;
          final opacity = arriving < leaving ? arriving : leaving;
          if (opacity <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: opacity,
            // Bottom-left, matching the design's transform origin. Scaling
            // from the centre reads as a pop; scaling from the corner reads
            // as the tile being drawn, which is the whole gesture.
            child: Transform.scale(
              scale: grow.value,
              alignment: Alignment.bottomLeft,
              child: child,
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(tile.radius),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dimensions = DimensionExtension.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Matches both the native launch frame and the destination, so
      // there is nothing to clear — this is why there is no groundOut
      // beat.
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Its own boundary: four tiles animating independently must not
            // drag the lockup into their repaints.
            RepaintBoundary(
              key: LaunchPage.bentoKey,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: <Widget>[
                    for (var i = 0; i < _bentoTiles.length; i++)
                      _bentoTileAt(i, constraints, colorScheme, isDark),
                  ],
                ),
              ),
            ),
            // The lockup, and *only* the lockup. Two things are load-bearing
            // here, and both are about the frame the landing page inherits.
            //
            // The alignment is `lockupAlignment`, not `Alignment.center`,
            // because `LandingPage` anchors the identical two children to
            // the identical constant — it cannot centre them, since its
            // sheet would sit on top of the mark on a small phone. Same
            // constant on both pages is what makes the mark not move across
            // the route change.
            //
            // The tagline is aligned separately below rather than sharing
            // this Column, because this Column's height is what decides
            // where that anchor puts the mark. Fold the tagline in and the
            // mark rides 30-odd pixels higher on the launch than on the
            // landing — the jump rule 9 is about.
            RepaintBoundary(
              child: Align(
                alignment: LaunchPage.lockupAlignment,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _markIn,
                      child: ScaleTransition(
                        // Keyed so the timeline test can read markIn's
                        // scale without walking the widget tree: Scaffold
                        // builds its own ScaleTransition for the
                        // floating-action-button slot even when there is
                        // no button, so any find.byType search has to
                        // dodge Material's internals to reach this one.
                        key: LaunchPage.markKey,
                        scale: Tween<double>(
                          begin: 0.88,
                          end: 1,
                        ).animate(_markIn),
                        // Tinted, like the wordmark beside it. The shipped
                        // mark is drawn in black with its counters as
                        // transparent holes, so on a dark launch frame an
                        // untinted mark is invisible — `srcIn` repaints the
                        // lozenges and leaves the holes showing the ground,
                        // which is what the counters are for. A brand whose
                        // mark is genuinely multi-colour should drop this
                        // filter here and on the landing page together.
                        child: SvgPicture.asset(
                          _markAsset,
                          height: 88,
                          colorFilter: ColorFilter.mode(
                            colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: dimensions.space24),
                    // Its own beat: fades up and lifts into place, starting
                    // while the mark is still settling. 28 logical pixels,
                    // matching the landing page exactly — the two lockups
                    // are the same frame either side of a route change, and
                    // a size that differs by even a few pixels is a jump.
                    FadeTransition(
                      opacity: _wordmarkIn,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(_wordmarkIn),
                        child: SvgPicture.asset(
                          _wordmarkAsset,
                          height: 28,
                          colorFilter: ColorFilter.mode(
                            colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Two fades, deliberately not compounded: each word arrives on
            // its own beat, the group leaves on `taglineOut`, and the
            // windows never overlap — the last word lands on 2390ms, the
            // clear begins at 2610. Give the words their own exit as well
            // and the line double-dips and finishes early.
            RepaintBoundary(
              child: Align(
                alignment: const Alignment(0, 0.04),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimensions.space24,
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 1,
                      end: 0,
                    ).animate(_taglineOut),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: <Widget>[
                        for (var i = 0; i < _taglineWords.length; i++)
                          FadeTransition(
                            opacity: _taglineIn[i],
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.4),
                                end: Offset.zero,
                              ).animate(_taglineIn[i]),
                              child: Text(
                                _taglineWords[i],
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tile in the launch's bento cluster: where it sits, how big it is, and
/// the three moments that own it.
///
/// [left], [top], [width] and [height] are fractions of the safe area, so the
/// cluster keeps its proportions on any screen. [isDim] picks the lighter of
/// the design's two washes.
@immutable
class _BentoTile {
  const _BentoTile({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.radius,
    required this.inFromMs,
    required this.outFromMs,
    required this.outToMs,
    this.isDim = false,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double radius;
  final int inFromMs;
  final int outFromMs;
  final int outToMs;
  final bool isDim;
}
