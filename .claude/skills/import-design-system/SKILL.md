---
name: import-design-system
description: Apply or update a design-system bundle (colors, semantic roles, ColorExtension, typography, font, and spacing/radius/elevation tokens) on this bp Flutter monorepo's core theme, implement any components the bundle describes, and install the bundle's design guide (DESIGN.md) and `design` skill so future UI work stays on-brand. `bp create --design-system <dir|dir/bundle.json>` already applies colors, dimensions, and typography/fonts once, deterministically, at project-creation time (the design-system folder carries bundle.json plus DESIGN.md, SKILL.md, a local fonts/ folder, an app_icons/ folder, and a launch/ folder; naming the folder or its bundle.json is the same request) -- use this skill for everything after that: rebranding/restyling an existing project, applying the bundle's components[], branding the per-flavor launcher icons from its app_icons/ folder, installing its design guide and skill, and turning a non-JSON source (a Figma link, screenshots, or a written description) into a bundle. The bundle can come from the project's own `.design-system/` folder, from a path the user supplies (a directory holding `bundle.json` plus `DESIGN.md`, `SKILL.md`, `fonts/`, `app_icons/`, and `launch/`, or the `bundle.json` inside it), or from a Claude Design handoff. Reads or derives the bundle, edits the core theme files, wires the font (google_fonts or local TTF/OTF), builds the described components, generates the production/development/staging launcher icons with flutter_launcher_icons, installs DESIGN.md + the `design` skill and points CLAUDE.md at them, and runs codegen.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - WebFetch
---

# Import a design system into the core theme

Apply a design-system bundle to this monorepo's `core` package theme, build the
components it describes, and install the guidance that keeps later UI on-brand.
All generated color / typography / dimension values live under
`packages/core/lib/src/presentation/theme/`. This skill **edits those files in
place** — it does NOT add a runtime JSON loader. Components described by the
bundle are implemented into `packages/core/lib/src/presentation/components/`.

A bundle has up to five parts. This skill handles the first four; `launch/`
belongs to `configure-launch-animation`:

| Part | Is | Where it ends up |
|---|---|---|
| `bundle.json` | the token contract — machine-applied | the `core` theme files |
| `DESIGN.md` | the design system's README: how the tokens are *meant* to be used | `.design-system/DESIGN.md`, referenced from `CLAUDE.md` |
| `SKILL.md` | a skill that makes an agent design on-brand UI | `.claude/skills/design/SKILL.md` |
| `app_icons/` | one launcher-icon PNG per flavor, described by the bundle's `appIcons` block | the native icon sets under `packages/<app>/android` and `ios` |
| `launch/` | the cold-start assets — `launch.json` (Lottie), `brand_logo.svg` (the mark) and `wordmark.svg` (the brand name) | staged at `.design-system/launch/`; the two SVGs also replace the placeholder brand artwork in `packages/<app>/assets/brand/`, and the `configure-launch-animation` skill applies the composition |

**Check what is already applied before doing any of it.** When the project was
created with `bp create --design-system`, the launcher icons are already
generated — `packages/<app>/flutter_launcher_icons-*.yaml` exists and
`ios/Runner/Assets.xcassets/AppIcon-<flavor>.appiconset` is on disk — and the
launch frame is already wired at tier `flat`. Re-running the icon section over
that is wasted work at best; the reason to touch it is a *change* (new artwork,
a flavor the bundle didn't declare, a background that no longer matches the
PNG). `bp` reports what it left undone when it finishes; if you weren't there
for that, the files above are the evidence.

Tokens alone only change what the colors are — `DESIGN.md` and the `design`
skill are what stop correct tokens from being arranged into off-brand screens,
and `app_icons/` is what stops the three flavor builds from being
indistinguishable on one home screen.
Older bundles are JSON-only; the last four parts are then simply absent.

**When you don't need this skill:** `bp create --design-system <dir|dir/bundle.json>`
already renders `colors`, `dimensions`, and `typography`/fonts from a JSON
bundle straight into the theme **at project-creation time**, deterministically
(the flag takes the design-system folder or the `bundle.json` inside it —
both pick up the folder's optional `DESIGN.md`, `SKILL.md`, `app_icons/`,
`launch/`, and a `fonts/` folder holding one
**subfolder per local family** — `<dir>/fonts/<Family>/<asset>`, where
`<Family>` matches `typography.font.families[].family` and `<asset>` is
exactly the filename in that family's `files[].asset`. They are copied to
`packages/core/lib/fonts/<Family>/<asset>` in the generated project, so the
source layout mirrors the destination. A `fonts/` subfolder matching no
declared family fails the generate. Only `local` families need a subfolder;
`google` families have no files. An `app_icons/` folder comes along too — see
below.) That one-shot apply is done before this skill ever runs — don't redo
it on a freshly-created project.

`bp create` also **generates the launcher icons** when the bundle carries both
an `appIcons` block and the `app_icons/` artwork it names. It copies and
validates the folder first — a declared PNG that is missing, a PNG no `appIcons`
entry claims, an abbreviated flavor key, or an unresolvable `background` all
fail the generate — then stages the PNGs into
`packages/<app>/assets/app_icons/`, writes one
`flutter_launcher_icons-<flavor>.yaml` per declared flavor, runs the generator,
and repoints the nine iOS build configurations at the
`AppIcon-<flavor>.appiconset` catalogs it produced. There is nothing left for
this skill to do unless the icons need to *change*.

Two cases still land here. **Artwork with no `appIcons` block**: nothing says
which PNG is which flavor and `bp` refuses to guess, so the files sit in
`.design-system/app_icons/` untouched. **A partly-declared block**: the
undeclared flavors keep the placeholder, and `flutter_launcher_icons` says
nothing about it — once one flavor file exists it runs in flavor-only mode and
silently skips whatever has no config.

