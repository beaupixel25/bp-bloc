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
