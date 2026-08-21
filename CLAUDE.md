# bp-riverpod

A develpoment agency

Melos workspace · Clean Architecture · **flutter_bloc** · `core` exports: **full** (one barrel).

@MEMORY.md

## The four files

| File | Answers | Loaded |
|---|---|---|
| `CLAUDE.md` (this file) | *What am I required to do?* Rules and checklists. Static — it does not change as the app grows. | always |
| `MEMORY.md` | *What exists today?* Features, components, decisions, gotchas. **You keep it current** — the protocol is its own `## How to maintain this file` section. | always (imported above) |
| `README.md` | *Why is it like this?* Diagrams, startup walkthrough, code samples, Melos scripts, flavors. | on demand |
| `.claude/memory/CHANGELOG.md` | *What did we already know?* Append-only archive of everything trimmed out of `MEMORY.md`. | on demand (`grep`) |

Never copy a rule from here into `MEMORY.md`, and never record project state
here. One fact, one home.

## Project shape

| | |
|---|---|
| Apps | `packages/hello` |
| Shared | `packages/core` — bootstrap, error handling, theme, components, base classes |
| Layers | `presentation` → `domain` ← `data`, one folder per feature |
| Routing | `go_router` typed routes (`@TypedGoRoute` → `routes.g.dart`) |
| Flavors | `development` / `staging` / `production`, plus `test` |
| Codegen | `melos build` — freezed, json_serializable, go_router_builder, injectable_generator |

## Startup path

`/` is `LaunchRoute` — **app-level**, declared in `routing/routes.dart`, not
inside any feature. It composes the brand, reads `isSignedIn` off the
app-wide state holder, and hands off at a fixed sync point:

| Path | Reached by | When |
|---|---|---|
| `/` | `LaunchRoute` | always, first |
| `/landing` | `LandingRoute` (`features/onboarding/`) | `isSignedIn == false` |
| `/login`, `/signup` | `LoginRoute`, `SignupRoute` | from `/landing` |
| `/main` | `HomeRoute` → `HomePage`, branch 0 of the shell | `isSignedIn == true` |
| `/notifications` | `NotificationsRoute` → `NotificationsPage`, branch 1 | the Notifications tab |
| `/settings` | `SettingsRoute` → `SettingsPage`, branch 2 | the Settings tab |

## The signed-in shell

`$mainRoute` is a `StatefulShellRoute.indexedStack` and carries **no path of
its own** — its branches do, which is why `/main` is a path and the shell is
not. Three properties it buys, each of which someone will otherwise undo:

1. **Each branch keeps its own `Navigator` behind an `IndexedStack`.** A tab
   pushed three pages deep is still three deep when you come back to it.
2. **The chrome is built once, outside the branch subtree.** `_MainShell`
   renders `MainNavBar` over `navigationShell` in a `Stack`. Moving the bar
   into any page's `Scaffold` still looks right on screen and costs a
   rebuild and a visible flicker per switch —
   `test/routing/main_shell_test.dart` asserts the bar's *element identity*
   across a switch precisely because presence proves nothing.
3. **Re-tapping the active tab returns it to its branch root**, via
   `goBranch(i, initialLocation: i == currentIndex)`. Omit `initialLocation`
   and a re-tap silently does nothing.

`MainNavBar` names this app's destinations and positions `core`'s `NavBar` with
`MediaQuery.viewPaddingOf(context).bottom` plus a spacing token. Not a
hardcoded inset: a device with no home indicator reports zero, and a fixed
offset leaves the bar floating.

**To add a fourth tab:** a `@TypedGoRoute` for the page, a
`StatefulShellBranch(routes: [$yourRoute])` in `$mainRoute`, and a
`NavBarItem` at the **same index** in `MainNavBar` — the two lists are
positional and unreconciled, so adding to one only sends every later tab to
its neighbour's page. All three tabs live in `lib/app/view/` and import
nothing from `lib/features/`, so deleting a feature never touches them.