**When you do need this skill:**
- Rebranding/restyling an **existing** project, or changing an
  already-applied bundle later (new palette, new type ramp, tweaked
  dimensions).
- Turning a **non-JSON source** — a Figma link, screenshots, or a written
  description — into a bundle, then applying it.
- Implementing the bundle's `components[]` — `bp create` only renders theme
  tokens, it never builds components.
- **Branding the launcher icons `bp create` could not place** — artwork the
  bundle ships with no `appIcons` block to map it to flavors, a flavor the
  block left out, or new artwork for an existing project. A project scaffolded
  from a bundle with a complete block already has its icons; check
  `packages/<app>/flutter_launcher_icons-*.yaml` before starting.
- **Installing the bundle's `DESIGN.md` and `SKILL.md`** — `bp create` copies
  them into `.design-system/` verbatim but never installs the skill and never
  touches `CLAUDE.md`. Wiring them up is this skill's job and is **not**
  optional when the bundle carries them.

**Paths below are relative to the monorepo root.** The `core` package lives at
`packages/core`. If the project was scaffolded with `bp create --design-system`,
the bundle is already at `.design-system/bundle.json` and its colors,
dimensions, and typography/fonts are already reflected in the theme files —
diff against the bundle before re-editing so you don't duplicate work. Its
`DESIGN.md` / `SKILL.md`, if present, are still uninstalled: check
`.claude/skills/design/SKILL.md` and `CLAUDE.md` rather than assuming.

## Theme layout (what you will edit)

- `theme/color_palette.dart` (`part of color_scheme.dart`) — `_ColorPalette` raw
  color tokens + two **parallel** role-alias classes: `_SemanticColors` (light)
  and `_SemanticColorsDark` (dark). Both define the same role names — dark
  values are NOT `*Dark`-suffixed members bolted onto `_SemanticColors`.
- `theme/color_scheme.dart` — `AppColorScheme extends ColorScheme`. **Do not
  edit**: it only references `_SemanticColors` / `_SemanticColorsDark`, so
  changing colors there is unnecessary.
- `theme/color_extension.dart` (`part of color_scheme.dart`) — `ColorExtension`
  `ThemeExtension` extras (variants, `link`, `transparentColor`, and
  `*Dark`-suffixed fields whose values default to `_SemanticColorsDark.<role>`).
- `theme/dimension_extension.dart` — `DimensionExtension` spacing / radius /
  elevation tokens (`DimensionExtension.defaults()` factory holds the values).
- `theme/app_theme.dart` — the M3 `textTheme` (15 roles) + font application,
  inside `_initializeDefaultThemeData`.

## Bundle schema

A bundle is JSON. Every value under `semantic.*` and `colorExtension.*` is either
a **palette key** (e.g. `"brand40"`, referencing a `palette` entry) or a literal
**hex** (`"#RRGGBB"` or `"#AARRGGBB"`). `fontWeight` is an int (100–900), applied
as `FontWeight.w<n>`. **Everything except `schemaVersion` is optional** — edit
only what the bundle specifies; leave everything else at its generated default.

`typography.font.families` is a list. Each entry needs `family` and `source`
(`"google"` or `"local"`); `local` entries also need `files[]` (`asset`,
`weight`, and optional `style: "italic"`). `roles[]` names the text roles that
family covers; anything unclaimed falls to the family marked `"default": true`.
A lone family is implicitly the default. With 2+ families exactly one must be
`default`. `source` is authoritative — a family declared `google` is fetched
from Google Fonts even if TTFs for it sit in `fonts/<Family>/` (which is an
error, not an override). Omit `font` entirely for no custom font.

