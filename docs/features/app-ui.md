# App UI — Cinematic Editorial Design System

**Status**: Implemented (Phase 1-6 complete, 2026-05-09; premium foundation pass 2026-05-13)

## Design direction

**Style**: Cinematic Editorial — confident hero typography, generous whitespace, ambient artwork-derived color, selective glass only on the floating transport bar.

**Color**:
- **Neutrals** — zinc-style dark ramp only: base `#09090B`, containers through `#3F3F46` (see `AppColors` in `lib/core/theme/colors.dart`).
- **Brand** — premium purple `#7B61FF` (primary) elevating the logo gradient, with logo blue `#4797F5` (secondary) (Material `ColorScheme` roles).
- **Dynamic accent** — extracted per-media via `palette_generator`; applied to now-playing ring glow, transcript active-line rail, and ambient backdrop tint.
- **Echo accent** — `#E65100` orange kept for brand recognition, only on echo-mode affordances.

**Typography**:
- Display / UI: **Inter** (Google Fonts), `w600` tight-tracked for hero titles.
- Transcript body: **Source Serif 4** (Google Fonts), default ON, toggleable.
- Tabular figures everywhere on timestamps and durations via `FontFeature.tabularFigures()`.
- Type scale: `12 / 13 / 14 / 16 / 18 / 22 / 28 / 36 / 48`.

**Effects**:
- Glass: **transport bar only** (`GlassSurface`). Sidebar is flat tonal; content cards are flat.
- Elevation scale: `0 / 1 / 3 / 8` (cards / sheets / modals).
- Radius scale: `8 / 12 / 16 / 20 / ∞`. `20` is the new default for cards and hero artwork.
- Ambient backdrop: very-low-opacity (~7%) radial tint from artwork dominant color behind player content.
- Motion: 180ms fast, **220ms medium** (transport layout morphs), 260ms standard, 240ms enter, 160ms exit. `prefers-reduced-motion` respected via `MediaQuery.disableAnimations`.
- Global theme polish: tuned `splashColor` / `highlightColor` / `hoverColor` / `focusColor`, `scrollbarTheme`, `dialogTheme.insetPadding`, `NavigationBarTheme` height aligned to token (for any residual Material nav).
- Shared interaction kit: `EnjoyTappable*`, `Haptics`, `EnjoyButton` — see [ADR-0018](../decisions/0018-shared-interactive-primitives.md).

## Theme mode

Single dark `ThemeData` only (`buildAppTheme()`). No light theme and no Settings theme toggle. See [ADR-0011](../decisions/0011-dark-mode-only.md).

## Navigation

- **Mobile**: custom `EnjoyBottomNav` (68pt content height + system home-indicator inset via `SafeArea`). **Four** destinations: Home, Discover, Library, Settings. Pill selection, editorial typography, keyboard focus ring on items; haptics on change. Implemented in `lib/core/theme/widgets/enjoy_bottom_nav.dart`, used from `RootShell`.
- **Library source switch**: Inside `LibraryScreen`, a compact **Local / Cloud** badge with swap icon sits inline beside the Library title; tap toggles source. Cloud mode uses `/library?source=cloud`; legacy `/cloud` redirects. Import + compact search on Local; Refresh on Cloud.
- **Desktop (≥ 900 px)**: `AppSidebar` — flat tonal panel (`surfaceContainerLow`), hairline right border, pill nav items with hover/splash/focus, `FocusTraversalGroup` for keyboard order; extra top breathing room on **macOS** desktop for traffic-light clearance. Library nav item covers both local and cloud sources (no separate Cloud row).
- **No glass on sidebar**: `EnjoyThemeTokens.useGlassOnSidebar = false`.
- Platform-adaptive transitions: Cupertino on iOS/macOS, ZoomPage on Android, FadeUpwards on Windows/Linux.

## System chrome

- **Mobile**: `MaterialApp.router` builder wraps content in `AnnotatedRegion<SystemUiOverlayStyle>` — transparent status bar, light status/nav icons, dark system navigation bar (`#09090B`).
- **Desktop**: `window_manager.setMinimumSize(880×560)` after init (Windows / macOS / Linux) for a usable minimum layout.

## Screen registry

