---
name: implement-prototype
description: Implement or update a slice — a single page, a multi-page flow, or a whole feature — of a Claude Design prototype in this Flutter monorepo. Imports the prototype via the claude_design MCP (a claude.ai/design URL, auth with /design-login), works out which part is new vs an update to an already-built screen, maps each UI element to an existing core component or a new one, reuses the existing blocs/repositories/routes it integrates with, delegates new shared widgets to create-component and brand-new backend layers to implement-feature, wires go_router, runs the build, and records the implementation (file map, integration points, gotchas) in MEMORY.md for future prototype work and troubleshooting. Use when someone points at a Claude Design prototype and wants a part of it built into an existing app. Not for scaffolding a whole app or monorepo, applying a design-system bundle to the theme (import-design-system), or building a full feature from scratch with no prototype (implement-feature).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Implement a prototype slice on the established architecture

This skill turns a **named slice of a Claude Design prototype** into real,
running Flutter code inside an **existing monorepo of this shape**. It imports
the prototype through the `claude_design` MCP, works out whether the slice is a
brand-new page/flow/feature or an **update** to something already built, maps
each part of the design onto the architecture and components you already have,
implements it, wires routing, builds, and — crucially — **records what it did
in `MEMORY.md`** so the next prototype slice (and any later troubleshooting)
starts with context instead of a blank slate.

It does **not** reinvent the layers below the UI. Where the slice needs a whole
new Clean-Architecture feature (a new entity, repository, use cases), it
delegates to **implement-feature**; where it needs a reusable widget that
isn't in `core` yet, it delegates to **create-component**. This skill's own job
is the slice-level work: understand → map to what exists → implement/update the
presentation and its wiring → remember.

> Not what you want?
> - A full Clean-Architecture feature from scratch, no prototype → **implement-feature**.
> - A single reusable shared widget → **create-component**.
> - Apply a design-system bundle (colors, typography, tokens) to the core theme → **import-design-system**.
> - A whole new app package or monorepo → this monorepo's `README.md`.

This skill assumes an **existing monorepo of this shape with at least one app
package** and the `claude_design` MCP configured. **All paths below are
relative to the monorepo root.**

## Step 1 — Import and understand the prototype

1. **Authenticate.** If the `claude_design` MCP is not yet authenticated, run
   `/design-login` first.
2. **Import the prototype.** Use the `claude_design` MCP's import/read tools on
   the prototype URL the user gave. It has the form
   `https://claude.ai/design/p/<project-id>?file=<path/to/File.html>` — the
   `file` query param names the specific HTML page inside the prototype (e.g.
   `native/Otto Native App.html`). Read that file.
3. **Identify the slice.** The user names *what* to implement (e.g.
   "Hotel QR Entry"). Locate that part inside the prototype. If the name is
   ambiguous or spans several screens, `AskUserQuestion` to confirm the exact
   boundary.
4. **Classify the slice** — this drives everything below:
   - **Page** — one screen.
   - **Flow** — several screens navigated in sequence; enumerate each screen,
     the navigation order, and the entry point (where the user enters the flow
     from the existing app).
   - **Feature** — a slice that needs its own data/domain layers, not just
     presentation.
5. **Extract per screen:** layout and sections, the states it has
   (empty / loading / error / success), interactions, and the data each screen
   **shows** or **captures**. This is what you map onto the codebase next.

## Step 2 — Understand the existing codebase (integration analysis)

Do this **before** writing anything — the point of a prototype slice is that it
plugs into an app that already exists.

1. **Read `MEMORY.md`** at the monorepo root if it exists. Prior slices record
   their file maps, integration points, and gotchas there — reuse that context.
2. **Inventory what exists:**
   - Features: `packages/<app>/lib/features/*`.
   - Routes: each feature's own `presentation/routing/<feature>_routes.dart`,
     aggregated by `appRoutes` in `packages/<app>/lib/routing/routes.dart`.
     `lib/app/view/app.dart` names no individual route.
   - Core components: `packages/core/lib/src/presentation/components/`, all
     exported from `package:core/core.dart`. Eleven ship with the scaffold —
     `MEMORY.md`'s **Component Index** is the live list, and a form slice is
     usually `LabeledTextField` + `PasswordField` + `PillButton` already.
   - Blocs / repositories / use cases relevant to the slice's data.
3. **New vs update — decide per screen.** Match the slice against existing
   routes, features, and screen names. A screen that matches an existing page is
   an **update** (edit in place, preserve its bloc wiring); one with no match is
   **new**.
4. **Map each UI element** to an **existing** core component or flag it as a
   **new** component. Prefer an existing component every time one fits.
