import 'dart:developer';

import 'package:core/src/domain/exceptions/app_exception.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Vendor-agnostic crash/error sink.
///
/// `core` never depends on a concrete crash reporter (Sentry, Crashlytics,
/// ...). `bootstrap` owns the instance: it constructs a
/// [ConsoleErrorReporter] unless an app passes its own, installs it in the
/// global error net, and registers it in the app's container so the handled
/// lane resolves the very same object.
abstract class ErrorReporter {
  /// Allows the shipped reporters to stay `const`.
  const ErrorReporter();

  /// Reports [error] with its [stackTrace] to the backing service.
  ///
  /// **The single method an implementation writes.** Both lanes arrive here;
  /// [handled] is what tells them apart, so the decision about how to format
  /// and where to send lives in one place instead of being duplicated across
  /// two overrides that drift.
  ///
  /// `handled: false` — nothing turned this into state, so it is a crash, and
  /// [stackTrace] is where it was thrown. `handled: true` — it arrived via
  /// [reportHandled]: [stackTrace] is still the throw site (or
  /// `StackTrace.empty` if the exception carried none) and [handledAt] is the
  /// presentation code that absorbed it.
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    bool handled = false,
    StackTrace? handledAt,
    StackTrace? invokedAt,
  });

  /// Reports a failure that was handled and shown to the user.
  ///
  /// Handled failures are not crashes — someone read a sentence and the app
  /// carried on — but a 5xx that a user experienced as generic copy is still a
  /// defect, and nothing else in the app would ever tell you it happened.
  /// Implementations should record these as breadcrumbs rather than as issues.
  ///
  /// [handledAt] is the presentation code that absorbed the failure. It
  /// answers a different question from [AppException.stackTrace], which is
  /// where the failure was *thrown*: together they say how often something
  /// breaks and what is currently absorbing it, which is what tells you
  /// whether the absorbing is good enough.
  ///
  /// [handledAt] is captured inside the `on AppException` catch, so its
  /// frame 0 is the handler. [invokedAt] is captured where the action was
  /// **started**, which is a third thing again: the `signup.execute(...)`
  /// that set it off. It needs its own capture because an async stack trace
  /// records only the frames that are awaiting, and a view model method that
  /// returns the future without awaiting is gone from the catch-time trace.
  ///
  /// Concrete on purpose: it funnels into [report] with `handled: true`, so a
  /// vendor implementation overrides one method and `extends` this class.
  /// `StackTrace.empty` when the exception carries no trace — [report] then
  /// has nothing to claim as a throw site, which is honest.
  Future<void> reportHandled(
    AppException error, {
    StackTrace? handledAt,
    StackTrace? invokedAt,
  }) =>
      report(
        error,
        error.stackTrace ?? StackTrace.empty,
        handled: true,
        handledAt: handledAt,
        invokedAt: invokedAt,
      );
}

/// An [ErrorReporter] that discards everything.
///
/// Not the default — [ConsoleErrorReporter] is. Use this where reporting is
/// noise rather than signal: a test that exercises a failure on purpose, or a
/// flavor running against a fake backend.
class NoopErrorReporter extends ErrorReporter {
  /// Creates a [NoopErrorReporter].
  const NoopErrorReporter();

  // `extends`, not `implements`: one override, and `reportHandled` keeps the
  // funnel it inherits. `implements` would take the interface and not the
  // implementation, putting both methods back.
  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    bool handled = false,
    StackTrace? handledAt,
    StackTrace? invokedAt,
  }) async {}
}

/// An [ErrorReporter] that writes to the developer log. What `bootstrap`
/// constructs when an app passes no reporter of its own.
///
/// The single swap point for a real backend: pass
/// `reporter: const SentryErrorReporter()` to `bootstrap` and every reporting
/// site in the app follows, because nothing else names a reporter.
///
/// A default that logs rather than one that discards: a generated app runs
/// with no backend either way, but this one tells you a crash happened.
class ConsoleErrorReporter extends ErrorReporter {
  /// Creates a [ConsoleErrorReporter].
  ///
  /// [colored] defaults to [kDebugMode] — on where a human is reading a
  /// console, off in release where the log is a file or a crash service and
  /// escape codes are noise. Pass `false` to turn it off anyway: a debug
  /// build on a device logs to logcat, which prints the codes literally.
  const ConsoleErrorReporter({this.colored = kDebugMode});

  /// Whether the frame lines are wrapped in ANSI colour.
  final bool colored;