```jsonc
{
  "schemaVersion": 1,
  "palette": { "brand40": "#E7F25A", "ink": "#1C1C1E", "white": "#FFFFFF" },
  "semantic": {
    "light": {
      "primary": "brand40", "onPrimary": "ink",
      "primaryContainer": "...", "onPrimaryContainer": "...",
      "secondary": "...", "onSecondary": "...",
      "secondaryContainer": "...", "onSecondaryContainer": "...",
      "tertiary": "...", "onTertiary": "...",
      "tertiaryContainer": "...", "onTertiaryContainer": "...",
      "error": "#B00020", "onError": "white",
      "errorContainer": "...", "onErrorContainer": "...",
      "surface": "white", "onSurface": "ink", "onSurfaceVariant": "...",
      "surfaceDim": "...", "surfaceBright": "...",
      "surfaceContainerLowest": "...", "surfaceContainerLow": "...",
      "surfaceContainer": "...", "surfaceContainerHigh": "...",
      "surfaceContainerHighest": "...",
      "outline": "...", "outlineVariant": "...",
      "shadow": "ink", "scrim": "...",
      "inversePrimary": "...", "inverseSurface": "...", "onInverseSurface": "..."
    },
    "dark": { "surface": "#121212", "onSurface": "white",
              "onPrimary": "...", "onSecondary": "..." }
  },
  "colorExtension": {
    "primaryVariant": "brand40", "link": "#0A84FF",
    "transparentColor": "#00000000", "surfaceVariant": "...", "errorVariant": "..."
  },
  "typography": {
    "font": {
      "families": [
        { "family": "Lexend", "source": "google", "default": true },
        {
          "family": "Inter",
          "source": "local",
          "roles": ["bodyLarge", "bodyMedium", "bodySmall"],
          "files": [
            { "asset": "Inter-Regular.ttf", "weight": 400 },
            { "asset": "Inter-Italic.ttf", "weight": 400, "style": "italic" }
          ]
        }
      ]
    },
    "roles": {
      "displayLarge":  { "fontSize": 57, "height": 1.12, "letterSpacing": -0.25, "fontWeight": 400 },
      "displayMedium": { "fontSize": 45, "height": 1.15, "letterSpacing": 0,     "fontWeight": 400 },
      "displaySmall":  { "fontSize": 36, "height": 1.22, "letterSpacing": 0,     "fontWeight": 400 },
      "headlineLarge": { "fontSize": 32, "height": 1.25, "letterSpacing": 0,     "fontWeight": 400 },
      "headlineMedium":{ "fontSize": 28, "height": 1.28, "letterSpacing": 0,     "fontWeight": 400 },
      "headlineSmall": { "fontSize": 24, "height": 1.33, "letterSpacing": 0,     "fontWeight": 400 },
      "titleLarge":    { "fontSize": 22, "height": 1.27, "letterSpacing": 0,     "fontWeight": 400 },
      "titleMedium":   { "fontSize": 16, "height": 1.5,  "letterSpacing": 0.15,  "fontWeight": 400 },
      "titleSmall":    { "fontSize": 14, "height": 1.43, "letterSpacing": 0.1,   "fontWeight": 400 },
      "labelLarge":    { "fontSize": 14, "height": 1.43, "letterSpacing": 0.1,   "fontWeight": 400 },
      "labelMedium":   { "fontSize": 12, "height": 1.33, "letterSpacing": 0.75,  "fontWeight": 400 },
      "labelSmall":    { "fontSize": 11, "height": 1.45, "letterSpacing": 0.5,   "fontWeight": 400 },
      "bodyLarge":     { "fontSize": 16, "height": 1.5,  "letterSpacing": 0.5,   "fontWeight": 400 },
      "bodyMedium":    { "fontSize": 14, "height": 1.43, "letterSpacing": 0.25,  "fontWeight": 400 },
      "bodySmall":     { "fontSize": 12, "height": 1.33, "letterSpacing": 0.4,   "fontWeight": 400 }
    }
  },
  "dimensions": {
    "spacing":   { "space4": 4, "space8": 8, "space12": 12, "space16": 16,
                   "space24": 24, "space32": 32, "space40": 40, "space48": 48,
                   "space56": 56, "space64": 64, "space72": 72, "space80": 80 },
    "radius":    { "radiusXs": 4, "radiusSm": 8, "radiusMd": 12, "radiusLg": 16,
                   "radiusXl": 20, "radiusPill": 9999 },
    "elevation": { "elevationNone": 0, "elevationLow": 1, "elevationMedium": 3,
                   "elevationHigh": 6 }
  },
  "components": [
    {
      "name": "PrimaryButton",
      "description": "Filled call-to-action button",
      "hasViewModel": false,
      "themeFields": [
        { "name": "backgroundColor", "type": "Color", "token": "colorScheme.primary" },
        { "name": "padding", "type": "EdgeInsets", "token": "space16" },
        { "name": "radius", "type": "double", "token": "radiusMd" }
      ]
    }
  ],
  "appIcons": {
    "production":  { "icon": "app_icon.png",      "background": "brand40" },
    "development": { "icon": "app_icon_dev.png",  "background": "#FF7A5C", "badge": "Dev",
                     "foreground": "app_icon_dev_foreground.png" },
    "staging":     { "icon": "app_icon_stag.png", "background": "#BDB2F5", "badge": "Stag" }
  }
}
```

`appIcons` keys are the app's flavor names — `production`, `development`,
`staging` — and nothing else; the key is what names the Android source set and
the iOS asset catalog downstream, so `dev` / `stg` are wrong. Per entry:
`icon` (required, a filename in `app_icons/`), `background` (required, palette
key or hex — the flat ground actually painted in the PNG), and the optional
`foreground` / `monochrome` filenames and `badge` label. A flavor with no entry
keeps the scaffold's placeholder icon.

The authoritative list of color roles, `ColorExtension` fields, text roles, and
dimension keys is whatever exists in the current theme files — **read them first**
(`_SemanticColors`, `_SemanticColorsDark`, `factory ColorExtension()`,
`_initializeDefaultThemeData`, `DimensionExtension`) and only edit keys that
exist there.

## Interactive flow

Ask with `AskUserQuestion`; skip anything already answered in the request.

1. **Source of truth** — offer these as the `AskUserQuestion` options:
   - **Bundle in this project** — the already-checked-in `.design-system/`
     folder. Offer this option only when `.design-system/bundle.json` exists,
     and make it the default when it does (note: if the project was created
     with `bp create --design-system`, this bundle's colors, dimensions, and
     typography/fonts are likely already applied — confirm with the user
     whether they want a re-apply/update, just the `components[]`, or just the
     still-uninstalled `DESIGN.md` / `SKILL.md`). `ls -A .design-system` so you
     know whether it carries `DESIGN.md` / `README.md` and `SKILL.md`.
   - **Bundle path supplied by the user** — the user points at a bundle
     living outside the project (a fresh export, a shared folder, a
     `Downloads/` handoff). Ask for the path, then resolve it as described in
     **Resolving a supplied bundle path** below. Use this whenever the user
     already named a path in their request, too — just skip the question.
   - **Claude Design handoff bundle** — read the handoff and use its JSON.
   - **Figma link** — fetch it (Figma tools / `WebFetch`) and extract palette,
     semantic roles, the type ramp, spacing, and radii.
   - **Screenshots / images** — read the images and derive the palette + type.
   - **Text description** — propose a palette + typography from the description.
   For every non-JSON source, first **produce a bundle conforming to the schema
   above, confirm it with the user, and write it to `.design-system/bundle.json`**
   so the result is reproducible. Then apply it. Also draft the matching
   `.design-system/DESIGN.md` and the `design` skill from what you learned about
   the source's visual language — the outline is in **Design guide and `design`
   skill** below. A derived system needs the written rules more than an exported
   one does, since nobody else wrote them down.
