---
name: implement-feature
description: End-to-end implementation of a Clean-Architecture feature in this Flutter monorepo — interviews for the feature's description, entities/DTOs, use cases, repository API, screens/pages, and new components, writes the baseline slice across all 3 layers (presentation/domain/data) and fills it in, builds the UI from design mockups (a Figma link, images, or a description) on top of the core design-system, generates new shared components via create-component, wires go_router for every page, and runs the build. Use when someone wants to fully build out a feature (like features/authentication), not just scaffold a baseline slice. Not for creating a whole app or monorepo, or a single standalone component.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Implement a Clean-Architecture feature end-to-end

This skill takes a feature from **idea to running screens**. It interviews you
for the feature's real shape (description, entity/DTO fields, model style, JSON
casing, repository API, use cases, screens, bloc states), writes the baseline
slice across all three layers, generates any **additional pages** and **new
shared components** the design needs, builds the presentation layer from your
**design mockups** on top of the `core` design-system, wires every page into
`go_router`, and runs the build.

Everything here is authored by you, in this workspace — no external tool is
invoked and nothing has to be on your `PATH`. The pattern to copy is already
checked in: **`features/onboarding/`** is the same three-layer slice, in this
app, in this state-management style. Read it before you write.

> Not what you want?
> - A single reusable shared widget → **create-component**.
> - A whole new app package or monorepo → this monorepo's `README.md`.

This skill assumes an **existing monorepo of this shape with at least one app
package**. **All paths below are relative to the monorepo root.**

## Interactive flow

Work through these prompts in order before generating anything. Use
`AskUserQuestion` where a preference is unknown; otherwise infer from context
and confirm.

1. **Feature description.** Ask what the feature does — its primary user goal,
   the core flow, and any key states (empty / error / success). This frames
   every decision below; capture it before anything else.
2. **Target app.** If unambiguous (the user named an app, or the working
   directory is inside a single app package), use it. Otherwise list the
   monorepo's apps (the `packages/*` directories, excluding `core`) and
   `AskUserQuestion` which one to target.
3. **Design references (adaptive).** Ask how the user will provide the design,
   in whatever form they have — collect one per screen where possible:
   - **Figma link** — if a `figma.com` URL is given and Figma MCP tools are
     available, pull the design context (`get_design_context`), a screenshot
     (`get_screenshot`), and tokens (`get_variable_defs`) for each frame.
   - **Images / screenshots** — if the user provides image files, `Read` them.
   - **Text description** — otherwise capture a written description of the
     layout, sections, and interactions per screen.
   From whichever form, extract: layout/sections, per-screen states, and which
   UI elements map to **existing** core components vs **new** ones. If no design
   is available, compose from existing core components and note the UI is a
   functional stub to refine later.
4. **Screens / pages.** A feature may have several. List each page with: its
   name, purpose, which entity/state it shows, and how it's navigated to. (The
   baseline slice is exactly one page; every additional screen is written in
   the "Generate" step.)
5. **New components.** For each screen, identify reusable widgets that are
   **not** already in `core`. Check `MEMORY.md`'s **Component Index** before
   deciding something is missing: eleven components ship with the scaffold,
   and a form is usually `LabeledTextField` + `PasswordField` + `PillButton`
   already. Each genuinely new one is created via the **create-component**
   skill (see Generate).
6. **Model style: `extends` vs `freezed`.**
   - `extends` — plain Dart classes; the data model `extends` the domain
     entity/DTO. Less boilerplate, no codegen for equality, easy to read.
   - `freezed` — immutable unions with generated `==`/`copyWith`/pattern
     matching; the model implements a shared interface (`<Entity>IF`) and
     exposes `toEntity()`. More ceremony, but safer for larger/evolving
     entities. Needs `freezed`/`freezed_annotation` deps (you add them in
     Generate) and a `DateTime` JSON converter if any field is a `DateTime`.
   - `AskUserQuestion` with this trade-off if the user hasn't stated a
     preference. Nothing records the answer for you — it decides how you spell
     every model file in Generate, so settle it before you write one.
7. **Entity name + fields.** Confirm the singular entity name (defaults to the
   singularized feature name) and collect its fields as
   `name: type, nullable?, default?` (e.g. `email: String`, `verifiedAt:
   DateTime?`, `role: String = 'member'`).
8. **DTO(s) and their fields.** At minimum the `<Entity>Draft` used by the
   create use case — same `name: type` format. Ask if additional DTOs are
   needed (e.g. an update draft).
9. **Which models need JSON, and casing.** Confirm `fieldRename` casing
   (baseline is `FieldRename.snake`) and flag any field that needs a custom
   `@JsonKey`/converter — most commonly a `DateTime`, which under `freezed`
   needs `@JsonKey(name: '...')` plus the shared `CustomDateTimeConverter`
   (from `common/data/utils/date_time_converter.dart`, auto-emitted for
   freezed features).