  // One override for both lanes — see [ErrorReporter.report]. The crash lane
  // hands `log` the stack trace; the handled lane never does, and folds what
  // matters into the message instead.
  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    bool handled = false,
    StackTrace? handledAt,
    StackTrace? invokedAt,
  }) async {
    if (!handled) {
      log('crash: $error', name: 'ErrorReporter', stackTrace: stackTrace);
      return;
    }
    log(
      formatHandled(
        error,
        thrownAt: stackTrace,
        handledAt: handledAt,
        invokedAt: invokedAt,
      ),
      name: 'ErrorReporter',
    );
  }

  /// The message [report] logs for a handled failure.
  ///
  /// A breadcrumb, not an issue: the user read a sentence and carried on, so
  /// no stack trace and no crash. It still has to be actionable, and three
  /// things make it so. `AppException.toString()` carries the message and the
  /// wrapped cause, so the line names the real failure rather than
  /// `UnknownException(code: null)`. `thrown at` says where it came from.
  /// `handled at` says what absorbed it — the half that tells you whether the
  /// handling is good enough, or whether this is a defect everybody has
  /// learned to live with.
  ///
  /// Public so a test can assert on it. `dart:developer`'s sink is not
  /// observable from a test, and a breadcrumb that names the plumbing rather
  /// than the screen is worse than no breadcrumb — nothing else would catch
  /// that.
  String formatHandled(
    Object error, {
    StackTrace? thrownAt,
    StackTrace? handledAt,
    StackTrace? invokedAt,
  }) {
    final rows = [
      if (_frame(thrownAt) case final f?) 'thrown at:  $f',
      if (_frame(handledAt) case final f?) 'handled at: $f',
      if (_callSiteFrame(invokedAt) case final f?) 'invoked at: $f',
    ];
    // Tree markers rather than an indent. `dart:developer` hands the console
    // one multi-line string; a console is free to strip leading whitespace,
    // and anything else logging concurrently interleaves the lines. `└─` on
    // the last row is also what says the group ended. Colour is the same
    // argument by other means, and degrades to nothing when switched off.
    return [
      'handled: $error',
      for (var i = 0; i < rows.length; i++)
        _paint('${i == rows.length - 1 ? '└─' : '├─'} ${rows[i]}'),
    ].join('\n');
  }

  /// Colours [text] when [colored] is on.
  String _paint(String text) =>
      colored ? '$_ansiWhite$text$_ansiReset' : text;
}

/// One colour for all three rows: what they need to say is "we belong to
/// the line above", and three colours said "we differ from each other".
const _ansiWhite = '\x1B[37m';

/// Ends a colour run. Every painted line closes with it, so a truncated log
/// cannot leak colour into whatever is printed next.
const _ansiReset = '\x1B[0m';

/// Frame 0 of [trace], or null when there is none.
///
/// Neither end of the breadcrumb is filtered; both are frame 0. For the
/// origin that is the throw site, because `BaseRepository.guard` rethrows
/// with `Error.throwWithStackTrace` — including when the thrower is inside
/// `core`, as everything `ApiClient` raises is. For the handling site the
/// caller captures inside its `on AppException` block, so frame 0 is that
/// block: the code that actually handled the failure.
String? _frame(StackTrace? trace) {
  final frames = _frames(trace);
  return frames.isEmpty ? null : frames.first;
}

/// The app code that *started* the action, for `invoked at:`.
///
/// The one frame that is filtered, and it has to be: whoever captured
/// `invokedAt` is itself the top of that trace, so frame 0 is always the
/// helper rather than its caller. Skips `core` and the state-management
/// framework, then takes the first frame left; falls back to frame 0 when
/// nothing is left, which beats saying nothing.
String? _callSiteFrame(StackTrace? trace) {
  final frames = _frames(trace);
  if (frames.isEmpty) return null;
  return frames.firstWhere(
    (frame) => !_plumbingFrames.any(frame.contains),
    orElse: () => frames.first,
  );
}

/// Frames of [trace] with their `#<n>` numbering stripped.
///
/// Text parsing because that is the only shape a [StackTrace] has. Anything
/// unrecognised drops out rather than throwing: a breadcrumb must never be
/// the thing that fails.
List<String> _frames(StackTrace? trace) {
  if (trace == null) return const [];
  return trace
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('#'))
      .map((line) => line.replaceFirst(RegExp(r'^#\d+\s+'), ''))
      .toList();
}

/// Frame locations [_callSiteFrame] steps over to reach app code.
///
/// Matched including the opening paren, because a frame reads
/// `Member (<uri>:<line>:<col>)` — a bare `dart:` would match the `.dart:`
/// ending every file path there is, making every frame plumbing.
const _plumbingFrames = [
  '(package:core/',
  '(dart:',
];
