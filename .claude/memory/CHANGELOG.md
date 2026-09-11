- **D-7** (2026-09-11) — **`report` is the only method an implementation
  writes.** `reportHandled` is concrete on `ErrorReporter` and funnels into
  `report(error, error.stackTrace ?? StackTrace.empty, handled: true,
  handledAt: ...)`; `handled` is what tells the two lanes apart. One decision
  point for formatting and destination instead of two overrides that drift —
  the drift being exactly how the riverpod variant ended up reporting a
  handled failure down both lanes (D-5). `NoopErrorReporter` and
  `ConsoleErrorReporter` therefore **`extends`** rather than `implements`:
  `implements` takes the interface and not the implementation, which would
  put the funnel back on every subclass to reproduce. `ErrorReporter` gained
  a `const` constructor so both stay `const`. The README's vendor sample
  changed with it. Pinned by *"reportHandled funnels into report as the
  handled lane"* in `packages/core/test/error_handling_test.dart`, and by the
  `_RecordingReporter`s, which now override `report` alone and so record the
  lane the funnel actually chose.


- **D-5** (2026-09-11) — `ConsoleErrorReporter.reportHandled` logs
  `handled: $error`, not `handled: <Type>(code: <code>)`. A breadcrumb still
  carries no stack trace and is never filed as a crash — but it has to name
  what failed, and the old line did not: the shipped `UnimplementedError` stub
  in `OnboardingRepository.login` printed `handled: UnknownException(code:
  null)`, which identifies nothing. `AppException.toString()` already carries
  `message`, `code` **and** `cause`, so the fix is one interpolation and the
  wrapped `UnimplementedError` finally appears. Pinned by *"the mapped
  exception names its cause, for the breadcrumb"* in
  `packages/core/test/error_handling_test.dart`.


## 2026-09-11 archived from MEMORY.md

- **D-6** (2026-09-11) — A handled-failure breadcrumb carries **both ends**:
  `reportHandled` took a `{StackTrace? handledAt}` and `handleBlocAction` passes
  `StackTrace.current`. `ConsoleErrorReporter` prints `thrown at:` (frame 0 of
  `AppException.stackTrace`, verbatim — `guard` rethrows with
  `Error.throwWithStackTrace`, so frame 0 *is* the throw site, including when
  that site is `ApiClient` inside `core`) and `handled at:` (the first frame
  that is not plumbing). Counting breadcrumbs says how often something breaks;
  the pair says what is already absorbing it, which is what decides whether to
  act. The formatting is a public `ConsoleErrorReporter.formatHandled`
  precisely so a test can assert it — `dart:developer`'s sink is not
  observable from a test. See G-8.


# Memory archive — bp-riverpod

Append-only history trimmed out of `MEMORY.md`. Newest block first.

This file is **deliberately not imported** into `CLAUDE.md`, so it may grow
without bound and costs nothing per session. `grep -n` it when you need history
that `MEMORY.md` no longer carries.

Rules: content arrives here **verbatim** — never edit an archived entry, never
delete from this file, and never archive something whose durable content has
not first been promoted into `MEMORY.md`'s Requirements, Decisions, Gotchas,
Feature Map or Component Index.

## 2026-09-10 archived from MEMORY.md

Superseded by the revised D-4 of the same date: `bootstrap` now owns the
reporter instance end to end, so there is one door rather than two and
`configureInjection` keeps its original signature.

- **D-4** (2026-09-08) — `ErrorReporter` reaches its consumers through get_it,
  not through the `appErrorReporter` global (deleted). It enters through **two
  doors on purpose**, because they open at different times:
  `bootstrap(reporter:)` installs the crash lane *before* `initializer()`
  configures DI — a failure inside DI configuration is the crash you most need
  reported, and that lane therefore cannot resolve anything from the
  injector — and `configureInjection(reporter:)` then registers **that same
  object** with `injector.registerSingleton<ErrorReporter>`, so
  `handleBlocAction` and any constructor-injected consumer get the identical
  instance. `main_<flavor>.dart` builds it once and passes it to both.
  It is deliberately **not** annotated: lazy or eager,
  `@LazySingleton(as: ErrorReporter, env: [...])` means *injectable* calls the
  constructor, and `main` still needs an instance before DI exists — so an
  annotation yields two objects for one type, with the crash lane reporting to
  one and the handled lane to the other. Flavor scoping lives in the flavor's
  own `main` instead of in `env:`. A pre-registered type resolves like any
  other, so future consumers can take `ErrorReporter` in an `@injectable`
  constructor with no further wiring.

<!-- archived blocks below, newest first -->
