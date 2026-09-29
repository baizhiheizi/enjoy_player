# App UI — Aurora Design System

**Status**: Implemented (Aurora redesign 2026-09-28, [ADR-0089](../decisions/0089-aurora-design-language.md); supersedes the 2026-05 "cinematic editorial" pass)

## Design direction

**Aurora — quiet chrome, luminous content.** Material is the widget toolkit, not the look: no ink ripples, continuous (superellipse) corners, hairline + ambient-light depth instead of elevation, one icon family, and one motion language on every platform.

**Color** (`AppColors` in `lib/core/theme/colors.dart`, role tokens on `EnjoyThemeTokens`):
- **Neutrals** — cool, with a faint iris cast. **Porcelain** light: page `#F7F7F9`, canvas `#ECECF1`, cards / popovers white. **Midnight** dark: page `#111115`, canvas `#09090B`, cards `#17171C`, popovers `#1E1E24`. Address surfaces by role: `t.canvas`, `cs.surface` (page), `t.card`, `t.popover`, `t.fill` (control fills), `t.hairline`, `t.textFaint`.
- **Iris accent** — fills `#5B4BE8` (light) / `#6D5DFC` (dark), white labels ≥ 4.5:1; inks `#4F3FD6` / `#A99BFF` (`t.accentInk`) for small text. `t.accentSoft` for selected washes.
- **Aurora** — the logo's blue `#4797F5` → violet `#A855F7` (`t.aurora`). Signature moments only: the page glow (`AuroraGlow`), goal ring, Pro badge (`EnjoyTierBadge`), credits meter, profile avatar ring, sign-in stage.
- **Semantic inks** — echo coral (`t.echoActive` / `t.echoInk`), intelligence blue (`t.intelligenceInk`), listening-focus teal (`t.blurActive`), scores (`t.scoreGood` / `scoreWarn` / `scoreBad`).
- **Dynamic accent** — artwork palette (ADR-0007) still tints the play button and the player's ambient backdrop **on top of** these neutrals.

### Typography

- UI (body, labels, buttons, nav): **Geist**.
- Display (page titles, hero figures, empty-state titles): **Instrument Serif**, regular weight only — never embolden. `enjoyDisplayStyle(size:)` for one-off display moments.
- Mono (timestamps, durations, scores): **Geist Mono** with tabular figures — `enjoyMonoStyle()`.
- Transcript body: **Source Serif 4** (default on, toggleable) + Noto Serif CJK; secondary track Noto Sans SC.
- CJK UI falls back to installed platform faces (`kCjkSansFallbacks` / `kCjkSerifFallbacks`) — no extra downloads.
- Scale: `11.5 / 12.5 / 13.5 / 14 / 15 / 15.5 / 17 / 18 / 21 / 30 / 38 / 44 / 56`.

### Icons

One stroke family — **Phosphor** (MIT) vendored as `PhosphorRegular` / `PhosphorFill` / `PhosphorBold` fonts in `assets/fonts/phosphor/`, exposed as semantic `const IconData` on **`EnjoyIcons`** (`lib/core/theme/enjoy_icons.dart`). Outline at rest, `…Fill` for selected / active. Do not use Material `Icons` in `lib/`. `EnjoyChromeIcon(glyph, filled:)` renders the same family for shell / transport glyphs.

### Shape, depth, interaction, motion

- Radii `6 / 8 / 12 / 16 / 22 / 30 / pill` (`radiusXs … radius2xl`), always via `RoundedSuperellipseBorder` / `ClipRSuperellipse` (`enjoyShape()` in `app_theme.dart`).
- Depth: `t.shadowCard` (resting), `t.shadowFloat` (floating chrome), `t.shadowPopover`; dark surfaces get a lit hairline instead of heavy shadow.
- Interaction: `EnjoyPressable` (press-scale, quiet hover / press wash, focus ring, keyboard activation, haptics). `NoSplash` globally.
- Motion: `EnjoyThemeTokens.ease` (soft landing) and `.emphasized` (selection travel); `motionFast 160 / Medium 220 / Standard 280 ms`. Page transition = `EnjoyGlidePageTransitionsBuilder` everywhere except iOS (`CupertinoPageTransitionsBuilder`). `MediaQuery.disableAnimations` respected.

