---
name: create-component
description: Scaffold a NEW reusable presentation component (widget + freezed ThemeData, optional freezed ViewModel) into the `core` package of this bp Flutter monorepo, modelled on the existing form_text_input / label_chip components. Use when someone wants to add a shared UI component/widget with a themable ThemeData and optionally a ViewModel. Walks the user through name, ViewModel?, folder, ThemeData fields, and ViewModel fields, writes the .dart files, wires the core.dart export, adds it to the core demo app's component gallery, and runs freezed codegen.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Create a reusable presentation component

Scaffold a shared UI component into this monorepo's `core` package,
following the two established patterns:

- **`label_chip`** — a `StatelessWidget` + a freezed `<Name>ThemeData` sealed
  class exposing a `.fallback(context)` factory. No ViewModel.
- **`form_text_input`** — the same, plus a separate freezed **ViewModel** file
  that carries the component's data/state.

Both keep a nullable `theme` field on the widget and fall back to
`<Name>ThemeData.fallback(context)` when none is passed. Both rely on freezed
codegen (`part '<name>.freezed.dart'`), are re-exported from
[core.dart](../../../packages/core/lib/core.dart), and are shown in the core
demo app's component gallery
([demo/lib/main.dart](../../../packages/core/demo/lib/main.dart)).

**Paths below are relative to the monorepo root.** The `core` package lives at
`packages/core`.

## Interactive flow

Ask these in order with `AskUserQuestion`, then confirm before writing. Skip a
question only when the user already answered it in their request.

1. **Component name** — e.g. `"Label Chip"`. Derive:
   - PascalCase `<ComponentName>` → `LabelChip`
   - snake_case `<component_name>` → `label_chip`
2. **Needs a ViewModel?** (default **No**.) Yes → also emit a freezed
   `<ComponentName>ViewModel` file and pass it into the widget (form_text_input
   style). No → widget takes only `theme` (label_chip style).
3. **Folder location** (default `packages/core/lib/src/presentation/components/<component_name>`). Options:
   - **default** (above)
   - **current folder** — the directory the user is working in
   - **a path** — an explicit path they give
   Only when the folder is under `packages/core/lib/` do you wire the
   `core.dart` export (see Build). Outside `core`, skip the export and adjust
   import paths (the templates assume `core`).
4. **ThemeData fields** — a list of `propertyName: Type` (e.g.
   `containerPadding: EdgeInsets, containerDecoration: BoxDecoration,
   height: double`). For each type, import the right package (see
   **Type → import** below). Every field is a `required` freezed field unless
   the user gives a default (`height: double = 42` → `@Default(42) double height`).
5. **ViewModel fields** (only if step 2 = Yes) — a list of `propertyName: Type`
   for the data the component renders (e.g. `label: String, isSelected: bool`).

## Type → import

Most Flutter UI types resolve from a single import — add it once per file:

```dart
import 'package:flutter/material.dart';
```

That covers `Color`, `EdgeInsets`, `EdgeInsetsGeometry`, `BoxDecoration`,
`BoxBorder`, `Border`, `BorderSide`, `BorderRadius`, `Radius`, `BoxConstraints`,
`TextStyle`, `StrutStyle`, `InputDecoration`, `IconData`, `Alignment`,
`VoidCallback`, `Widget`, and all the `dart:ui` types material re-exports.
`double`, `int`, `bool`, `String`, `Duration` are `dart:core` — no import.

If a field's type comes from elsewhere, add that import too:

| Type origin | Import |
|---|---|
| `TextInputFormatter`, `TextInputType`, `TextInputAction` | `package:flutter/services.dart` |
| A type defined in `core` (e.g. another ViewModel, `ColorExtension`) | `package:core/core.dart` |
| A third-party type | that package's import |

When unsure, add `package:flutter/material.dart` and let `melos build` /
`flutter analyze` surface any missing import.

## Templates

Substitute `<ComponentName>` / `<component_name>` and the field lists. Write
files with the `Write` tool.

### 1. Widget — `<component_name>.dart`

```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// If ViewModel: import 'package:core/src/presentation/components/<component_name>/<component_name>_view_model.dart';

part '<component_name>.freezed.dart';

/// TODO: describe the <ComponentName> component.
class <ComponentName> extends StatelessWidget {
  const <ComponentName>({
    super.key,
    // If ViewModel: required this.viewModel,
    this.theme,
  });

  // If ViewModel:
  // final <ComponentName>ViewModel viewModel;

  /// Theme overriding [<ComponentName>ThemeData.fallback].
  final <ComponentName>ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? <ComponentName>ThemeData.fallback(context);

    // TODO: build the component UI using `theme` (and `viewModel`).
    return const Placeholder();
  }
}

@freezed
sealed class <ComponentName>ThemeData with _$<ComponentName>ThemeData {
  const factory <ComponentName>ThemeData({
    // For each ThemeData field:
    required <Type> <fieldName>,
    // With a default: @Default(<value>) <Type> <fieldName>,
  }) = _<ComponentName>ThemeData;

  /// The default theme, derived from the ambient [Theme].
  factory <ComponentName>ThemeData.fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return <ComponentName>ThemeData(
      // For each field, a sensible default (see Default-by-type below).
      <fieldName>: <default>,
    );
  }
}
```

Drop the `colorScheme` / `textTheme` locals if unused (avoids lint warnings).

### 2. ViewModel — `<component_name>_view_model.dart` (only if step 2 = Yes)

```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '<component_name>_view_model.freezed.dart';

/// Immutable data/state for the <ComponentName> component.
@freezed
sealed class <ComponentName>ViewModel with _$<ComponentName>ViewModel {
  const factory <ComponentName>ViewModel({
    // For each ViewModel field:
    required <Type> <fieldName>,
    // Optional/defaulted: @Default(<value>) <Type> <fieldName>, or nullable: <Type>? <fieldName>,
  }) = _<ComponentName>ViewModel;
}
```

