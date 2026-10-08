# ADR-0089 — Aurora design language (supersedes the ADR-0083 palette, type, and chrome clauses)

**Status**: Superseded in part by [ADR-0093](0093-duet-design-language.md) — §4 (icons), §6 (interaction), and §7 (motion) still stand
**Date**: 2026-09-28

**Supersedes**: [ADR-0083](0083-paper-graphite-light-dark.md) §1 (paper / graphite neutrals), §4 (chrome), §5 (type + radii). ADR-0083 §3 (System / Light / Dark theme mode) still stands.
**Amends**: [ADR-0018](0018-shared-interactive-primitives.md) (adds `EnjoyPressable`; the tappable kit no longer paints ink ripples), [ADR-0055](0055-adaptive-page-layout-system.md) (page kinds unchanged; desktop pages now sit on a floating content panel).

## Context

The app read like "an Android app running everywhere": Material 3 ink ripples on every surface, the stock pill-indicator navigation idiom, M3 tonal cards and chunky `FilledButton` proportions, Material `Icons` mixed with a small hand-drawn SVG sprite, and per-platform page transitions (zoom on Android, fade-upwards on Windows / Linux, slide on Apple). Nothing was wrong individually, but together the product had no single visual voice and felt least native on desktop.

## Decision

Adopt **Aurora**: *quiet chrome, luminous content*. Material remains the widget toolkit; it is no longer the look.

1. **Palette** — Cool neutrals with a faint iris cast: **porcelain** light (`#F7F7F9` page, `#ECECF1` canvas, white cards) and **midnight** dark (`#111115` page, `#09090B` canvas, `#17171C` cards). One iris accent (`#5B4BE8` light / `#6D5DFC` dark fills; `#4F3FD6` / `#A99BFF` inks), chosen by computed WCAG contrast — both fills carry white labels at ≥ 4.5:1. Semantic inks: echo coral, intelligence blue, listening-focus teal, score green / amber / red. Surfaces are addressed by role tokens (`canvas`, `card`, `popover`, `fill`, `hairline`, `textFaint`) on `EnjoyThemeTokens`.
2. **Aurora glow** — The logo's blue → violet gradient is the signature light: a soft static radial glow pooled at the top of every page (`AuroraGlow`, no blur filters), the Today's Goal ring, the Pro badge, the credits meter, the profile avatar ring, and the sign-in stage. It is never used as a general fill.
3. **Type** — **Geist** for all UI, **Instrument Serif** (regular weight only) for editorial display titles and hero figures, **Geist Mono** for timestamps / durations / scores. Transcript reading keeps **Source Serif 4** (runtime toggle). CJK falls back to installed platform faces (`PingFang SC`, `Microsoft YaHei UI`, `Noto Sans CJK SC`, …) so Chinese UI renders natively with no extra downloads.
4. **Icons** — One stroke family: **Phosphor** (MIT), vendored as three icon fonts (`Regular`, `Fill`, `Bold`) under `assets/fonts/phosphor/` and exposed through the semantic `EnjoyIcons` facade of `const IconData` (release builds still tree-shake icon fonts). Outline glyphs at rest, filled glyphs for selected / active states. Material `Icons` are no longer used in `lib/`. The package `phosphor_flutter` is **not** a dependency: its `IconData` subclass does not compile against Flutter ≥ 3.44 (`IconData` is final).
5. **Shape & depth** — Continuous (superellipse) corners everywhere (`RoundedSuperellipseBorder`, `ClipRSuperellipse`); radii `6 / 8 / 12 / 16 / 22 / 30 / pill`. Depth reads as light, not elevation: hairline outlines, soft wide ambient shadows on porcelain, a lit top edge on midnight.
6. **Interaction** — No ink ripples (`NoSplash`). Hover / press are quiet washes; tappables press-scale (`EnjoyPressable`); keyboard focus draws an iris ring. Primary buttons are "lit" (top sheen, inner highlight, tinted shadow) and brighten on hover instead of fading the label.
7. **Motion** — One page transition on every platform except iOS: a short fade-and-glide (`EnjoyGlidePageTransitionsBuilder`; the outgoing page fades too, because shell pages are transparent). iOS keeps `CupertinoPageTransitionsBuilder` for the native edge-swipe. Selection indicators (tab-bar lens, segmented thumb) glide on an emphasized curve. `MediaQuery.disableAnimations` is honoured throughout.
8. **Shell** — Desktop: the sidebar sits directly on the window canvas; routed pages live on a floating continuous-corner **content panel** (inset `8`, radius `14`) lit by the aurora glow. Mobile: a floating frosted **glass capsule** tab bar with a gliding selection lens and outline → fill glyphs. Both replace the M3 pill-indicator navigation idiom.
9. **Components** — Grouped inset lists with colored icon tiles (`EnjoyIconTile`, System-Settings rhythm) for Settings / Profile; sliding-thumb `EnjoySegmentedControl`; poster-style media tiles (artwork *is* the card, hover zoom + glass play glyph, mono duration pill); dark "toast" notices with a semantic glyph; lyric-style transcript focus (context cues dim while a cue is active).

## Consequences

- Every screen inherits the look through `buildAppTheme`, `EnjoyThemeTokens`, and the shared primitives; feature code that still uses raw Material widgets (`FilledButton`, `ListTile`, `AlertDialog`, `Switch`, …) is themed to Aurora automatically. New UI should prefer the primitives (`EnjoyButton`, `EnjoyIconButton`, `EnjoyCard`, `EnjoyPressable`, `EnjoySegmentedControl`, `SettingsRow` + `EnjoyIconTile`, `EditorialHeader` / `EnjoySectionHeader`, `EmptyState` / `EnjoyIconOrb`).
- `EnjoyChromeIcon` keeps its glyph enum (tests and call sites unchanged) but renders `EnjoyIcons`; the `assets/icons/` SVG sprite and the `assets/illustrations/` SVGs were removed (`EmptyState` now draws an icon orb, so `illustrationAsset` is gone).
- Generative media covers keep web parity for *identity* (the seed still picks the same palette / pattern / angle) but render with an opaque, deepened base, a lit corner, and a vignette.
- Instrument Serif ships regular weight only — never pass a bold weight to display styles (the engine would synthesize a faux bold).
- Home's header is a time-of-day greeting under a date overline (`homeGreeting*` strings).
- The integrated (hidden) macOS title bar is **not** part of this decision: it needs per-route traffic-light insets that should be verified on hardware first.