**The launch page names no route.** `LaunchPage` receives its destination as
a `ValueChanged<bool> onResolved` callback from `LaunchRoute` — it imports no
feature and no route class. That is what keeps deleting
`features/onboarding/` a two-file edit even though that feature owns
`/landing`.

Beats belong to whichever page is on screen when they run, not to one file.
The launch owns stages one and two — `bentoIn` → `bentoOut` → `markIn` →
`wordmarkIn` → `taglineIn` → `taglineOut` → `surfaceIn` (0–3400ms, hands off
at the 2950ms sync point). `/landing` owns stage three — `heroFade` /
`heroSettle` / `sheetFade` / `sheetLift` and five staggered `reveal*` rows
(0–1450ms, starting fresh every time it is built), a separate timeline, not a
continuation of the launch's.

**The lockup is the seam, and it does not move.** The launch's last frame is
the mark and wordmark at rest on `Alignment(0, -0.22)`; `/landing` opens on
the same two assets at the same sizes on the same alignment, with no beat of
their own. There is no `brandOut` and no `groundOut` — nothing leaves, and
both pages ground on `colorScheme.surface`. If you retime one side, the mark
jumps across the route change; that constant is duplicated in both files on
purpose (the feature must stay deletable) and `templates_test.dart` pins the
pair. Full diagram and reasoning: README's "Startup walkthrough".

## Hard rules

1. **The dependency rule is not negotiable**: `presentation` → `domain` ←
   `data`. A `presentation` file that imports `data/` is a bug, not a shortcut.
   `domain` is pure Dart — no Flutter, no HTTP, no JSON.
2. **Never hand-write generated files** — `*.g.dart`, `*.freezed.dart`, `routes.g.dart`, `inject.config.dart`.
   Run `melos build` (or `melos build:core` for a core-only change). A hand
   edit is silently reverted by the next build.
3. **Errors are typed, copy resolved in one place.** `ApiClient` types a non-2xx
   status and lifts the backend's code into `AppException.code`; `guard` types
   the rest. The UI calls `toUserMessage(AppErrorMessages(context.l10n))` — code
   first, then type. New copy is a code + ARB entry, never a second type switch.
4. **Styling comes from the theme**, never from constants in a widget. Read
   `Theme.of(context).colorScheme` / `.textTheme` or the component's
   `ThemeData`.
5. **Entities vs DTOs vs Models.** Entities have identity and live across use
   cases; DTOs cross a use-case boundary; models add serialization and live in
   `data/` only.
6. **Use Cases orchestrate, Services perform work.** Initiated by a user, API
   or job → Use Case. Reused across use cases → Service. One focused business
   capability → Domain Service. Touches an external system → Infrastructure
   Service. A Service must never invoke a Use Case. **Never a God Service.**
   (Full reasoning: README `### Use Cases vs Services`.)
7. **Route every page.** A page with no `@TypedGoRoute` in its feature's
   `presentation/routing/<feature>_routes.dart`, and no entry in that file's
   `<feature>Routes` list, is unreachable code. `lib/routing/routes.dart`
   spreads every feature's `<feature>Routes` into `appRoutes`; nothing is
   added to `lib/app/view/app.dart`.
8. **Finishing a change means `melos analyze` is clean and `MEMORY.md` is
   updated** per its own protocol. Both are part of "done", not cleanup.

### BLoC + injectable rules

9. **A bloc depends on use cases only** — never on a repository, never on
    another bloc. Events and states are `sealed`/`final` so the compiler
    enforces exhaustive handling. Render with `BlocBuilder`; do side effects
    (navigation, snackbars) with `BlocListener`.
10. **Repositories are annotated on the implementation**, bound to the abstract
    interface with `as:` and scoped with `env:`:
    `@LazySingleton(as: I<Feature>Repository, env: [...])`. The `mock/`
    counterpart is registered for `env: [Environment.test]` **only**.
