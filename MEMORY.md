# Project memory — bp-riverpod

The current state of this workspace, auto-loaded into every session through the
`@MEMORY.md` import in `CLAUDE.md`. `CLAUDE.md` holds the **rules**; this file
holds the **facts**. Keeping it accurate is part of finishing a task.

<!-- ids: R=requirement D=decision G=gotcha S=slice · monotonic · never reused -->

## How to maintain this file

**When.** At the end of every task that changed a file under `packages/`, and
whenever the user states a requirement, you make a design decision, or you lose
time to a trap.

**Stable ids.** `R-<n>` requirement · `D-<n>` decision · `G-<n>` gotcha ·
`S-<n>` prototype slice. Monotonic, never reused, never renumbered — that is
what turns "was this preserved?" into a `grep`.

**Append or edit — one test.**

- The fact describes *how the project is now* → **edit the existing line**.
  Gate: run `grep -in "<subject>" MEMORY.md` first; a hit means edit, not append.
- The fact describes *a change that happened* → **append** one Session Log line.
- A change that contradicts an existing line does **both**: edit the line, then
  append `old -> new` to the Session Log.

**Write mode per section.**

| Section | Mode | May be trimmed? |
|---|---|---|
| Current State | replace in place | yes — it is only ever "now" |
| Feature Map | one row per feature, edit in place | only once the files are gone from disk |
| Component Index | one row per component, edit in place | only once the files are gone from disk |
| Design System | replace in place | yes |
| Prototype Slices | one `###` per slice, edit in place on re-implementation | body only, after a verbatim archive |
| Requirements (`R-`) | append only | **never** |
| Decisions (`D-`) | append only; supersede with a stub | **never** |
| Gotchas (`G-`) | append only; mark "no longer applies" | **never** |
| Session Log | append, newest first | yes — archived, never deleted |

**Trim triggers.** Run both before you finish a memory update:

```bash
wc -l MEMORY.md                                                          # > 400 -> compact
awk '/^## Session Log/{f=1;next} /^## /{f=0} f&&/^- /' MEMORY.md | wc -l  # > 20  -> compact
```

**Compaction pass** — in this order, no shortcuts:

1. Select the Session Log entries older than the newest **10**.
2. **Promote first.** Every durable fact in a selected entry must already exist
   somewhere permanent: a requirement under `## Requirements`, a decision under
   `## Decisions`, a trap under `## Gotchas`, a created file / route / provider /
   component as a row in `## Feature Map` or `## Component Index`. If it is not
   there, put it there now. **Never archive an entry whose durable content has
   not been promoted** — this single rule is what stops trimming from losing
   requirements.
3. Move the selected entries **verbatim and unedited** to the top of
   `.claude/memory/CHANGELOG.md`, under a new
   `## <YYYY-MM-DD> archived from MEMORY.md` heading.
4. Re-run `wc -l MEMORY.md`. Still over 400? Run the reorganize pass.

**Reorganize pass** — only when the curated sections themselves overflow:

- Collapse prose that restates a table row into the row. One row, one line.
- Prototype slices beyond the newest **3**: move the whole `###` section
  verbatim to the changelog and leave a one-line row under
  `### Archived slices` (name · feature path · routes · archive date).
- A superseded decision keeps a one-line stub —
  `- **D-3** — <title> (superseded by D-9; full text in CHANGELOG)` — and only
  its body moves.
- Never merge two gotchas. Never reword a requirement. Never renumber an id.

**Never.**

- Delete an `R-`, `D-` or `G-` entry, or reuse its number.
- Delete a Feature Map or Component Index row while those files exist on disk.
- Edit text while moving it into `.claude/memory/CHANGELOG.md`.
- Let this file pass 400 lines without running the compaction pass.

## Current State
<!-- format: replace in place · keep under 15 lines -->

- **Apps:** `packages/hello`
- **Shared:** `packages/core`
- **State management:** flutter_bloc + get_it/injectable — one bloc per page, sealed events and states
- **`core` exports:** `full` — a single `core.dart` barrel
- **Design system:** a design-system bundle applied at create time
- **Features:** `onboarding` (baseline slice shipped at create time)
- **Error reporting:** `ErrorReporter` is a get_it registration, not a global,
  and `bootstrap` owns it end to end — it builds a `ConsoleErrorReporter` when
  a `main_<flavor>.dart` passes none, installs it in the crash net, and
  registers that same object after `initializer()`. No main wires anything.
  See D-4.
- **Last verified:** 2026-09-10 — `melos build`, `melos analyze` clean,
  `melos test:unit-widget` passing

## Feature Map
<!-- format: | feature | app | entity | pages -> routes | use cases | notes | -->