5. **Find the integration points:** which existing bloc / repository / use case
   already supplies (or should supply) this slice's data, which existing screen
   should navigate **into** the slice, and any shared state it reads or writes.

## Step 3 — Plan what to create vs update

Turn the analysis into a concrete plan, then **confirm it with the user**
(`AskUserQuestion`) before writing code:

| The slice needs… | Do this |
|---|---|
| New domain + data layers (new entity/repository/use cases) | Run **implement-feature** for that feature first, then return here for the prototype-accurate presentation. |
| A new page inside an existing feature | Author `<page>_bloc.dart` + `<page>_page.dart` under `presentation/view/pages/<page>/`, then wire its route. |
| Changes to an existing page | Edit that page (and its bloc, if states change) **in place**; keep its existing route and bloc wiring. |
| A reusable widget not in `core` | Invoke **create-component** (widget + freezed `ThemeData`, plus a ViewModel if it carries data); consume it from `package:core/core.dart`. |
| Only reused data | Wire the presentation to the **existing** bloc/repository the integration analysis found — do not add a parallel one. |

## Step 4 — Implement

1. **Respect the layering.** Presentation consumes domain through blocs backed
   by injectable-provided use cases/repositories — never reach into `data`
   directly from a widget. Reuse the blocs/repositories identified in Step 2;
   add new ones only for genuinely new data.
2. **Build the UI** from the prototype references — layout, spacing, colors,
   and every state (empty/loading/error/success) — on top of the `core`
   design-system. Read values off the ambient theme (`Theme.of(context)`,
   `.colorScheme`, `.textTheme`); leave a `// TODO` wherever the prototype
   implies a token you can't derive.
3. **Compose from components** — existing core components first, new ones from
   **create-component** second. Do not inline a bespoke widget where a shared
   component belongs.
4. **Never hand-write generated files** — `*.g.dart`, `*.freezed.dart`,
   `inject.config.dart`, `routes.g.dart` are all build_runner outputs
   (see Build).
5. **Wire routing for every new page** by editing the target app package:
   - The feature's `presentation/routing/<feature>_routes.dart` — for a
     brand-new feature, create it; for an existing one, add the import and a
     `@TypedGoRoute` class alongside its other routes:

     ```dart
     import 'package:<pkg>/features/<feature>/presentation/view/pages/<page>/<page>_page.dart';

     @TypedGoRoute<<Page>Route>(path: '/<page>')
     class <Page>Route extends GoRouteData with $<Page>Route {
       const <Page>Route();
       @override
       Widget build(BuildContext context, GoRouterState state) =>
           const <Page>Page();
     }
     ```

     then add `$<page>Route` to that file's own `<feature>Routes` list.

   - `lib/routing/routes.dart` — for a brand-new feature, import
     `<feature>Routes` and spread it into `appRoutes`; for an existing one,
     nothing here changes. `lib/app/view/app.dart` is never touched.

   The `$<Page>Route` mixin and `$<page>Route` getter come from
   `<feature>_routes.g.dart`, generated by the build — referencing them before
   they exist is expected.
6. **Connect the flow.** For a multi-screen flow, wire the navigation between
   its screens and, importantly, the **entry point** — the existing screen that
   navigates into the slice (e.g. a button that pushes the first route).

## Step 5 — Build and verify

Run `melos build` at the monorepo root:

```bash
melos build
```

This regenerates `*.g.dart`, `*.freezed.dart`, `inject.config.dart`, and
`routes.g.dart`, resolving the `$<Page>Route` references and any JSON/freezed
code. (`melos build:core` scopes codegen to `core` for a component-only change.)

Report the run and navigation steps to the user: `melos <app>` (or the app's
flavor run scripts) to launch, and which route(s) to open to see the slice.

## Step 6 — Record the implementation in `MEMORY.md`

This is what makes the next prototype slice cheap. `MEMORY.md` sits at the
monorepo root and is always present — do not create or restructure it.

1. **Record the slice.** Under `## Prototype Slices`, append a
   `### S-<n> <Slice name>` section — or, when you re-implemented a screen that
   is already listed, **edit that section in place** rather than adding a
   second one. The field list is the "Slice entry template" `<details>` block
   inside that same section: use it verbatim, it is the single source of truth
   for the format.
2. **Promote the durable parts out of it.** A gotcha becomes a `G-<n>` under
   `## Gotchas`; a design decision a `D-<n>` under `## Decisions`; anything the
   user stated as a requirement an `R-<n>` under `## Requirements`. The slice
   section then just cites the ids. This is what survives compaction.
