# Otto Design System

Otto is a round-trip rideshare app: riders book both legs of a trip at once, track their
driver live, and split fares without rebooking or renegotiating. The UI should feel calm,
friendly, and confident — one bold lime accent doing all the work against black text and a
clean white ground, so the eye always knows where the live trip status is.

## Principles

1. **One accent, used once per screen.** Lime (`colorScheme.primary`) marks exactly one
   surface per screen — almost always the active/next-action card. Everything else is
   black-on-white or grey-on-white.
2. **Status lives in a card, never in a color alone.** A trip's state (on route, upcoming,
   needs action) is shown with an icon + label pair, never by tinting text or a row red/green.
3. **Pills over rectangles.** Any tappable control (button, input, chip, tab) is fully
   rounded (`radiusPill`). Only content containers (cards, sheets) use partial radii.
4. **Flat surfaces, minimal shadow.** Depth comes from the lime card sitting on white, not
   from drop shadows. Shadows are reserved for `elevationLow`/`elevationMedium` on things that
   float above content (bottom sheets, floating actions).
5. **Display type is for greetings and headlines only.** Baloo 2 (rounded, bold) is reserved
   for the greeting and section headlines; everything else — labels, body, buttons — is Inter,
   so dense trip data stays legible at small sizes. *(derived)*
6. **The lime card is the hierarchy anchor.** Whatever sits inside the primary lime card
   (search, live status) is the single most important thing on screen; below it is always a
   flat list.

## Color in use

| Role | For | Not for |
|---|---|---|
| `primary` / `onPrimary` | The active-trip / search card fill; the primary CTA | Body text, large backgrounds, more than one card per screen |
| `primaryContainer` / `onPrimaryContainer` | Soft lime tints — selected chip, subtle highlight | The main CTA fill (use `primary` instead) |
| `secondary` / `onSecondary` | Secondary text emphasis, inactive nav icon | Any CTA |
| `tertiary` / `onTertiary` | Warning glyphs (e.g. "departure needs confirmation"), a soft callout | Errors that block the user (use `error`) |
| `error` / `onError` | Destructive actions (cancel trip), failed bookings, form validation | Warnings that aren't blocking — use `tertiary` |
| `surface` / `onSurface` | Page background and default card fill; primary text | — |
| `onSurfaceVariant` | Secondary/muted text (timestamps, helper copy) | Primary trip titles |
| `surfaceContainer` … `surfaceContainerHighest` | Nested cards/list rows sitting on `surface` (ladder from lowest to most separated) | The single hero lime card |
| `outline` | Hairline dividers, input borders | Anything load-bearing for meaning |
| `colorExtension.routeActive` / `routeInactive` | Timeline dot state in `RouteTimeline` | General UI accents |

**Accent hierarchy:** lime (`primary`) = the one thing to do next. Ink outline `BrandButton`
= secondary emphasis. Coral (`tertiary`/`error`) = warnings and destructive actions only.

**Dark mode:** surfaces invert to near-black (`darkSurface`/`darkCard`); lime keeps full
saturation as the one accent that must survive both modes unchanged. *(derived)*

## Typography in use

| Role | Where |
|---|---|
| `displayLarge`/`displayMedium`/`displaySmall` | Unused in this product — reserved for a future marketing/onboarding surface |
| `headlineLarge`/`headlineMedium` | Rare full-screen moments (empty state title, onboarding) |
| `headlineSmall` | The "Hi {name}!" greeting — never wraps past one line |
| `titleLarge` | Screen titles (Trips, Profile) |
| `titleMedium` | Card titles (trip destination, "Next Stop in 34 min") |
| `titleSmall` | List-row titles (a past-trip stop name) |
| `bodyLarge` | Primary reading copy (trip summary, help text) |
| `bodyMedium` | Standard body copy, the greeting subtitle, list-row detail line |
| `bodySmall` | Timestamps, helper captions |
| `labelLarge` | Button labels |
| `labelMedium` | Chips, driver rating tag, tab labels |
| `labelSmall` | Overlines ("On Route"), badges |

Default line length for body copy is ~40 characters at mobile width (cards are narrow).
`titleMedium` trip titles never truncate mid-word — wrap to a second line instead.

## Spacing & layout

- Base grid: 4pt (`space4`…`space80`).
- Screen padding: `space16` on mobile edges.
- Gap between stacked cards: `space16`. Gap between sections: `space24`–`space32`.
- Padding inside a card: `space16` (list row) to `space24` (hero status card).
- Minimum touch target: 44×44 logical px (nav icons, icon buttons).
- Layout rhythm: one hero card (search or live status) at the top of the trips screen, then a
  flat vertical list of `TripListItem`s below — no side-by-side card grids on mobile.