| Feature | App | Entity | Pages → routes | Use cases | Notes |
|---|---|---|---|---|---|
| `onboarding` | `hello` | `User` | landing → `/landing`, login → `/login`, signup → `/signup` | Login, Signup | baseline slice from the scaffold; declares its own routes, aggregated by `appRoutes` — `/` and `/main` are app-level, not part of it |

## Component Index
<!-- format: | component | folder under core/lib/src/presentation/components/ | ViewModel? | key ThemeData fields | -->

| Component | Folder | ViewModel | Key `ThemeData` fields |
|---|---|---|---|
| `AmbientBackdrop` | `ambient_backdrop/` | no | ground colour, `List<AmbientWash>` (colour, centre, radius, alpha) |
| `FormMessage` | `form_message/` | no | background, foreground, message style, **icon** (required), radius, padding |
| `FormTextInput<T>` | `form_text_input/` | yes — `FormTextInputViewModel<T>` | decoration, content padding, text style |
| `IconActionButton` | `icon_action_button/` | no | background, icon/disabled icon colour, hover, highlight, size (44), icon size |
| `LabelChip` | `label_chip/` | no | container decoration, label style |
| `LabeledTextField` | `labeled_text_field/` | no | fill, outline, focus ring, cursor, label/text/hint styles, height, radius, `isLabelUppercased` |
| `NavBar` | `nav_bar/` | no | background, active/inactive colour, selected fill, shadow, radius, three paddings, icon size |
| `PasswordField` | `password_field/` | no | none — composes `LabeledTextField`, `IconActionButton` and `PasswordStrengthMeter` |
| `PasswordStrengthMeter` | `password_strength/` | yes — `PasswordStrengthMeterViewModel` | track colour, four ramp colours, label style, track height, label width |
| `PillButton` | `pill_button/` | no | background, foreground, label style, height, radius, padding, border, disabled opacity, pressed scale |
| `PromptLink` | `prompt_link/` | no | prompt style, action style, padding, text align |

Notes an agent needs before editing any of these:

- Every component resolves its colours through its own `<Name>ThemeData`, and
  every `ThemeData` has a `.fallback(context)` deriving from `ColorScheme`,
  `ColorExtension`, `DimensionExtension` and `textTheme`. A literal colour in a
  component is unreachable from a design-system bundle — it survives a rebrand
  and is then the one wrong colour on the screen.
- Each also has a `<Name>Theme` `InheritedWidget` with a
  `static <Name>ThemeData of(BuildContext)`, so a subtree can restyle every
  instance without touching a call site.
- `PasswordStrengthMeter`'s files are `password_strength/meter.dart` and
  `meter_view_model.dart`, not `<name>/<name>.dart` like the others: spelled
  out fully, the export line exceeds 80 characters and trips
  `lines_longer_than_80_chars`.
- Icons come from `AppIcons` and render through `AppIcon`. There is no Material
  glyph fallback and no unicode arrow, chevron or check anywhere in `core`.

## Design System
<!-- format: replace in place -->

A design-system bundle was applied at create time from
`.design-system/bundle.json` — colours, dimensions and typography are already
rendered into `packages/core/lib/src/presentation/theme/`. The bundle's
`components[]` may still be unimplemented; run **import-design-system** to
finish or re-apply it.

## Prototype Slices
<!-- format: newest first · one ### per slice · edit in place on re-implementation -->

_None yet._

<details><summary>Slice entry template — the single source of truth for the format</summary>