10. **Repository API.** Confirm the method signatures beyond the generated
    `fetch<Entity>(String id)` / `create<Entity>(<Entity>Draft draft)` — e.g.
    `update<Entity>(...)`, `delete<Entity>(...)`, `list<Entity>s(...)`.
11. **Use cases.** One use case per repository method the bloc needs to call
    (beyond the generated `fetch`/`create` pair).
12. **Bloc states/events per page.** Confirm, for each page, any states beyond
    the generated initial/loading/loaded/error (e.g. `submitting`, `submitted`,
    `empty`).

## Generate

1. **Baseline slice.** Write these files yourself. **Read
   `packages/<app>/lib/features/onboarding/` first** — it is this same
   three-layer slice, already in this app and already in this state-management
   style, so copy its file shapes, imports, annotations and naming rather than
   inventing them. Under `packages/<app>/lib/features/<feature>/`:
   - `domain/entities/<entity>.dart`, `domain/dtos/<entity>_draft.dart`
   - `domain/repositories/<feature>_repository.dart` (`I<Feature>Repository`)
   - `domain/use_cases/fetch_<entity>_uc.dart`, `create_<entity>_uc.dart`
   - `data/repositories/<feature>_repository.dart` (impl, `@LazySingleton(as: I<Feature>Repository, env:[dev,staging,prod])`, throws `UnimplementedError`)
   - `data/repositories/mock/<feature>_repository.dart` (`@LazySingleton(env:[Environment.test])`)
   - `data/models/<entity>_model.dart`, `data/models/<entity>_draft_model.dart`
   - `presentation/view/pages/<feature>/<feature>_bloc.dart` (events + states + bloc), `<feature>_page.dart`
   - freezed only: `common/data/utils/date_time_converter.dart` — one per app,
     so create it only if it isn't there already

   Then add whatever the app's `pubspec.yaml` is still missing:
   `json_annotation` under `dependencies`; `build_runner` and
   `json_serializable` under `dev_dependencies`; for freezed style also
   `freezed_annotation` (dependency) and `freezed` (dev dependency).

2. **Fill in the slice** to match what the user described:
   - Add the real fields to the entity, DTO(s), and both models (keep
     constructors, `fromJson`/`toJson`, and — for freezed — the `<Entity>IF`
     interface and `toEntity()` in sync with every field you add).
   - Add `@JsonKey`/converter annotations for any field needing custom JSON
     handling.
   - Add the extra repository methods to `I<Feature>Repository` and both
     implementations (real + mock), plus matching use cases.
   - Add extra bloc states/events and their handling in the bloc.

   **Do not hand-write `.g.dart`, `.freezed.dart`, `inject.config.dart`, or
   `routes.g.dart`** — these are build_runner outputs, always produced by
   `melos build` (see Build below), never authored or edited by hand.

3. **Additional pages** (beyond the baseline page). For each extra screen from
   the interactive flow, hand-author a page following the baseline page's
   pattern, under `presentation/view/pages/<page>/`:
   - `<page>_bloc.dart` — events + states + bloc (mirror the one from step 1).
   - `<page>_page.dart` — the widget, consuming the bloc.

4. **New components.** For each new reusable widget identified in the flow,
   invoke the **create-component** skill (widget + freezed `ThemeData`, and a
   ViewModel if it carries data). Consume them from `package:core/core.dart`.
   Prefer an existing core component before creating a new one —
   `MEMORY.md`'s **Component Index** lists all eleven, and a login form in
   particular is already `LabeledTextField` + `PasswordField` + `PillButton`.

5. **Build the presentation UI.** Compose each page from core + new components,
   driven by the design references from step 3 of the flow — layout, spacing,
   colors, and states. Use the ambient theme (`Theme.of(context)`); leave a
   `// TODO` wherever a value needs a real design token you couldn't derive.

## Wire routing

Routing is not part of the baseline slice — this skill wires it, **for every
page**, by writing the feature's own routing file and aggregating it into the
app:

1. **`lib/features/<feature>/presentation/routing/<feature>_routes.dart`** —
   create it once per feature; for each page, add its import and a
   `@TypedGoRoute` route class, then collect them into `<feature>Routes`:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:go_router/go_router.dart';
   import 'package:<pkg>/features/<feature>/presentation/view/pages/<page>/<page>_page.dart';

   part '<feature>_routes.g.dart';

   @TypedGoRoute<<Page>Route>(path: '/<page>')
   class <Page>Route extends GoRouteData with $<Page>Route {
     const <Page>Route();
     @override
     Widget build(BuildContext context, GoRouterState state) =>
         const <Page>Page();
   }

   final List<RouteBase> <feature>Routes = [$<page>Route];
   ```

2. **`lib/routing/routes.dart`** — import `<feature>Routes` and spread it into
   `appRoutes`, alongside the other features already there. `lib/app/view/
   app.dart` is never touched: it reads the single `appRoutes` list and never
   names an individual route.

The `$<Page>Route` mixin and `$<page>Route` getter come from
`<feature>_routes.g.dart`, generated by `melos build` — the code above
references them before they exist, which is expected; the build step below
makes it compile.

## Build

Run `melos build` at the monorepo root:

```bash
melos build
```

This runs `melos exec ... dart run build_runner build --delete-conflicting-outputs`
across all packages, regenerating `*.g.dart`, `*.freezed.dart`,
`inject.config.dart`, and `routes.g.dart` — resolving the `$<Page>Route`
references and the JSON (de)serialization code added above. (For a
component-only change, `melos build:core` scopes codegen to `core`.)

Report the next steps to the user: `melos <app>` (or the app's flavor run
scripts) to launch, and where to navigate (`/<page>`) to see each new screen.

## Update MEMORY.md

Required, before you report done. In `MEMORY.md` at the monorepo root:

- **`## Feature Map`** — add or update one row:
  `| feature | app | entity | pages -> routes | use cases | notes |`.
- **`## Current State`** — add the feature to the features line.
- **`## Component Index`** — one row for any component you delegated to
  create-component (that skill adds its own, so check before duplicating).
- **`## Requirements`** — one `R-<n>` for each constraint the user stated
  during the interview. These are what a later agent cannot re-derive from the
  code.
- **`## Decisions`** / **`## Gotchas`** — anything durable you decided or hit.
- **`## Session Log`** — one line.

Follow `## How to maintain this file` at the top of `MEMORY.md` for the
append-vs-edit test, the id scheme, and the trim triggers. Do not restate that
protocol here, and do not copy rules out of `CLAUDE.md` into `MEMORY.md`.

## Prerequisites

- **Dart SDK ≥ 3.2.3** on `PATH`.
- **`melos`** for the Build step. `dart pub global activate melos`.
- An **existing monorepo of this shape with at least one app package** to add
  the feature into.
- **Figma MCP** is optional — only used when a Figma link is provided and the
  tools are available; the skill works from images or a text description too.

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
  3 color palette, scheme, extension, and `app_theme`. Read fields off
  `Theme.of(context).colorScheme` / `.textTheme` rather than hard-coding.
- **New components** are added with the **create-component** skill, modelled on
  the two above. Map each design element to an existing component first; only
  create a new one when nothing fits.

## Gotchas

- **Must run inside an existing monorepo, targeting an existing app.** The
  feature is written under `packages/<app>/lib/features/<feature>/`.
- **Settle the target app before writing anything.** With two or more app
  packages, ask — a slice written into the wrong `packages/<app>/` still
  compiles, it is simply never reachable from the app you meant.
- **Feature naming is pluralized, entity naming is singularized.** `feature`
  becomes the directory/bloc/repository name as given (snake_cased); the entity
  is the *singular* of the feature name, PascalCased (e.g. feature `orders` →
  entity `Order`).
- **Never write over an existing feature.** If any of the paths above is
  already there, stop and confirm first — running this skill again over a
  customized slice loses the customizations.
- **Route every page.** Each additional page needs its own `@TypedGoRoute`
  class in the feature's `<feature>_routes.dart`, collected into
  `<feature>Routes` — a page missing from that list is unreachable.
- **`melos build` is required**, not optional, once you've wired routing or
  added JSON models — the code references generated symbols (`$<Page>Route`,
  `_$<Model>FromJson`, freezed mixins) that don't exist until codegen runs.
- **Freezed adds deps and a shared date converter.** `freezed_annotation`/
  `freezed` are added to the app's pubspec only for freezed-style features;
  `common/data/utils/date_time_converter.dart` is emitted once per app the
  first time a freezed feature is created.
- **No git commit.** This leaves files on disk for you to review and commit.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails after routing edit (`$<Page>Route` undefined) | Expected until `melos build` runs — that's what generates `routes.g.dart`. |
| Build fails on JSON codegen (`_$<Model>FromJson` undefined) | Run `melos build`; if it still fails, check for a mismatched field between the entity and its model. |
| `The class '_$<Name>ThemeData' isn't defined` (a new component) | Component `.freezed.dart` not generated — run `melos build:core`. |
| `melos: command not found` | `dart pub global activate melos`; add `$HOME/.pub-cache/bin` to `PATH`. |
| Freezed model won't generate | Ensure the `@freezed sealed class ... with _$...` shape and that every `required` field is set. |