## Shape & elevation

| Surface | Radius |
|---|---|
| Button / chip / input | `radiusPill` |
| List row / small card | `radiusMd` (16) |
| Standard card | `radiusLg` (24) |
| Hero status card, bottom sheet | `radiusXl` (32) |

Shadows: `elevationNone` for anything sitting flat on `surface` (list rows, the hero card
itself). `elevationLow` only for something that floats above the page — a bottom sheet, a
floating action button, an open dropdown. Never stack elevation on more than one surface at
once.

## Component catalog

### RideStatusCard
The lime hero card. Anatomy: optional overline label (e.g. "On Route"), a greeting or a live
status line, then either a `SearchDestinationField` (idle state) or trip details (active
state). States: **idle** (search prompt), **active** (live ETA + driver rating), **loading**
(status line replaced by a shimmer placeholder), **error** (falls back to idle with a small
coral inline notice). Sizing: full card width, min height 200. Use for the one live/next
action per screen. Do not use for anything not tied to the current or next trip.

### RouteTimeline
Anatomy: a vertical line connecting a filled dot (departure, checked) to an outlined dot
(next stop), each with a label. A trailing "Details +" pill reveals the full stop list.
States: default, and a disabled/greyed line when a trip is cancelled. Use inside
`RideStatusCard` or a trip detail screen. Do not use for anything with more than two stops
inline — collapse to a summary instead.

### SearchDestinationField
Anatomy: pill input, leading search icon, greyed placeholder text on a white fill (so it
reads against the lime card behind it). States: default, focused (outline appears), filled.
Always the entry point to the booking flow — never used as a generic text field elsewhere
(use a standard Material `TextField` styled from `titleMedium`/`outline` for that).

### GreetingHeader
Anatomy: circular avatar, "Hi {name}!" in `headlineSmall`/display family, one-line prompt in
`bodyMedium`. Use once, at the top of the home screen. Never repeat the greeting elsewhere.

### TripListItem
Anatomy: date label, a status glyph (checkmark = confirmed, coral triangle = needs attention),
driver rating chip, small car-photo avatar. States: default, needs-attention (triangle +
coral tint on the glyph only, not the row), disabled/past (reduced opacity). Use for every row
in the trips list. Do not use for the active trip — that belongs in `RideStatusCard`.

### BrandButton
Anatomy: pill, centered label. Variants: **filled** (lime, primary action), **outline** (ink
ring, secondary action), **destructive** (coral fill, e.g. "Cancel Trip"). States: default,
pressed (flat 10% darker fill, no shadow shift), disabled (`surfaceContainerHigh` fill,
`onSurfaceVariant` label). Use for every tappable CTA; never a bare `TextButton` for a primary
action.

## Composition patterns

**Home / trips screen:** `GreetingHeader` → `RideStatusCard` (idle or active) → section label
→ vertical list of `TripListItem` → bottom nav. Loading: `RideStatusCard` shimmer + 2–3
skeleton `TripListItem` rows. Empty: `RideStatusCard` idle state, then a single centered line
("No trips yet — search above to book your first round trip") in place of the list. Error:
same as idle, with an inline coral notice line beneath the search field.

**Trip detail (sheet or full screen):** `RouteTimeline` (expanded) → fare/driver summary card
→ `BrandButton` row (outline "Message driver", destructive "Cancel Trip"). Loading: timeline
renders with placeholder dots. Error: destructive button disabled with a coral helper line.

**Booking flow (multi-step):** `SearchDestinationField` (outbound) → same field (return,
optional) → fare estimate card → `BrandButton` (filled, "Confirm Round Trip"). Empty state N/A
(always has the two inputs). Error: inline coral text under the failing field, button disabled.

## Accessibility

- Guaranteed-legible pairs: `onPrimary` on `primary`, `onSurface` on `surface`,
  `onError`/`onTertiary` on their fills — all meet WCAG AA at body sizes.
- Minimum body text size is 14px (`bodyMedium`); never go below it for anything but
  `labelSmall` badges.
- Trip/warning state is always paired with an icon + text label, never color alone (see
  Principle 2).

## Token access (Flutter)

| Need | Read it from |
|---|---|
| An M3 color role | `Theme.of(context).colorScheme.<role>` |
| A text style | `Theme.of(context).textTheme.<role>` |
| Spacing / radius / elevation | `Theme.of(context).extension<DimensionExtension>()!.<key>` |
| A non-M3 brand color | `Theme.of(context).extension<ColorExtension>()!.<field>` |

**Never:** a literal hex in widget code. A magic padding or radius number. A `TextStyle` built
from scratch instead of `textTheme`. A color picked for looks over its role meaning above.