```markdown
### S-<n> <Slice name>

- **Source:** <prototype URL> — file `<path/to/File.html>`
- **Type:** page | flow | feature · **Status:** created | updated
- **App / feature:** `packages/<app>/lib/features/<feature>/`
- **File map:** <prototype element> → `<path>`
- **Components:** reused <names>; created <names> (via create-component)
- **Routes added:** `/<page>` (`<Page>Route`)
- **Integration points:** consumes <...>; entered from <...>; shared state <...>
- **Gotchas:** promoted to `## Gotchas` as G-<n>
```

</details>

## Requirements
<!-- append only · NEVER trimmed · id R-<n> -->

- **R-1** — This workspace uses one state-management architecture; every app
  package must match it. It was chosen at create time and is baked into
  `packages/core`.

## Decisions
<!-- append only · NEVER deleted · supersede with a one-line stub · id D-<n> -->

- **D-1** (create time) — Scaffolded with the state-management
  and `core`-export variants recorded above. Changing either afterwards means
  regenerating, not editing.
- **D-2** (create time) — Error envelope: `ApiClient` reads a non-2xx body
  tolerantly and the backend's code beats the status in `AppException.code`.
  Messages are log-only; copy comes from `forCode`, with the type as fallback.
- **D-3** (2026-08-21) — build_runner output is **not** committed:
  `.gitignore` carries `*.freezed.dart`, `*.g.dart` and an unanchored `build/`,
  matching `bp/bp-mvvm` exactly. `melos build` is therefore a required step on a
  fresh clone, before `melos analyze`. `.gen.dart` (flutter_gen's
  `assets.gen.dart` / `fonts.gen.dart`) and `inject.config.dart` stay **tracked**
  — `*.g.dart` does not match `*.gen.dart`, and that asymmetry is deliberate,
  not an oversight to "fix".
- **D-4** (2026-09-10, revised) — `ErrorReporter` reaches its consumers through
  get_it, not through the `appErrorReporter` global (deleted), and **`bootstrap`
  owns the instance end to end**. It is a nullable parameter: pass one to
  forward crashes to Sentry/Crashlytics, or pass nothing and `bootstrap` builds
  a `ConsoleErrorReporter` (which lives in `core`, beside `NoopErrorReporter`,
  precisely so `core` can construct the default without naming an app class).
  That one object is installed in `FlutterError.onError` /
  `PlatformDispatcher.onError`, handed to `AppBlocObserver`, and registered with
  `injector.registerSingleton<ErrorReporter>` — **after `initializer()`**, see
  G-5. One door, so the crash lane and the handled lane cannot drift apart, and
  all four `main_<flavor>.dart` stay free of reporter wiring.
  It is deliberately **not** annotated: lazy or eager,
  `@LazySingleton(as: ErrorReporter, env: [...])` means *injectable* calls the
  constructor, so an annotation yields a second object for the type while the
  crash lane keeps reporting to the first. A pre-registered type resolves like
  any other, so a future consumer can take `ErrorReporter` in an `@injectable`
  constructor with no further wiring.
  *Supersedes the original D-4 (two doors: `bootstrap(reporter:)` plus
  `configureInjection(reporter:)`, with a `ConsoleErrorReporter` in the app
  package). Full text in CHANGELOG.*

## Gotchas
<!-- append only · NEVER deleted · id G-<n> -->

- **G-1** — Generated files (`*.g.dart`, `*.freezed.dart`, `routes.g.dart`, `inject.config.dart`) are
  build_runner outputs. Hand-editing one is silently reverted by the next
  `melos build`.
- **G-2** — A new `@injectable` does not exist until `melos build`
  regenerates `inject.config.dart`; until then `injector<T>()` throws at
  runtime, not at compile time.
- **G-3** — Parsing a non-2xx body must stay in a `try`/`catch`: a bare
  `jsonDecode` on an HTML error page throws, losing the status and the `code`
  that tells one outage from another in the crash reporter.
- **G-4** — `handleBlocAction`'s reporter lookup **must** stay guarded by
  `GetIt.instance.isRegistered<ErrorReporter>()`. `core`'s own tests and
  `core/demo` never call `configureInjection`, so an unguarded
  `GetIt.instance<ErrorReporter>()` throws from *inside* the `on AppException`
  catch — turning every failure the app handles into a crash it does not, in
  exactly the code path meant to prevent that. Pinned by *"still routes the
  failure when no reporter is registered"* in
  `packages/core/test/error_handling_test.dart`.
- **G-5** — `configureInjection` opens with `await injector.reset()`, which is
  why `bootstrap` registers the `ErrorReporter` **after** `await initializer()`
  and not before: registered earlier, the reset wipes it and every resolution
  silently falls back to the no-op. `bootstrap` also unregisters first — it runs
  once per app but once per *test* too, and a bare `registerSingleton` throws on
  the second call.
- **G-6** — `melos hello` option **2) iOS Simulator** passes `-d "iPhone"`, and
  `flutter run` resolves `-d` by **exact-or-prefix** match against
  *already-running* devices only (`DeviceManager.getDevicesById`, flutter_tools
  `lib/src/device.dart`). Two consequences: `flutter run` never boots a
  simulator for you, so with none booted the option matches nothing; and a
  connected physical iPhone does **not** rescue it, because devices are named
  `<owner>'s iPhone` and prefix matching is not substring matching. Boot a
  simulator first (`open -a Simulator`, or `flutter emulators --launch
  apple_ios_simulator`) — then `-d "iPhone"` prefix-matches e.g. `iPhone 17 Pro`.