2. **Scope** — colors / typography / dimensions / components / app icons /
   design guide + skill, or all present in the bundle (default: all present).
3. **Font families** — read `typography.font.families[]` (`source`: `google` |
   `local`, `roles[]`, `default`). If any family is `local` and its files were
   not resolved from a supplied bundle directory, ask where its TTF/OTF files
   are.
4. **App icons** — if the bundle has an `appIcons` block but no `app_icons/`
   folder came with it (a tokens-only `bundle.json`, or artwork that arrived
   after the project was scaffolded), ask for the path to the folder holding
   the PNGs. If the bundle has no `appIcons` block, say the launcher icons
   stay as they are and move on — never invent icon artwork.

### Resolving a supplied bundle path

The path the user gives takes the same forms `bp create --design-system`
accepts — resolve it before applying anything:

- **A directory, or the `bundle.json` inside one** — both name the same design
  system, so resolve a `bundle.json` path to its parent folder and treat the
  two identically. Pointing at the JSON is the natural thing to tab-complete
  to; the assets beside it are part of the same bundle.
- **A `.json` file under any other name** — read it directly as a lone tokens
  file. Nothing else is carried by this form: no local font files (ask where
  the TTF/OTF files are, step 3), no app-icon PNGs (step 4), no `DESIGN.md`,
  no `SKILL.md`. Its neighbours are some folder of the user's, not a design
  system. Say so rather than silently shipping a tokens-only import.

The design-system folder must contain `bundle.json`, and may also contain:
- **`DESIGN.md`** (or `README.md` — same thing, `DESIGN.md` wins if both
  exist) — the design guide. See **Design guide and `design` skill** below.
- **`SKILL.md`** — the `design` skill. Same section.
- **`fonts/`** — one **subfolder per local family**:
  `<dir>/fonts/<Family>/<asset>`, where `<Family>` matches a
  `typography.font.families[].family` whose `source` is `local` and `<asset>`
  is exactly the filename in that family's `files[].asset`. Copy each into
  `packages/core/lib/fonts/<Family>/<asset>` — the source layout mirrors the
  destination — and don't ask for font paths. A `fonts/` subfolder matching no
  declared `local` family is a bundle error: stop and report it rather than
  guessing. `google` families never have files.
- **`app_icons/`** — a flat folder of launcher-icon PNGs, one set per flavor,
  named by the bundle's `appIcons` entries (`<dir>/app_icons/<icon>`). Every
  `icon` / `foreground` / `monochrome` filename must exist there, and a PNG
  that no entry claims means a flavor somebody forgot to declare — report it
  rather than guessing which flavor it belongs to. See **App icons** below.
- **`launch/`** — the cold-start assets, three fixed names. A bundle may also
  keep them loose beside `bundle.json`; `bp create` accepts either layout and
  stages them all into `.design-system/launch/`.

  | File | Is | Ends up as |
  |---|---|---|
  | `launch.json` | the cold-start Lottie composition | `packages/<app>/assets/lottie/launch.json` |
  | `brand_logo.svg` | the brand mark, vector — the same mark the `app_icons/` PNGs raster | `packages/<app>/assets/brand/brand_logo.svg` |
  | `wordmark.svg` | the brand name set as vector, drawn under the mark on the launch and landing pages | `packages/<app>/assets/brand/wordmark.svg` |

  Each is independent and each may be absent: a mark with no composition is a
  valid launch, a bundle may brand the mark and inherit the wordmark or the
  reverse, and a bundle with none of the three simply keeps bp's placeholder
  artwork. **Supplying `brand_logo.svg` and `wordmark.svg` is how a project
  stops shipping bp's placeholder brand** — nothing else replaces them.

  Both SVGs are tinted with `colorScheme.onSurface` where they render, so a
  monochrome silhouette works in light and dark without a second file. A
  multi-colour mark needs the tint removed from the launch and landing pages.

  The names are the contract. They are
  what the launch spec's `native.asset`, the Flutter asset paths, the Android
  `res/raw` copy, and the iOS overlay all reference. A brand-specific name
  (`acme-launch.json`) reads fine in the bundle folder and then becomes
  `assets/lottie/acme-launch.json` in a spec pointing at a file nobody ever
  wrote — so when a file arrived under any other name, **rename it** in
  `.design-system/launch/` and say you did.

  When a `launch.json` was there at create time, `bp` has already copied both
  into the app package, declared them under `flutter: assets:`, set the OS
  launch frame to the theme's `surface` colour via `flutter_native_splash`, and
  written a draft `launch-animation.json` whose timeline is anchored to the
  composition's measured duration. That is tier `flat` and it is as far as a
  scaffolder goes: **nothing plays the composition yet.** The Flutter launch
  page, and the choice to upgrade to tier `lottie`, belong to the
  `configure-launch-animation` skill — point the user there rather than
  building it here.

List the folder (`ls -A`) before you decide what it carries — do not infer its
contents from `bundle.json`.

Expand `~` and resolve relative paths against the monorepo root. If the path
doesn't exist, isn't readable, or is a directory with no `bundle.json`, say so
and re-ask instead of falling back to `.design-system/bundle.json` silently.