## Theme mode

Porcelain light + midnight dark `ThemeData` (`buildAppTheme(Brightness)`, ADR-0089). `MaterialApp.themeMode` follows persisted `prefs.theme_mode` (`system` | `light` | `dark`, default **system**). Settings → Appearance exposes the three options. See [ADR-0083](../decisions/0083-paper-graphite-light-dark.md) (supersedes [ADR-0011](../decisions/0011-dark-mode-only.md)).

## Navigation

- **Mobile**: `EnjoyBottomNav` — a floating frosted glass capsule (58pt + safe area) with a gliding selection **lens**; glyphs switch outline → filled. **Four** destinations: Home, Discover, Library, **Profile** (Settings is reached from a tile inside Profile). `RootShell` mounts it as `Scaffold.bottomNavigationBar` with `extendBody` over `AppBackground` (page color + aurora glow); the routed body reserves `rootShellBottomNavClearance`.
- **Library source switch**: inside `LibraryScreen`, a compact **Local / Cloud** capsule (`LibrarySourceToggle`) beside the title; tap toggles source. Cloud mode uses `/library?source=cloud`; legacy `/cloud` redirects.
- **Desktop (≥ 900 px)**: `AppSidebar` sits directly on the window **canvas** (no fill, no border); routed pages live on a floating continuous-corner **content panel** (inset `t.shellInset` 8, radius `t.panelRadius` 14, hairline edge, aurora glow). Sidebar rows are `NavItemPill` (34px, lifted plate when selected, filled glyph + iris ink). Search shows its hotkey as an `EnjoyKeycap`. Profile is reached via `SidebarAccountChip` (avatar, name, aurora tier badge; Free users get an aurora **Upgrade** pill).
- Page transitions: one glide everywhere, Cupertino on iOS.

## Page layout

Adaptive page families ([ADR-0055](../decisions/0055-adaptive-page-layout-system.md)):

| Kind | Width | Chrome | Examples |
|------|-------|--------|----------|
| `browse` | Full pane + `pageGutter` (16 / 24) | `EditorialHeader` (gutter-aligned) | Home, Discover, Library, channel feed |
| `hub` | Centered `hubMaxWidth` (840) | Editorial or `EnjoySubpageAppBar` | Profile, Settings, Subscription, Credits, Hotkeys, AI providers, Vocabulary |
| `form` | Centered `formMaxWidth` (680) | `EnjoySubpageAppBar` | Preferences, Edit Profile |
| `auth` | Centered `modalMaxWidth` (400) | Auth scaffold | Sign-in |
| `playerChrome` | Player-owned | Player chrome | Expanded player |

Use `EnjoyPage` + `EnjoyPageMetrics` (or `pageGutterOf`) — never invent per-screen max widths or stretch form Save buttons to the full desktop pane.

## System chrome

- **Mobile**: `MaterialApp.router` builder wraps content in `AnnotatedRegion<SystemUiOverlayStyle>` — transparent status bar with brightness-matched icons; system navigation bar follows porcelain / midnight.
- **Desktop**: native title bars (an integrated macOS title bar is a future option — see ADR-0089 consequences). `window_manager.setMinimumSize(880×560)`.

## Screen registry

| Screen | Aurora treatment |
|--------|-----------|
| `SignInScreen` | Aurora-lit stage (`AuroraGlow` ×2.2), logo in a glowing glass tile, Instrument Serif title, large provider buttons, hairline "or" divider |
| `HomeScreen` | Greeting title (`homeGreeting*`) under a date overline; Craft / Import as small buttons (icon-only on phones); Today's Goal (aurora ring + serif figure) and Community (serif figures, live dot) as two cards; recents grid of poster tiles (two columns on phones) under `EnjoySectionHeader` |
| `LibraryScreen` | Serif title + Local/Cloud capsule; `EnjoySegmentedControl` for Video / Audio; poster grid / list rows |
| `DiscoverScreen` | Serif title; channel strip with story-ring avatars and an inverted "All" pill; feed tiles share the poster artwork treatment |
| `ExpandedPlayerScreen` | `PlayerAmbientBackdrop` artwork tint; glass transport capsule (lit play button, mono times, filled glyphs for active tools); transcript with lyric-style focus (context cues dim while a cue is active) |
| `TranscriptPanel` | Source Serif 4 body, Geist Mono timestamps, continuous-corner active plate with iris rail, iris translation rule |
| `ProfileScreen` | Hero card (aurora-ringed avatar, serif name, mono ID, aurora wash), one stat card with three serif figures, credits meter, grouped rows |
| `SettingsScreen` | Serif title + description; grouped inset lists with colored `EnjoyIconTile`s; single-column groups get overline headings; two-pane rail uses `NavItemPill` |
| `VocabularyScreen` | Segmented tab bar (shared track / thumb decoration); stat sheet with serif figures; stacked rating tiles in review |
| `NotFoundScreen` | Router `errorBuilder` fallback; localized; single primary "Back to Home" |