11. Use cases and blocs are `@injectable`; nothing constructs them by hand.
12. `injector<T>()` belongs at a composition point (a page's `State`) — never
    in domain or data code.
13. **A new `@injectable` does not exist until `melos build` has run** — that
    is what regenerates `inject.config.dart`.
14. `package:core/core.dart` exports an `Environment` enum that collides with
    `injectable`'s. Import one of them with a prefix or a `hide` clause.

## What a feature requires

**Prefer the skill — `implement-feature`.** It writes the baseline slice and
then fills in all three layers. Working by hand, a feature is not done until
every row below exists.

### Files — `packages/<app>/lib/features/<feature>/`

| Path | Must contain |
|---|---|
| `domain/entities/<entity>.dart` | pure-Dart entity, no serialization |
| `domain/dtos/<entity>_draft.dart` | the shapes crossing a use-case boundary |
| `domain/repositories/<feature>_repository.dart` | `abstract class I<Feature>Repository` — the contract, not an implementation |
| `domain/use_cases/<verb>_<entity>_uc.dart` | one per operation; `extends UseCase<In, Out>`; callers invoke `execute()` |
| `data/models/<entity>_model.dart` | JSON only; either `extends` the domain type or a freezed twin with `toEntity()` |
| `data/repositories/<feature>_repository.dart` | `@LazySingleton(as: I<Feature>Repository, env: [...])`; every method body wrapped in `guard(...)` |
| `data/repositories/mock/<feature>_repository.dart` | `@LazySingleton(as: I<Feature>Repository, env: [Environment.test])` |
| `presentation/view/pages/<p>/<p>_bloc.dart` | `@injectable` bloc; sealed events → sealed states |
| `presentation/view/pages/<p>/<p>_page.dart` | `StatefulWidget`; `injector<Bloc>()` in the `State`; `BlocBuilder` + `BlocListener` |

Feature names are plural, entity names singular (`orders` → `Order`).

### Wiring — outside the feature folder

| File | Change |
|---|---|
| `.../<feature>/presentation/routing/<feature>_routes.dart` | one `@TypedGoRoute<<Page>Route>` class per page, collected into `<feature>Routes` |
| `packages/<app>/lib/routing/routes.dart` | import `<feature>Routes` and spread it into `appRoutes` — `app.dart` itself is never touched |
| `packages/<app>/lib/inject.config.dart` | regenerated by `melos build` — never edited |

### Verify

- [ ] `melos build`
- [ ] `melos analyze` clean
- [ ] `melos test:unit-widget` passes
- [ ] `MEMORY.md` `## Feature Map` row added or updated

## What a component requires

**Prefer the skill — `create-component`.** A component is the quartet
Widget / `ThemeData` / `Theme` / optional `ViewModel`, one folder under
`packages/core/lib/src/presentation/components/<component_name>/`.

| Path | Must contain |
|---|---|
| `<component_name>.dart` | the widget **and** `@freezed sealed class <Name>ThemeData` with a `.fallback(BuildContext)` factory. freezed 3.x requires `sealed`/`abstract` or nothing generates. |
| `<component_name>_view_model.dart` | optional — `@freezed sealed class <Name>ViewModel` for components with input state |
| `<component_name>.freezed.dart` | generated by `melos build:core`; never hand-written |

Contract:

- The widget keeps a **nullable `theme` field** and `build()` opens with
  `final theme = this.theme ?? <Name>ThemeData.fallback(context);`.
- `.fallback` must assign **every** required field, derived from
  `Theme.of(context).colorScheme` / `.textTheme` — never a literal colour or
  size.
- Add a `ComponentDemo` to the matching `ComponentSection` in
  `packages/core/demo/lib/main.dart`, even while the widget is still a stub.

**Export.** Add one line per file to `packages/core/lib/core.dart`, keeping
the list alphabetical.

### Verify

- [ ] `melos build:core`
- [ ] `melos analyze` clean
- [ ] the demo entry renders (`melos core:demo`)
- [ ] `MEMORY.md` `## Component Index` row added

## Skill routing

| Intent | Start with |
|---|---|
| Build a Clean Architecture feature end to end | `implement-feature` |
| Add a reusable component to `core` | `create-component` |
| Apply or update a design-system bundle | `import-design-system` |
| Build one slice of a Claude Design prototype | `implement-prototype` |

The skills live in `.claude/skills/`. Each one ends by updating `MEMORY.md`;
when you change the app **outside** a skill, do that update yourself.

## Commands

| Command | Use |
|---|---|
| `melos bs` | Bootstrap the workspace |
| `melos build` | Codegen everywhere (required after touching anything generated) |
| `melos build:core` | Codegen for `core` only |
| `melos analyze` | Must be clean before you report done |
| `melos test:unit-widget` | All tests, coverage, randomized ordering |
| `melos core:demo` | Component gallery |
| `melos hello` | Run the app (prompts for flavor and device) |
| `melos hello:test` | Run the app against the in-memory account store |

**Every cold start lands on `/landing` today.** `AppBloc._restoreSession()` in
`lib/app/bloc/app_bloc.dart` always returns `false`, so `isSignedIn` never flips true
on its own. Replace that one method with a real token-store check to reach
`/main` on a restored session — every destination is already wired and
covered by `test/app/view/launch_page_test.dart`, so the stub is the only
thing left to change.

### The `test` flavor's account store

`melos hello:test` runs against a stateful fake backend, not canned
outcomes — sign-up registers an account and log-in validates against it, so the
two forms actually relate to each other.

| Input | What happens |
|---|---|
| `demo@example.com` / `Passw0rd!` | The seeded account. Log in works before signing up. |
| any unregistered email | Sign up registers it; log in reports the same failure as a wrong password |
| an email that is already registered | Sign up refuses it and says to log in instead |
| `offline@example.com` | Throws a `SocketException`, which `BaseRepository.guard` maps to `NetworkException` |

The store is in-memory and does not survive a restart. It holds passwords as
typed — a fake backend that pretended to be secure would be worse than one that
obviously is not.

## Removing the onboarding feature

The generated flow is a worked example, not a commitment. Deleting
`lib/features/onboarding/` breaks exactly **two** source files, each carrying a
comment that says so:

| File | Edit |
|---|---|
| `lib/routing/routes.dart` | drop the import and `...onboardingRoutes,` |
| `lib/di/overrides.dart` | drop the import and `...onboardingOverrides(environment),` |
| `lib/routing/routes.dart` again | repoint `LaunchRoute`'s signed-out branch: `context.go('/landing')` targets a path the feature owned, so leaving it sends every cold start to go_router's error screen |

**The third row is the one that will not fail your build.** Dropping the first
two is a compile error, so you cannot miss them. The third is a string, so
analysis stays clean and the tests stay green — `/landing` still *appears* to
be the current location, because go_router reports the requested URI whether or
not anything matched it. Point it at `/main`, or at whatever your own first
screen is.

Then `rm -rf test/features/onboarding/`, drop the onboarding assertions from
`test/di/overrides_test.dart`, and move `test/app/view/launch_page_test.dart`'s
signed-out expectation to the same destination you chose above. Run
`melos build`.

Nothing else moves, but look twice at `lib/routing/routes.dart` while you are
already in it: `LaunchRoute` is app-level and plays the cold start either way,
but its signed-out branch calls `context.go('/landing')` **by path** —
repoint that string at a real destination (or at `/main` unconditionally, if
this app has nothing left to sign in to) once `onboardingRoutes` no longer
answers it. `pubspec.yaml` is untouched — everything the feature renders
arrives through `core`. `lib/app/view/home_page.dart` survives: it
navigates by path rather than naming a feature route, which is the whole reason
it does that. `app.dart` reads the single `appRoutes` list and never names an
individual route. The app-level `test/theme_contract_test.dart` and
`test/design_assets_test.dart` glob or read `core`'s own constants, so they stay
green rather than becoming the third and fourth things to fix.
