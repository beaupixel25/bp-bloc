---
name: design
description: Applies the Otto design system's visual language — a friendly lime-and-ink rideshare aesthetic, pill controls, and a flat single-accent hierarchy — when creating or changing any UI in this Flutter app: new pages/screens, new components, layout or spacing changes, restyling, or a "make this look right"/visual-review request. Do not use for Dart architecture, state management, routing, or data-layer work — see the delegated skills below for those.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

Read `.design-system/DESIGN.md` first, every time. It is the source of truth for roles,
components, and composition patterns — this skill is only the procedure for applying it.
Decision-critical rules from there, repeated because they're easy to violate by accident:
one lime accent per screen; status is icon+label, never color alone; all tappable controls
are pill-shaped; display type only for the greeting/headlines.

## Decision table

| UI element I need | Use | Reads |
|---|---|---|
| Primary CTA | `BrandButton` (filled) | `colorScheme.primary`, `radiusPill` |
| Secondary action | `BrandButton` (outline) | `colorScheme.onSurface`, `radiusPill` |
| Destructive action | `BrandButton` (destructive) | `colorScheme.error` |
| Hero "what's next" card | `RideStatusCard` | `colorScheme.primary`, `radiusXl` |
| Trip search entry point | `SearchDestinationField` | `colorScheme.surface`, `radiusPill` |
| Two-stop route display | `RouteTimeline` | `colorExtension.routeActive/routeInactive` |
| Screen-top personalization | `GreetingHeader` | `textTheme.headlineSmall` |
| A row in a trips list | `TripListItem` | `colorScheme.surface`, `radiusMd` |
| Generic text field (not booking) | plain `TextField` themed from `textTheme.titleMedium` + `colorScheme.outline` | — |

## Build order for a new screen

1. Pick the composition pattern from `DESIGN.md` (home/trips, trip detail, booking flow) —
   don't invent a new screen shape without checking there first.
2. Place components top to bottom per that pattern's recipe.
3. Apply spacing tokens: `space16` screen edges, `space16` between cards, `space24`–`space32`
   between sections.
4. Add loading (shimmer/skeleton), empty, and error states for every data-bound component —
   these are required, not optional polish.
5. Verify dark mode: re-check every color reference resolves through `colorScheme`/theme
   extensions, not a literal light-mode hex.

## Self-review checklist

- [ ] Exactly one lime (`primary`) surface on screen
- [ ] Every status shown with an icon + label, not color alone
- [ ] Every tappable control is pill-shaped
- [ ] Display/headline font used only for greeting/headlines, not body or labels
- [ ] No literal hex anywhere in the diff
- [ ] No magic padding/radius numbers — every value is a `dimensions` token
- [ ] Every text style comes from `textTheme`, none built inline
- [ ] Loading / empty / error states present for data-bound components
- [ ] Dark mode checked and legible
- [ ] `onX`/container contrast pairs used correctly (never `onPrimary` on `surface`, etc.)

## Delegate rather than duplicate

This skill decides **what the UI should look like**. These sibling skills decide **how the
code is structured** — run this one first, then hand its visual spec to whichever applies:

- `create-component` — scaffolding a new reusable widget + its `ThemeData` into `core`.
- `implement-feature` — a full Clean Architecture feature (data/domain/presentation).
- `implement-prototype` — implementing a slice of an existing Claude Design prototype.
- `import-design-system` — re-applying or changing the token bundle itself.