## Design token reference (`EnjoyThemeTokens`)

```
Spacing:   4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48
Radii:     6 / 8 / 12 / 16 / 22 / 30 / pill   (radiusXs … radius2xl, superellipse)
Controls:  32 / 40 / 48                        (controlHeightSm / controlHeight / controlHeightLg)
Surfaces:  canvas / card / popover / fill / hairline / textFaint / topHighlight
Aurora:    auroraStart #4797F5 → auroraEnd #A855F7 (t.aurora gradient)
Shadows:   shadowCard / shadowFloat / shadowPopover
Motion:    160 fast / 220 medium / 280 standard / 260 enter / 160 exit; ease + emphasized curves
Shell:     sidebar 236 · brand row 52 · shellInset 8 · panelRadius 14 · bottom nav 64 (58 capsule)
Widths:    content 720 · form 680 · hub 840 · modal 400 / 560
Gutters:   pageGutter 24 · pageGutterCompact 16 (< 600)
Breakpoints: compact 600 · rail 900 · transcript side-by-side 720
Focus ring: 2px iris ink
```

## Widgets reference

| Widget | File | Purpose |
|--------|------|---------|
| `EnjoyIcons` | `core/theme/enjoy_icons.dart` | Semantic Phosphor glyphs (`const IconData`) |
| `EnjoyChromeIcon` | `core/theme/widgets/enjoy_chrome_icon.dart` | Shell / transport glyph enum → `EnjoyIcons` (`filled:` for active) |
| `EnjoyPressable` | `core/interaction/enjoy_pressable.dart` | Press-scale + hover wash + focus ring + keyboard activation + haptics (no ripple) |
| `EnjoyTappableSurface` / `EnjoyTappableIcon` | `core/interaction/enjoy_tappable.dart` | Legacy API over `EnjoyPressable` / `IconButton` |
| `EnjoyButton` (`primary` / `secondary` / `tonal` / `ghost` / `destructive`, `small` / `medium` / `large`, `expand`) | `core/theme/widgets/enjoy_button.dart` | Action buttons; primary is "lit" (`enjoyLitFillBuilder`) |
| `EnjoyIconButton` | same | Square icon-only action in the same variants |
| `EnjoyCard` / `enjoyCardDecoration` | `core/theme/widgets/enjoy_card.dart` | Hairline card with ambient depth |
| `EnjoyAvatar` / `EnjoyTierBadge` / `EnjoyKeycap` | `core/theme/widgets/enjoy_avatar.dart` | Gradient-initial avatar, aurora tier pill, shortcut keycap |
| `EnjoyIconTile` / `EnjoyTint` / `enjoyTintForIcon` | `core/theme/widgets/enjoy_icon_tile.dart` | Colored icon tiles for grouped lists |
| `EnjoySegmentedControl` / `EnjoySegment` | `core/theme/widgets/enjoy_segmented_control.dart` | Sliding-thumb segmented control (+ `enjoySegmentTrackColor` / `enjoySegmentThumbDecoration` for segmented `TabBar`s) |
| `AppBackground` / `AuroraGlow` / `PlayerAmbientBackdrop` | `core/theme/widgets/app_background.dart` | Page color + aurora glow; player artwork tint |
| `EnjoyPage` / `EnjoyPageKind` | `core/theme/widgets/enjoy_page.dart`, `core/layout/enjoy_page_kind.dart` | Adaptive page scaffold + width metrics |
| `EnjoySubpageAppBar` / `EnjoyBackButton` | `core/theme/widgets/enjoy_subpage_app_bar.dart` | Push-route chrome |
| `EditorialHeader` / `EnjoyOverline` / `EnjoySectionHeader` | `core/theme/widgets/editorial_header.dart` | Serif page title (+ `overline`, `subtitle`), eyebrow label, in-page section heading |
| `EmptyState` / `EnjoyIconOrb` | `core/theme/widgets/empty_state.dart` | Icon orb + serif title + actions |
| `EnjoyBottomNav` | `core/theme/widgets/enjoy_bottom_nav.dart` | Glass capsule tab bar with gliding lens |
| `NavItemPill` | `core/theme/widgets/nav_item_pill.dart` | Sidebar / settings-rail row (ADR-0018) |
| `showEnjoySheet` / `showEnjoyAdaptiveSheet` / `showEnjoyAlertDialog` / `showEnjoyDialog` | `core/theme/widgets/enjoy_modal.dart` | Popover-surface sheets / dialogs, shared scrim + `enjoyDialogAnimationStyle` |
| `SheetDragHandle` / `PaddedSheetDragHandle` | `core/theme/widgets/sheet_drag_handle.dart` | 36×5 grabber |
| `MediaCardTile` / `MediaCardRow` | `core/theme/widgets/media_card.dart` (→ `media_card/`) | Poster tile (artwork is the card) with optional discover affordances (adding scrim, in-library chip, custom `meta` slot) / list row |
| `GlassSurface` | `core/theme/widgets/glass_surface.dart` | Frosted floating chrome (transport) |
| `SettingsRow` / `SettingsRowDivider` / `SettingsValuePill` | `features/settings/presentation/widgets/settings_row.dart` | Grouped-list row with icon tile, value, chevron |
| `AppNotice` | `core/notices/app_notice.dart` | Dark toast with semantic glyph |
| `Skeleton` (+ helpers) | `core/theme/widgets/skeleton.dart` | Shimmer placeholders; see [skeleton-loading.md](skeleton-loading.md) |
| `LoadingIcon` / `SectionLabel` | `core/presentation/` | Inline spinner; in-card section label |
| `AppSidebar` / `SidebarAccountChip` | `features/player/presentation/widgets/app_sidebar.dart`, `features/auth/presentation/widgets/sidebar_account_chip.dart` | Desktop navigation on the canvas |