Copy the resolved bundle to `.design-system/` — `bundle.json`, plus `DESIGN.md`
and `SKILL.md` when the source has them (a `README.md` is copied **as**
`DESIGN.md`), plus `app_icons/` and `launch/` when it has them — overwriting after confirming
with the user if a different bundle is already there, so the project keeps a
reproducible record of what was applied.

## Apply

Edit in this order, then build. Use the mapping table for exact symbols.

| Bundle field | File | Symbol to edit |
|---|---|---|
| `palette.<key>` | `color_palette.dart` | `_ColorPalette.<key>` const |
| `semantic.light.<role>` | `color_palette.dart` | `_SemanticColors.<role>` |
| `semantic.dark.<role>` | `color_palette.dart` | `_SemanticColorsDark.<role>` |
| `colorExtension.<field>` | `color_extension.dart` | `factory ColorExtension()` body |
| `dimensions.*` | `dimension_extension.dart` | `DimensionExtension.defaults()` |
| `typography.roles.<role>` | `app_theme.dart` | `_initializeDefaultThemeData` textTheme `.copyWith` |
| `typography.font` | `pubspec.yaml` + `app_theme.dart` | font wiring (below) |
| `components[]` | `components/` | new component via the **create-component** skill |
| `appIcons.<flavor>` + `app_icons/` | `packages/<app>/flutter_launcher_icons-<flavor>.yaml` | one config per flavor, then `dart run flutter_launcher_icons` |
| `DESIGN.md` / `README.md` | `.design-system/DESIGN.md` | copied verbatim; `CLAUDE.md` points at it |
| `SKILL.md` | `.claude/skills/design/SKILL.md` | installed as the `design` skill |

1. **Palette** — in `color_palette.dart`, for each `palette` entry set
   `static const Color <key> = Color(0x<AARRGGBB>);` inside `_ColorPalette`. A hex
   without an alpha channel becomes `0xFF<RRGGBB>`. Add any new token the bundle
   introduces; never delete a token that is still referenced.
2. **Semantic (light)** — in `_SemanticColors`, point each role at its token:
   `static const Color primary = _ColorPalette.<ref>;`. If a role's value is a
   literal hex, add a `_ColorPalette` token for it first, then reference it.
3. **Semantic (dark)** — in `_SemanticColorsDark` (the parallel class in the
   same file, same role names as `_SemanticColors`), point each role at its
   token exactly as in step 2, from `semantic.dark`.
4. **colorExtension** — in `color_extension.dart`, update the matching field
   references inside `factory ColorExtension()`. Only change fields the bundle
   lists; leave the rest. `*Dark`-suffixed fields should reference
   `_SemanticColorsDark.<role>`, not `_SemanticColors`.
5. **Dimensions** — in `dimension_extension.dart`, edit the values inside
   `DimensionExtension.defaults()` from `dimensions.spacing/radius/elevation`.
6. **Typography roles** — in `app_theme.dart`, inside the textTheme `.copyWith`,
   update `fontSize` / `height` / `letterSpacing` / `fontWeight` per role from
   `typography.roles` (`fontWeight: <int>` -> `FontWeight.w<int>`).
7. **Font wiring** — see below.
8. **Components** — see below.
9. **App icons** — see below. Independent of everything above; it touches no
   Dart and only native icon assets.
10. **Design guide + `design` skill + `CLAUDE.md`** — see below. Do this last:
    the guide should describe a theme that is already true.

### Font wiring (per family, per role)

