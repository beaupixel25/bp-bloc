# Core Package

Shared domain, DI, theme, and reusable UI components for bp-riverpod.

Everything here is app-agnostic: exceptions, use cases, the error-handling
machinery, the design-system colour library, and the presentation components
consumed by every app package. Import it through the single barrel:

```dart
import 'package:core/core.dart';
```

## Layout

```
lib/
  core.dart                      # Public barrel — export everything consumable here
  src/
    constants/                   # DI environment names, etc.
    data/repositories/           # BaseRepository — maps raw errors to AppExceptions
    data/services/               # ApiClient — status + backend code to AppException
    domain/
      exceptions/                # AppException vocabulary
      use_cases/                 # UseCase base class
    error/                       # Vendor-agnostic ErrorReporter
    presentation/
      bloc/                      # Typed error routing + status enums
      components/                # Reusable UI components (see below)
      error/                     # AppException -> user message mapping
      theme/                     # ColorScheme, ColorExtension, AppTheme
      views/apps/app/            # App / BaseApp wrappers
```

## Component architecture

Reusable components live under `src/presentation/components/`. Each component is
built from **four cooperating classes** so that *what a component shows*, *how it
looks*, and *how it is themed* stay independent and independently overridable.

For the full rationale see
[Building flexible & adaptive Flutter UI with components and custom themes](https://medium.com/@qt.nguynh/building-flexible-and-adaptive-flutter-user-interface-with-components-and-custom-themes-ee71333a586).

| Class | Role |
|-------|------|
| **Widget** (`FormTextInput`, `LabelChip`) | The public widget. Holds no styling constants — it reads everything visual from its `ThemeData` and everything data-related from its `ViewModel`. |
| **ThemeData** (`FormTextInputThemeData`, `LabelChipThemeData`) | An immutable [`freezed`] data class describing *every* visual property (colours, borders, paddings, text styles). Exposes a `.fallback(context)` factory that derives sensible defaults from the ambient `Theme.of(context)`, so a component looks correct with zero configuration. |
| **Theme** (`FormTextInputTheme`) | An `InheritedWidget` that propagates a `ThemeData` down the tree. Its static `of(context)` resolves the nearest instance and falls back to `ThemeData.fallback(context)` when none is provided — letting you theme a whole subtree once instead of per-widget. |
| **ViewModel** (`FormInputViewModel` / `FormTextInputViewModel`) | An immutable [`freezed`] model carrying the component's *data and behavioural state* (label, hint, error text, value, obscuring, validation mode…), deliberately separate from styling. |

### Why split it this way

- **Styling is data.** Because `ThemeData` is a plain value object, a caller can
  `copyWith` one property, build a variant, or swap the whole theme without
  touching the widget.
- **Zero-config defaults, full override.** `ThemeData.fallback(context)` reads
  the app `ColorScheme`/`ColorExtension`, so components adapt to light/dark and
  brand colours automatically — yet any value can still be overridden.
- **Theme once, apply widely.** Wrap a subtree in the component's `Theme`
  `InheritedWidget` and every descendant widget of that type picks up the shared
  styling via `of(context)`.
- **State ≠ style.** The `ViewModel` holds what to show; the `ThemeData` holds
  how to show it. Each evolves without disturbing the other.

### Resolution order inside a component

```dart
// 1. explicit theme passed to the widget, else
// 2. nearest FormTextInputTheme.of(context) InheritedWidget, else
// 3. FormTextInputThemeData.fallback(context) derived from Theme.of(context)
final theme = widget.theme ?? FormTextInputTheme.of(context);
```

### The components that ship

| Component | ViewModel | What it is for |
|---|---|---|
| `PillButton` | no | The call to action. `isDimmed` gates a form without disabling the button, so an incomplete submit answers with a message instead of silence. |
| `IconActionButton` | no | A 44pt circular tap target around one `AppIcons` glyph. `semanticLabel` is required and should name the action, not the icon. |
| `FormMessage` | no | Form feedback, error or success. The glyph is required: colour never carries the meaning on its own. |
| `LabeledTextField` | no | The outlined input with the label above it. Has `trailing` and `footer` slots. |
| `FormTextInput<T>` | yes | The filled input with a floating in-field label. Use for dense forms. |
| `PasswordField` | no | `LabeledTextField` + show/hide toggle + optional strength meter. Owns only its obscure state. |
| `PasswordStrengthMeter` | yes | The strength ramp. It informs; it never blocks and never scolds. |
| `PromptLink` | no | "Already have an account? **Log in**" — the whole line is the tap target. |
| `LabelChip` | no | A small tappable pill label. |
| `NavBar` | no | The floating pill of destinations. The pill only — the app positions it. |
| `AmbientBackdrop` | no | A soft wash derived from the colour scheme. Needs no artwork and restyles with any bundle. |

Icons come from `AppIcons` and render through `AppIcon`, which tints the SVG
from the theme. `core` bundles no raster art; `AppImages` exists so anything
added later builds its path the same way.

Run `melos core:demo` to see all eleven, in light and dark.

### Adding a new component

1. Create `src/presentation/components/<name>/`.
2. Add the four classes: `<Name>` (widget), `<Name>ThemeData` (`@freezed`, with a
   `.fallback(context)` factory), optionally `<Name>Theme` (`InheritedWidget`
   with `of(context)`), and a `<Name>ViewModel` (`@freezed`) when the component
   carries data/state.
3. Export the public files from `lib/core.dart`.
4. Run codegen: `dart run build_runner build --delete-conflicting-outputs`.

## Codegen

The components and theme data classes use [`freezed`], so after generation (or
any change) run:

```dart
dart run build_runner build --delete-conflicting-outputs
```

## Demo

`demo/` is a runnable Flutter app that showcases the core theme and components.

[`freezed`]: https://pub.dev/packages/freezed