## Dynamic color module

`lib/core/theme/dynamic_color/`
- `artwork_palette.dart` — `extractArtworkPalette(path)` extracts an `ArtworkPalette { dominant, accent, onAccent, vibrant }` from a local thumbnail via `palette_generator`. Results are held in a process-wide **LRU cache** (cap = 32) keyed by `(path, size, mtime)`; lookups re-`stat` the file and evict any prior entry for the same path whose `(size, mtime)` no longer matches the live stat, so re-thumbnailing or rewriting the file in place correctly invalidates the cache. `ArtworkPalette` has value-equality on its four `Color` fields. `@visibleForTesting` seams (`debugResetArtworkPaletteCache`, `debugArtworkPaletteCacheSize`, `debugArtworkPaletteCacheContainsPath`, `debugLookupArtworkPalette`, `debugPutArtworkPalette`) are the only supported access path for tests.
- `dynamic_color_provider.dart` — Riverpod providers: `currentArtworkPaletteProvider` (active player, watches `playerControllerProvider`'s `thumbnailUrl`), `artworkPaletteProvider(path)` (per-path family).

See ADR-0007 for rationale.

## ADRs

- [ADR-0089](../decisions/0089-aurora-design-language.md) — Aurora design language

- [ADR-0007](../decisions/0007-dynamic-color-from-artwork.md) — Dynamic color from artwork
- [ADR-0008](../decisions/0008-light-mode-parity.md) — Light mode parity (superseded by 0011)
- [ADR-0009](../decisions/0009-platform-adaptive-shell.md) — Platform-adaptive shell
- [ADR-0011](../decisions/0011-dark-mode-only.md) — Dark mode only (superseded by 0083)
- [ADR-0083](../decisions/0083-paper-graphite-light-dark.md) — Paper / graphite light+dark + System/Light/Dark appearance
- [ADR-0055](../decisions/0055-adaptive-page-layout-system.md) — Adaptive page layout system