- **G-7** — **`Failed to update packages.` from any `melos` script is noise and
  has nothing to do with pub.** The `melos` on PATH re-execs through
  `flutter pub run`, and flutter_tools turns *any* non-zero child exit into that
  one string (`throwToolExit('Failed to update packages.')`, `lib/src/dart/pub.dart`).
  `melos exec --scope=hello -- "exit 1"` reproduces it with no pub involved, and
  one line is printed per nested melos layer. The real error is always further
  **up** the output, inside the `hello:` block — scroll past the `└> FAILED`
  summary and read that instead.

## Session Log
<!-- format: - _<date>_ — <what changed> -->

- _2026-09-10_ — Debugged a `melos hello` failure; **no source changed**. Root
  cause was environmental, not a code bug: no iOS Simulator was booted, so
  `-d "iPhone"` matched nothing (see G-6), and melos's `Failed to update
  packages.` epilogue hid the real message (see G-7). Verified by booting
  `iPhone 17 Pro` and re-running the exact inner command — Xcode build done in
  53.2s, app launched, VM Service attached. `melos.yaml`'s `run-app` script is
  still unhardened: option 2 remains a bare `device="iPhone"` that assumes a
  booted simulator.
- _2026-09-10_ — Revised yesterday's `ErrorReporter` work and propagated it to
  `bp-mvvm`, `bp-riverpod` and the `bp-cli` generator, so all four repos agree
  and future generated projects ship it (see the revised D-4, G-4, G-5).
  `configureInjection(reporter:)` -> `bootstrap` owns the registration;
  `packages/hello/lib/common/error/console_error_reporter.dart` ->
  `ConsoleErrorReporter` in `packages/core/lib/src/error/error_reporter.dart`;
  four hand-wired `main_<flavor>.dart` -> all four back to their generated
  form. `bootstrap`'s `reporter` is now nullable and it builds the default
  itself, then registers it after `initializer()` (unregistering first, because
  a test calls `bootstrap` once per case). Deleted
  `packages/hello/test/inject_test.dart` — the seam it covered moved into
  `packages/core/test/bootstrap_test.dart`, which now pins
  `same(reporter)` between the crash net and the container plus the
  console-reporter fallback. Every one of these files is now a byte-for-byte
  copy of `bp create` output; `inject.config.dart` is unchanged, which is the
  check that nothing got annotated by mistake.
- _2026-09-08_ — `ErrorReporter` moved from a mutable process global onto DI
  (see D-4, G-4, G-5). `appErrorReporter` global -> `injector<ErrorReporter>()`.
  Deleted the global from `core/src/error/error_reporter.dart` and the
  `appErrorReporter = reporter` line from `bootstrap`; `handleBlocAction` now
  resolves from `GetIt.instance` behind an `isRegistered` guard;
  `configureInjection` gained an optional `reporter` (defaulting to
  `NoopErrorReporter`, which keeps every existing test call site unchanged) and
  registers it with `registerSingleton`. New
  `packages/hello/lib/common/error/console_error_reporter.dart` — unannotated
  on purpose, the swap point for Sentry/Crashlytics. All four
  `main_<flavor>.dart` build the instance and pass it to both doors, except
  `main_test.dart`, which reports nothing and takes the defaults. Blocs were
  **not** changed: no constructor gained a parameter, so `AppBloc`, `LoginBloc`
  and `SignupBloc` and their tests are untouched. Tests: replaced the deleted
  global's two seams — `bootstrap_test`'s "installs the reporter as the
  breadcrumb sink" became "hands the observer the very reporter it was given",
  and `error_handling_test` now registers through get_it plus a new
  no-reporter-registered case; new `packages/hello/test/inject_test.dart`
  pins `same(reporter)` across the registration. `inject.config.dart` is
  unchanged, which is the check that nothing got annotated by mistake.
- _2026-08-21_ — `.gitignore` aligned byte-for-byte with `bp/bp-mvvm`:
  `/build/` -> `build/` (root-anchored missed `packages/<pkg>/build/`), plus
  `*.freezed.dart` and `*.g.dart` (see D-3). Untracked the three
  `packages/core/build/` artifacts the old anchor had let in. `origin` added as
  `git@bp.github.com:beaupixel25/bp-bloc.git` — the `bp.github.com` SSH alias
  from `~/.ssh/config`, same form as bp-mvvm, not the plain HTTPS URL. Nothing
  pushed yet; the GitHub repo is empty.
<!-- format: `- <YYYY-MM-DD> <what changed> (skill|manual) -> <where it landed>` -->
<!-- newest first · keep the newest 10 · older entries move verbatim to .claude/memory/CHANGELOG.md -->

- _create time_ — workspace scaffolded: `packages/core` plus
  `packages/hello`, baseline `onboarding` feature, eleven `core` components (manual)
  → whole tree