### Default-by-type (for the `.fallback` factory)

Use these as starting defaults, each with a `// TODO` if it needs real design values:

| Type | Default |
|---|---|
| `Color` | `colorScheme.surface` |
| `EdgeInsets` / `EdgeInsetsGeometry` | `const EdgeInsets.all(16)` |
| `BoxDecoration` | `const BoxDecoration()` |
| `BoxBorder` / `Border` | `Border.all(color: colorScheme.outlineVariant)` |
| `BorderRadius` | `const BorderRadius.all(Radius.circular(8))` |
| `Radius` | `const Radius.circular(8)` |
| `TextStyle` | `textTheme.bodyMedium!` |
| `double` | `0` (or the intended size) |
| `int` | `0` |
| `bool` | `false` |
| `Duration` | `const Duration(milliseconds: 150)` |

## Build

1. **Wire the export** (only when the component is under `packages/core/lib/`).
   Add to [packages/core/lib/core.dart](../../../packages/core/lib/core.dart),
   keeping the list alphabetically sorted like the existing entries:

   ```dart
   export 'src/presentation/components/<component_name>/<component_name>.dart';
   // If ViewModel:
   export 'src/presentation/components/<component_name>/<component_name>_view_model.dart';
   ```

   **If `packages/core/lib/components.dart` exists**, this workspace uses
   per-area barrels: put the export lines **there** instead. `core.dart` then
   only re-exports the barrels, and adding a `src/...` line to it would be
   wrong. `CLAUDE.md` names the correct target under
   `## What a component requires`.

2. **Run freezed codegen** so `<component_name>.freezed.dart` (and the
   ViewModel's) exist and the component compiles. From the monorepo root:

   ```bash
   melos build:core
   ```

   `melos build:core` scopes build_runner to the `core` package
   (`flutter pub get && dart run build_runner build --delete-conflicting-outputs`).
   Use `melos build` to regenerate every package.

3. **Demo it in the core demo app** (only when the component is under
   `packages/core/lib/`).
   [packages/core/demo/lib/main.dart](../../../packages/core/demo/lib/main.dart)
   renders a gallery of every core component, grouped by component type. Add
   the new component to the `componentSections` list there:

   - Put its demos in the `ComponentSection` whose `title` names the component's
     type (`Inputs`, `Chips`, ...). When none fits, add a new `ComponentSection`
     titled after the type, keeping sections in the order they read best.
   - Give it a `'Default'` `ComponentDemo`, plus one per state worth seeing —
     whatever the ThemeData/ViewModel makes visually distinct (selected,
     disabled, with an error, with icons).

   ```dart
   ComponentSection(
     title: '<Type>',
     demos: [
       ComponentDemo(
         name: 'Default',
         builder: (context) => const <ComponentName>(
           // If ViewModel: viewModel: <ComponentName>ViewModel(...),
         ),
       ),
     ],
   ),
   ```

   Then check it renders with `melos core:demo`, or at minimum
   `cd packages/core/demo && flutter analyze` when no device is available.

4. Report to the user: the files written, the export added, the demo section the
   component landed in, and that the widget's `build()` and the ThemeData
   defaults are `TODO` stubs to fill in.

## Update MEMORY.md

Required, before you report done. In `MEMORY.md` at the monorepo root, add or
update **one row** under `## Component Index`:

| Component | Folder | ViewModel | Key `ThemeData` fields |

Then append one line to `## Session Log`, and promote anything durable you hit
along the way — a trap to `## Gotchas`, a styling decision to `## Decisions`.

Follow `## How to maintain this file` at the top of `MEMORY.md` for the
append-vs-edit test, the id scheme, and the trim triggers. Do not restate that
protocol here, and do not copy rules out of `CLAUDE.md` into `MEMORY.md`.

## Gotchas

- **Never hand-write `.freezed.dart`.** It's a build_runner output — always
  produced by `melos build:core` / `melos build`, never authored or edited.
- **`freezed` 3.x needs `sealed` (or `abstract`).** Keep the
  `@freezed sealed class ... with _$...` shape; a bare `class` won't generate.
- **The widget file needs its own `part` directive.** The freezed `ThemeData`
  lives in the widget file (like label_chip), so
  `part '<component_name>.freezed.dart';` goes there; the ViewModel file has its
  own `part '<component_name>_view_model.freezed.dart';`.
- **Export only for `core`.** Components outside `packages/core/lib/`
  aren't exported from `core.dart` and aren't added to the demo app; fix their
  import paths (they can't use `package:core/src/...`).
- **A `TODO` stub still goes in the demo.** The demo is the gallery of what
  `core` offers — a component missing from it is invisible to everyone else.
  Add it while it still renders a `Placeholder()`; the demo fills out as the
  real `build()` lands.
- **`.fallback` must return real values.** freezed `required` fields have no
  defaults — the fallback factory must assign every field. Unassigned = compile
  error, not a warning.
- **No git commit.** Files are left on disk for the user to review, fill in the
  `TODO`s, and commit.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `The class '_$<Name>ThemeData' isn't defined` | `.freezed.dart` not generated yet — run `melos build:core`. |
| `melos: command not found` | `dart pub global activate melos`; add `$HOME/.pub-cache/bin` to `PATH`. |
| build_runner fails: "missing concrete implementation" | A `required` freezed field isn't set in `.fallback` — assign every field. |
| `Undefined name 'colorScheme'` | You referenced `colorScheme`/`textTheme` in `.fallback` but removed the local — re-add the local or drop the reference. |
| Analyzer: unused import | A ThemeData/ViewModel field's type didn't need `services.dart` (or another import) — remove it. |