`typography.font.families` may declare one or more families. Each family
covers the text roles in its `roles[]`; whatever no family claims falls to
the family marked `"default": true` (a lone family is implicitly the
default). `source` is authoritative — a family declared `"google"` is fetched
from Google Fonts even if TTFs for it exist under `fonts/<Family>/` locally
(that's a bundle error, not an override).

- **Any family is `google`** — add `google_fonts` to `dependencies` in
  `packages/core/pubspec.yaml` (check the latest version — the `find-docs`
  skill can confirm it) and `import 'package:google_fonts/google_fonts.dart';`
  to `app_theme.dart`.
- **Any family is `local`** — copy its TTF/OTF files into
  `packages/core/lib/fonts/<Family>/`, and in `packages/core/pubspec.yaml`
  under `flutter:` emit a `fonts:` block with one `- family: <Family>` entry
  per local family, and under it one `- asset: lib/fonts/<Family>/<asset>` /
  `weight:` (+ `style: italic` when the file's `style` is `"italic"`) per
  `files[]` entry.
- In `app_theme.dart`, resolve the family **per role** inside the textTheme
  `.copyWith(...)` chain (`typography.font.families[].roles` picks the
  family for a role; unclaimed roles use the default family):
  - google-resolved role:
    `<role>: GoogleFonts.getFont('<Family>', textStyle: baseTheme.textTheme.<role>, color: colorScheme.onSurface, ...)`.
  - local-resolved role:
    `<role>: baseTheme.textTheme.<role>!.copyWith(color: colorScheme.onSurface, fontFamily: 'packages/core/<Family>', ...)`
    — the `packages/core/` prefix is written inline on the role itself; there
    is no `package: 'core'` parameter to set per-role.
  - On the trailing `.apply(...)`, once any family is declared, keep only
    `decorationColor: colorScheme.tertiary` — drop `fontFamily:` and
    `package:` entirely, since every role already carries its own family and
    a blanket value there would override them all uniformly.

### Components

For each entry in `components[]`:

- Map it to an existing `core` component first. Eleven ship with the scaffold
  — `AmbientBackdrop`, `FormMessage`, `FormTextInput<T>`, `IconActionButton`,
  `LabelChip`, `LabeledTextField`, `NavBar`, `PasswordField`,
  `PasswordStrengthMeter`, `PillButton`, `PromptLink` — plus whatever this
  project has added since; `MEMORY.md`'s **Component Index** is the live list.
  Only create a new one when nothing fits.
- To create one, invoke the **create-component** skill with the entry's `name`,
  `hasViewModel`, and `themeFields`. In the generated `<Name>ThemeData.fallback`,
  wire each field's value from the design-system tokens using its `token` hint:
  `colorScheme.*` / `textTheme.*` for colors and text, and
  `Theme.of(context).extension<DimensionExtension>()!.<token>` for spacing /
  radius / elevation.
- create-component wires the `core.dart` export and runs codegen for you.

### App icons (one per flavor)

The bundle's `appIcons` block plus its `app_icons/` PNGs brand the **native
launcher icon** for each of the app's three flavors — `production`,
`development`, `staging` — so three builds installed side by side are
distinguishable. Skip this whole section when the bundle has no `appIcons`
block, and never invent icon artwork.

Everything here happens inside the app package (`packages/<app>/`), not `core`.
With more than one app package, ask which app the icons are for.

1. **Stage the PNGs.** Copy `.design-system/app_icons/*` into
   `packages/<app>/assets/app_icons/`. They are build-time inputs to the icon
   generator, **not** Flutter assets — do not declare them under
   `flutter: assets:` in the pubspec.
2. **Add the generator.** Put `flutter_launcher_icons` in `dev_dependencies` of
   `packages/<app>/pubspec.yaml` (confirm the current version with the
   **find-docs** skill) and run `melos bs`.
3. **Write one config per flavor** — three files beside that pubspec:
   `flutter_launcher_icons-production.yaml`,
   `flutter_launcher_icons-development.yaml`,
   `flutter_launcher_icons-staging.yaml`. The suffix is load-bearing twice: it
   selects the Android source set (`android/app/src/<flavor>/res/`) and names
   the iOS asset catalog (`AppIcon-<flavor>.appiconset`). It must equal the
   gradle `productFlavors` name exactly — `development`, never `dev`.

   ```yaml
   # packages/<app>/flutter_launcher_icons-development.yaml
   flutter_launcher_icons:
     image_path: "assets/app_icons/app_icon_dev.png"
     android: "ic_launcher"
     min_sdk_android: 21
     adaptive_icon_background: "#FF7A5C"
     adaptive_icon_foreground: "assets/app_icons/app_icon_dev_foreground.png"
     ios: true
     remove_alpha_ios: true
     background_color_ios: "#FF7A5C"
   ```

   - `android: "ic_launcher"` matches the `android:icon="@mipmap/ic_launcher"`
     the scaffold's `AndroidManifest.xml` already declares. Renaming it is a
     separate decision — don't.
   - Resolve `background` through `palette` to a literal `#RRGGBB` first: the
     YAML cannot read palette keys.
   - `adaptive_icon_background` and `adaptive_icon_foreground` are **both or
     neither** — the generator writes adaptive icons only when both are set,
     and it never promotes `image_path` to the foreground. When the entry has
     no `foreground`, drop both keys; that flavor ships legacy icons only.
   - `remove_alpha_ios: true` is not optional: App Store Connect rejects an
     icon carrying an alpha channel, and the bundle's PNGs may have one.
     `background_color_ios` is what shows through where the alpha was, so set
     it to the same hex as the background.
   - **Production needs its own flavor file too.** As soon as one
     `flutter_launcher_icons-*.yaml` exists the tool runs in flavor-only mode,
     ignoring a plain `flutter_launcher_icons.yaml`, a
     `flutter_launcher_icons:` block in `pubspec.yaml`, and the `-f` flag
     alike.
4. **Generate.** From `packages/<app>/`: `dart run flutter_launcher_icons`. One
   run loops every `flutter_launcher_icons-*.yaml` it finds, so all three
   flavors are covered.
5. **Point iOS at the new catalogs — by hand.** Generation creates
   `ios/Runner/Assets.xcassets/AppIcon-<flavor>.appiconset`, but the tool's
   Xcode auto-wiring matches the flavor against the *xcconfig file name*
   (`Debug` / `Release`), which never contains a flavor — so it silently leaves
   `project.pbxproj` untouched and the app keeps building the old icon set.
   The scaffold ships nine `ASSETCATALOG_COMPILER_APPICON_NAME` lines
   (`Debug` / `Release` / `Profile` × three flavors). Rewrite them:

   | Build configurations | Set to |
   |---|---|
   | `Debug-production`, `Release-production`, `Profile-production` | `"AppIcon-production"` |
   | the three `*-development` configurations | `"AppIcon-development"` |
   | the three `*-staging` configurations | `"AppIcon-staging"` |

   Then verify with `grep -n ASSETCATALOG_COMPILER_APPICON_NAME
   packages/<app>/ios/Runner.xcodeproj/project.pbxproj` — nine lines, and every
   name has a matching `.appiconset` folder on disk.
6. **Verify Android.**
   `packages/<app>/android/app/src/<flavor>/res/mipmap-*/ic_launcher.png` now
   exists for all three flavors. Leave the scaffold's icons under
   `android/app/src/main/res/` in place — a flavor's own source set overrides
   `main` for that flavor, and `main` stays the fallback.

Report which flavors got new icons and which kept the placeholder.

### Design guide and `design` skill

The tokens are now correct. This step is what keeps them *used* correctly.
Do all three parts — a `DESIGN.md` nobody is routed to is dead weight.

**1. Install the design guide.** Copy the bundle's `DESIGN.md` (or its
`README.md`, under the name `DESIGN.md`) to `.design-system/DESIGN.md`,
verbatim — do not rewrite, summarize, or reformat it. Read it once afterwards
and reconcile it against what you just applied: if it names a token, role, or
component that the bundle does not define, note the mismatch in your report
rather than editing the guide to fit.

**2. Install the `design` skill.** Copy the bundle's `SKILL.md` to
`.claude/skills/design/SKILL.md` (create the folder). Before writing it, check
its frontmatter and fix only these, leaving the body alone:

- `name:` must be exactly `design` — it has to match the folder name or the
  skill will not load.
- `description:` must be present and non-empty; it is the only text an agent
  sees when deciding to invoke the skill. If it is missing, write one naming the
  design system and its triggers (designing a screen, building a page, adding a
  component, restyling, visual review).
- Any path it references must resolve in this project. Rewrite a reference to
  the guide as `.design-system/DESIGN.md`.

If a skill already exists at that path, show the user a diff and confirm before
overwriting — the old one may have been hand-tuned.

**3. Point `CLAUDE.md` at both.** Without this, an agent building a page never
learns the guide exists. Make these four edits, each **idempotent** — check for
the text first and skip it if a previous run already added it:

| Section in `CLAUDE.md` | Edit |
|---|---|
| `## The four files` | Add a row: `\| \`.design-system/DESIGN.md\` \| *How should this look?* The design system's rules — color roles in use, type ramp, spacing, component catalog, composition patterns. \| on demand (before any UI work) \|` and retitle the section `## The five files`. |
| `## Hard rules`, rule 4 (*Styling comes from the theme*) | Append: `**Which** role, size, or spacing to reach for is \`.design-system/DESIGN.md\` — read it before designing any UI, and run the \`design\` skill when creating or restyling a page, screen, or component.` |
| `## What a component requires` | Under the contract bullets, add: `- The component's look — variants, states, sizing, when to use it — comes from \`.design-system/DESIGN.md\`. Run the \`design\` skill first when the component is new to the design system.` |
| `## Skill routing` | Add as the **first** row of the table: `\| Design or restyle any UI — a page, screen, component, or state \| \`design\` (reads \`.design-system/DESIGN.md\`) \|`. It goes first because it decides what the UI should look like; `implement-feature` / `create-component` / `implement-prototype` then decide how the code is structured. |

Keep every edit a surgical insertion. Do not restructure `CLAUDE.md`, do not
copy rules out of `DESIGN.md` into it, and do not touch any other section — one
fact, one home.

**When the bundle has neither file.** A tokens-only bundle (a bare
`bundle.json`, or an older export) carries no guide and no skill. Don't
fabricate a full design system silently. Tell the user what is missing, then
offer to draft both from what the bundle and the source actually show. If they
accept, `DESIGN.md` follows this outline, and every rule in it must name keys
that exist in the bundle:

1. Identity — the product, the feeling, the one recognizable thing.
2. Principles — 3–6 numbered rules a reviewer can check against a screen.
3. Color in use — `role → what it's for → what it is NOT for`, the accent
   hierarchy (primary CTA / secondary emphasis / destructive), dark-mode intent.
4. Typography in use — `text role → where it appears`; every one of the 15 roles
   gets a home or is marked unused.
5. Spacing & layout — base grid, page padding, section gap, list gap, in-card
   gap, minimum touch target, each named as a `dimensions.spacing` key.
6. Shape & elevation — the `radius` key per surface class (button, input, card,
   sheet, chip) and exactly when a shadow is allowed.
7. Component catalog — one subsection per `components[]` entry: anatomy,
   variants, states, sizing, when to use / when not to.
8. Composition patterns — the 3–5 recurring screen shapes as ordered recipes,
   each including the loading / empty / error treatment.
9. Accessibility — guaranteed contrast pairs, minimum body size, never convey
   state by color alone.
10. Token access — `Theme.of(context).colorScheme.<role>`,
    `.textTheme.<role>`, `Theme.of(context).extension<DimensionExtension>()!.<key>`,
    `Theme.of(context).extension<ColorExtension>()!.<field>`, then a **Never**
    list: no literal hex, no magic padding/radius, no hand-built `TextStyle`.

The drafted `design` skill stays under ~200 lines and contains: frontmatter
(`name: design`), a hard first step to read `.design-system/DESIGN.md`, a
`UI element → component/pattern → tokens` decision table, a build order for a
new screen (pattern → components → spacing → loading/empty/error → dark mode),
and a self-review checklist. It must **not** restate the catalog from
`DESIGN.md`, and must **not** carry Dart architecture rules — layering, codegen,
routing, and state management belong to `CLAUDE.md` and the sibling skills, and
it should hand off to `create-component`, `implement-feature`, and
`implement-prototype` by name for those.

Confirm the drafts with the user before writing, then install them as in parts
1–3 above.

## Build

From the monorepo root run `dart run melos build:core` (regenerates
`.freezed.dart` for any changed freezed classes), then `dart run melos analyze`.
Report which files changed and the build result. Never hand-write
`.freezed.dart`. Do not `git commit`.

App icons are outside that loop — `dart run flutter_launcher_icons` writes
native assets only, so it neither needs nor triggers codegen, and `analyze`
will not catch a mis-wired icon. The icon checks in the section above are the
only verification it gets.

## Update MEMORY.md

Required, before you report done. In `MEMORY.md` at the monorepo root:

- **`## Design System`** — replace the section in place with what is now true:
  the bundle's name/source, a one-line palette summary, the font families,
  which of the bundle's `components[]` are implemented versus still pending,
  which flavors carry branded launcher icons versus the placeholder, and
  whether `.design-system/DESIGN.md` and the `design` skill are installed
  (or that the bundle carried neither).
- **`## Current State`** — update the design-system line.
- **`## Decisions`** — add one `D-<n>` entry recording which bundle was applied
  and where it came from, so a later re-brand knows what it is replacing.
- **`## Component Index`** — one row for each component this run created.
- **`## Session Log`** — one line.

Follow `## How to maintain this file` at the top of `MEMORY.md` for the
append-vs-edit test and the trim triggers. Do not restate that protocol here.

## Gotchas

- **Do not edit `color_scheme.dart`** — `AppColorScheme` reads only from
  `_SemanticColors` / `_SemanticColorsDark`. Change colors in
  `color_palette.dart`.
- Dark colors live in `_SemanticColorsDark`, a full parallel class to
  `_SemanticColors` with the same role names — there is no `*Dark`-suffixed
  member on `_SemanticColors` itself. `color_extension.dart`'s `*Dark`-suffixed
  fields default to `_SemanticColorsDark.<role>`.
- `color_palette.dart` and `color_extension.dart` are `part of
  'color_scheme.dart'` — do NOT add imports to them; edit in place.
- Do not delete a `_ColorPalette` token still referenced by an unedited role.
- **Per-role family, not a blanket one.** Once any family is declared,
  `.apply(...)` carries only `decorationColor:` — adding `fontFamily:` /
  `package:` there overrides every role uniformly and defeats per-role
  families.
- Local fonts: the pubspec `family:` must match the
  `fontFamily: 'packages/core/<Family>'` string written on that family's
  roles exactly, or the font silently falls back.
- `source` is authoritative, not file presence: a `google` family is still
  fetched from Google Fonts even if stray TTFs for it sit under
  `fonts/<Family>/` — that's a bundle error, not an override.
- Keep `fontWeight` as `FontWeight.w<NNN>` (the bundle gives an int).
- `DimensionExtension` and `ColorExtension` are already registered on the theme
  (`app_theme.dart`), so no registration step is needed after editing values.
- **`DESIGN.md` is copied, never rewritten.** It is the design system's own
  words; paraphrasing it into your own is how a guide stops matching the design
  it documents. Report mismatches instead of fixing them silently.
- The `design` skill's folder name and its frontmatter `name:` must both be
  `design`, or Claude Code will not load it.
- A bundle that carries `README.md` instead of `DESIGN.md` means the same
  thing — install it as `.design-system/DESIGN.md`. If both exist, `DESIGN.md`
  wins and you say so in the report.
- Applying tokens without installing the guide/skill is a **half-import**: the
  colors change and the next screen is still off-brand. The `CLAUDE.md` edits
  are the part that actually routes future work.
- **App icons: the flavor name is the API.** The
  `flutter_launcher_icons-<flavor>.yaml` suffix picks the Android source set
  *and* names the iOS asset catalog. `-dev.yaml` writes to a nonexistent
  `android/app/src/dev/res/` that gradle never reads, so the icon silently
  never changes.
- One `flutter_launcher_icons-*.yaml` puts the tool in **flavor-only mode** — a
  plain `flutter_launcher_icons.yaml` and the `-f` flag are then ignored, which
  is why production gets a flavor file of its own rather than the default one.
- The tool does **not** rewire iOS for flavors in this scaffold: it matches the
  flavor against the xcconfig file name (`Debug` / `Release`), never against
  the build-configuration name, so `ASSETCATALOG_COMPILER_APPICON_NAME` is a
  manual edit. Skipping it is the classic "new icon on Android, old icon on
  iOS" bug.
- Android adaptive icons need `adaptive_icon_background` **and**
  `adaptive_icon_foreground`; `image_path` is never used as the foreground.
  Setting only the background produces no adaptive icon at all.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Build fails on `*.freezed.dart` | Re-run `dart run melos build:core` after saving. |
| The `design` skill never triggers | Folder is `.claude/skills/design/`, frontmatter `name:` is `design`, and `description:` names the trigger cases. |
| An agent still hardcodes colors | The `CLAUDE.md` edits were skipped — rule 4 and the `## Skill routing` row are what point it at `DESIGN.md`. |
| `DESIGN.md` cites a token the theme lacks | The guide and the bundle disagree; report it, don't invent the token. |
| `Undefined name '_ColorPalette.x'` | You referenced a token from a role without adding it to `_ColorPalette` first. |
| Font not visible (google) | Confirm the family exists in the google_fonts catalog and the role resolves to it (`roles[]` / `default`). |
| Font not visible (local) | Confirm asset paths + that pubspec `family:` matches the `fontFamily: 'packages/core/<Family>'` string on that role. |
| Analyzer "unused" token warning | Acceptable, or remove the orphaned `_ColorPalette` token. |
| Icon changed on Android, not on iOS | `ASSETCATALOG_COMPILER_APPICON_NAME` still names the old set — step 5 of **App icons** was skipped. |
| Icon changed on iOS, not on Android | The yaml's flavor suffix doesn't match a gradle `productFlavors` name, so the output went to a source set gradle never reads. |
| Only the production icon changed | A `flutter_launcher_icons.yaml` (or a `pubspec.yaml` block) was used instead of three per-flavor files — flavor-only mode ignored it. |
| Android icon is square, not adaptive | `adaptive_icon_foreground` is missing; the bundle entry has no `foreground` PNG. |
| App Store upload rejected for an alpha channel | `remove_alpha_ios: true` missing from that flavor's yaml. |
| `image_path` not found | Paths in the yaml are relative to `packages/<app>/`, not the monorepo root. |