3. **Update the indexes.** New pages and routes go into the feature's row in
   `## Feature Map`; any component you created goes into `## Component Index`.
4. **Append one `## Session Log` line.**

Follow `## How to maintain this file` at the top of `MEMORY.md` — it defines the
append-vs-edit test, the id scheme, the line cap, and the compaction pass. Do
not restate that protocol here.

Why it matters: the next slice's Step 2 reads this to find existing state
holders, routes, and components instead of re-deriving them, and troubleshooting
a regression starts from the recorded file map and integration points.

## Design-system reference

The presentation layer is built on the `core` package's design-system:

- **Existing components** (`packages/core/lib/src/presentation/components/`),
  all exported from `package:core/core.dart`:

  | Component | Folder | What it is |
  |---|---|---|
  | `AmbientBackdrop` | `ambient_backdrop/` | a page ground with soft colour washes |
  | `FormMessage` | `form_message/` | one inline sentence with an icon — errors, notices |
  | `FormTextInput<T>` | `form_text_input/` | themable `TextFormField` wrapper (+ ViewModel) |
  | `IconActionButton` | `icon_action_button/` | a 44pt icon-only tap target |
  | `LabelChip` | `label_chip/` | a themable chip |
  | `LabeledTextField` | `labeled_text_field/` | label above field, focus ring, hint |
  | `NavBar` | `nav_bar/` | the floating pill nav bar |
  | `PasswordField` | `password_field/` | obscured field, reveal toggle, optional strength meter |
  | `PasswordStrengthMeter` | `password_strength/` | the five-step ramp (+ ViewModel) |
  | `PillButton` | `pill_button/` | the primary CTA, with busy and dimmed states |
  | `PromptLink` | `prompt_link/` | "Don't have an account? Sign up" as one button |

  `MEMORY.md`'s **Component Index** is the live list — read it rather than
  this one if the two disagree, and update it when you add a component.
- **Theme / tokens** (`packages/core/lib/src/presentation/theme/`): the Material
  3 palette, scheme, extension, and `app_theme`. Read off
  `Theme.of(context).colorScheme` / `.textTheme` rather than hard-coding.
- **New components** are added with **create-component**, modelled on the two
  above. Map each design element to an existing component first.

## Prerequisites

- An **existing monorepo of this shape with at least one app package**.
- **`melos`** for the Build step: `dart pub global activate melos`.
- The **`claude_design` MCP** configured and authenticated (`/design-login`).

## Gotchas

- **Analyze before you author.** A prototype slice lands inside an existing app;
  skipping Step 2 produces a parallel bloc/route/component that duplicates what
  already exists.
- **Update in place, don't fork.** When a screen matches an existing page, edit
  it — don't create a second page with a near-identical route.
- **Route every new page.** A page without a `@TypedGoRoute` class in its
  feature's `<feature>_routes.dart`, collected into `<feature>Routes`, is
  unreachable.
- **Wire the entry point.** A flow no existing screen navigates into is dead
  code — connect where the user enters it.
- **`melos build` is required**, not optional, once routing or JSON/freezed code
  is touched — the code references generated symbols that don't exist until
  codegen runs.
- **Delegate down, don't inline.** New backend layers → implement-feature; new
  shared widgets → create-component. This skill owns the slice, not the layers.
- **Always update `MEMORY.md`.** Skipping Step 6 is the one thing that makes the
  next slice expensive — treat it as part of "done", not optional cleanup. The
  rules for how to write it live in that file's own
  `## How to maintain this file` section; follow them rather than inventing a
  layout.
- **No git commit.** This leaves files on disk for you to review and commit.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `claude_design` MCP calls unauthorized | Run `/design-login`, then retry the import. |
| Prototype file not found for the URL | Check the `?file=` query param names an actual HTML page in the prototype; confirm the exact name with the user. |
| Two pages/routes for the same screen | You created new where you should have updated — re-check Step 2's new-vs-update decision and remove the duplicate. |
| New screen compiles but is unreachable | Missing route or missing entry-point navigation — see the routing and "connect the flow" steps. |
| Build fails (`$<Page>Route` undefined) | Expected until `melos build` runs — that generates `routes.g.dart`. |
| `The class '_$<Name>ThemeData' isn't defined` (a new component) | Component `.freezed.dart` not generated — run `melos build:core`. |
| Slice needs data with no repository behind it | Stop and run **implement-feature** for that feature before finishing the presentation. |
| `melos: command not found` | `dart pub global activate melos`; add `$HOME/.pub-cache/bin` to `PATH`. |