| Screen | Key change |
|--------|-----------|
| `SignInScreen` | Editorial centered hero; no glass card |
| `HomeScreen` | `EditorialHeader` + media grid via `MediaCardTile` |
| `LibraryScreen` | `EditorialHeader` + `SegmentedButton` + `MediaCardRow` / `MediaCardTile` |
| `ExpandedPlayerScreen` | `PlayerAmbientBackdrop` + transparent app bar (hidden while playing, returns on pause) |
| `AudioPlayerLayout` | `HeroArtwork` with dynamic rim light, "Now reading" editorial label |
| `VideoPlayerLayout` | Side-by-side video + transcript when width **>** `breakpointTranscriptSideBySide` (720) (any orientation). Below: stacked 16:9 video over transcript. Split: draggable transcript column (**≥360** px min, max 50% width), persisted `splitPx` preference, dark zinc panel, 1px left border; top **SafeArea** on video when expanded chrome hides the app bar |
| `GlobalTransportBar` | Glass kept; dynamic-accent play ring; tabular timestamps; narrow ≤720px: prev/next always when transcript loaded (replay via line tap) |
| `TranscriptPanel` | Source Serif 4 body; editorial left-rail active line; neutral echo card with 8px orange rail |
| `ShadowReadingPanel` | Idle: three-zone bar (pitch icon, centered 56pt FAB, play + more; delete in menu); recording: centered FAB + countdown |
| `SettingsScreen` | iOS-style grouped `_SettingsCard`; **Appearance & Language** rows open pickers for display + native language (learning fixed en-US); guest vs signed-in copy for language sync |
| `NotFoundScreen` | `errorBuilder` fallback at the router root for unknown `go_router` locations; localized en / zh / zh-CN, shows the attempted URI, single primary "Back to Home" action to `/` |

## Design token reference (`EnjoyThemeTokens`)

```
Spacing:  4 / 8 / 12 / 16 / 20 / 24 / 32 / 40
Radii:    8 / 12 / 16 / 20 / 999
Elevation: 0 / 1 / 3 / 8
Motion:   180ms fast / 260ms standard / 240ms enter / 160ms exit
Sidebar:  248px wide, useGlassOnSidebar: false
Transport: 88px height
ContentMaxWidth: 720px
BottomNav: 68px content height (+ safe area)
DesktopGutter: 24px (wide layout rhythm)
Modal max: 400px (alerts) / 560px (wide pickers)
Focus ring: 2px (custom nav / sidebars)
```

## Widgets reference

| Widget | File | Purpose |
|--------|------|---------|
| `AppBackground` | `core/theme/widgets/app_background.dart` | Dark gradient scaffold BG |
| `PlayerAmbientBackdrop` | same | Artwork color tint overlay (player only) |
| `EditorialHeader` | `core/theme/widgets/editorial_header.dart` | Large title + subtitle + trailing; wide screens center within `contentMaxWidth`; optional `compact` |
| `EnjoyBottomNav` | `core/theme/widgets/enjoy_bottom_nav.dart` | Mobile shell bottom navigation (replaces stock `NavigationBar`) |
| `showEnjoySheet` / `showEnjoyAlertDialog` / `showEnjoyDialog` | `core/theme/widgets/enjoy_modal.dart` | Shared modal scrim + sheet shape; alert content max width |
| `MediaCardTile` | `core/theme/widgets/media_card.dart` | Grid tile (video/home) |
| `MediaCardRow` | `core/theme/widgets/media_card.dart` | List row (audio) |
| `HeroArtwork` | `core/theme/widgets/hero_artwork.dart` | Artwork + rim light + shadow |
| `EmptyState` | `core/theme/widgets/empty_state.dart` | Editorial empty state |
| `GlassSurface` | `core/theme/widgets/glass_surface.dart` | **Transport bar only** |
| `AppSidebar` | `features/player/presentation/widgets/app_sidebar.dart` | Flat tonal sidebar |

## Dynamic color module

`lib/core/theme/dynamic_color/`
- `artwork_palette.dart` — LRU-cached extraction via `palette_generator`
- `dynamic_color_provider.dart` — Riverpod providers: `currentArtworkPaletteProvider`, `artworkPaletteProvider(path)`

See ADR-0007 for rationale.

## ADRs

- [ADR-0007](../decisions/0007-dynamic-color-from-artwork.md) — Dynamic color from artwork
- [ADR-0008](../decisions/0008-light-mode-parity.md) — Light mode parity (superseded by 0011)
- [ADR-0009](../decisions/0009-platform-adaptive-shell.md) — Platform-adaptive shell
- [ADR-0011](../decisions/0011-dark-mode-only.md) — Dark mode only + logo-aligned brand
