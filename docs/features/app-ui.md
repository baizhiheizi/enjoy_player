# App UI — Aurora Design System

**Status**: Implemented (Aurora redesign 2026-09-28, [ADR-0089](../decisions/0089-aurora-design-language.md); supersedes the 2026-05 "cinematic editorial" pass)

> **Being replaced by Duet** ([ADR-0091](../decisions/0091-duet-design-language.md)) on the `design-duet` branch. This page describes the code as it is. Each section is rewritten as its phase lands ([PLAN.md → Documentation map](../design/duet/PLAN.md#documentation-map)). Build new UI to [`docs/design/duet/`](../design/duet/README.md), not to the Aurora descriptions below.

## Design direction

**Aurora — quiet chrome, luminous content.** Material is the widget toolkit, not the look: no ink ripples, continuous (superellipse) corners, hairline + ambient-light depth instead of elevation, one icon family, and one motion language on every platform.

**Color** (`AppColors` in `lib/core/theme/colors.dart`, role tokens on `EnjoyThemeTokens`; Duet values per [ADR-0091](../decisions/0091-duet-design-language.md) — Aurora-named fields alias them until the rename pass, values from [`tokens.json`](../../design/duet/tokens.json)):
- **Flat neutrals** — one **ground** for sidebar and pages (light `#F5F6F8`, dark `#0E1014`), `paper` cards, `raised` menus / dialogs, `sunk` control fills, `line` separators; text inks `ink` / `ink2` / `ink3`. No floating content panel, no glass surfaces.
- **Two voices** — **original** blue (`original` / `originalInk` / `originalSoft`) is the original speaker: playback, the spoken word, reference pitch, Listen. **You** violet (`you` / `youInk` / `youSoft` / `youLine` / `onYou`) is the learner: the Echo loop, Record, takes, your pitch, notes. The voices keep a ~1.9:1 lightness gap in both themes and never rely on hue alone (translucent layer vs solid).
- **Brand** — the gradient between the voices: `brand` `#2563EB → #7C3AED` (`t.brand`) for Play, primary buttons, Pro, Upgrade; `logo` `#4797F5 → #A855F7` (`t.logo`) for the mark, goal ring, credits meter, avatar ring, generated covers. `brandInk` / `brandSoft` carry selected rows and tabs.
- **Material `ColorScheme`** (`AppColors.colorScheme`) maps onto Duet: `primary`/`onPrimary` = `brandInk` / white (dark `ground`), `primaryContainer` = `brandSoft`, `secondary` = `original`, `tertiary`/`onTertiary` = `you`/`onYou`, `error` = `danger`, `surface` = `ground`, `surfaceContainer*` = `paper`/`raised`/`sunk`, `onSurface`/`onSurfaceVariant` = `ink`/`ink2`, `outline`/`outlineVariant` = `ink3`/`line`, `scrim` = the `scrim` token. Filled action buttons never take `ColorScheme.primary` — `EnjoyButton` owns its fills.
- **Component accents** — switches, radios, checkboxes, and input focus borders use `brandInk`; sliders, text selection, and the sentence ruler use `original`. Dialogs sit on `raised` at radius 24 with the `scrim` token; sheets use radius 26; menus use `raised` + the float shadow; tooltips are ink-on-ground. `AppNotice` stays a dark toast in `ink`.
- **Semantic inks** — `danger` for destructive actions and errors. Scores are **uncolored**: an ink number plus a four-step meter.

### Typography

- UI (body, labels, buttons, nav): **Geist** 400 / 500 / 600.
- Display (page titles, hero figures, empty-state titles): **Literata** 500. `enjoyDisplayStyle(size:)` for one-off display moments (defaults to weight 500).
- Mono (timestamps, durations, scores, keycaps): **Geist Mono** 500 / 600 with tabular figures — `enjoyMonoStyle()`.
- Transcript body: **Literata** 400 / 500 (default on, toggleable) + Noto Serif CJK; secondary track and IPA: Noto Sans 400.
- CJK UI falls back to installed platform faces (`kCjkSansFallbacks` / `kCjkSerifFallbacks`) — no extra downloads.
- Scale (tokens.json → typography.scale): body 14.5 / 1.55, button 14 / 600, nav 14 / 500, caption 12.5, overline 11 / 600 caps 0.08em, time 12.5 mono / 500, score 13 mono / 600, keycap 10.5 mono / 500.

**Font delivery** (issue #810, #818): every variant the app requests — Geist 400/500/600, Geist Mono 500/600, Literata 400/500/600, Playfair Display 700 + 600-italic (share poster, retired with D3.12), Noto Sans 400 — ships in `assets/fonts/google_fonts/` in the google_fonts asset layout (filenames use the package's camelCase family ids, e.g. `GeistMono-Medium.ttf`), so the first theme build loads them from the bundle instead of fetching fonts.gstatic.com: no first-run FOUT / full-app relayout, correct fonts offline. `OFL-*.txt` files carry each family's license.

`GoogleFonts.config.allowRuntimeFetching = false` is set in `lib/main.dart`, so no font can ever trigger a runtime download. This is possible because **CJK is addressed by name, never through `google_fonts`**: the ~40 MB Noto SC/Kr/Jp variants are neither bundled nor loaded, and instead appear in `fontFamilyFallback` as the plain family ids `kCjkNotoSansFallbacks` / `kCjkNotoSerifFallbacks` (`NotoSansKR`, `NotoSansSC`, `NotoSansJP`, `NotoSerifKR`, `NotoSerifSC`, `NotoSerifJP`) plus the assembled `_kTranscriptCjkSansFallbacks` / `_kTranscriptCjkSerifFallbacks`. A `fontFamilyFallback` entry is resolved by the platform font matcher, so an absent family is skipped at no cost and the installed-platform lists `kCjkSansFallbacks` / `kCjkSerifFallbacks` take over. Do **not** reintroduce `GoogleFonts.notoSerifSc().fontFamily`-style lookups to "get" a family name — building the `TextStyle` to read `.fontFamily` is what forced the multi-megabyte fetch and a font registration on the text build path, once per transcript line. **Every** entry in those two lists must be a literal, including `'Geist'`, for the same reason. When adding a weight or family to `typography.dart`, bundle the matching file and extend `test/core/theme/bundled_google_fonts_test.dart`.

### Icons

One stroke family — **Phosphor** (MIT) vendored as `PhosphorRegular` / `PhosphorFill` / `PhosphorBold` fonts in `assets/fonts/phosphor/`, exposed as semantic `const IconData` on **`EnjoyIcons`** (`lib/core/theme/enjoy_icons.dart`). Outline at rest, `…Fill` for selected / active. Do not use Material `Icons` in `lib/`. `EnjoyChromeIcon(glyph, filled:)` renders the same family for shell / transport glyphs.

### Shape, depth, interaction, motion

- Radii `6 / 8 / 12 / 16 / 22 / 30 / pill` (`radiusXs … radius2xl`), always via `RoundedSuperellipseBorder` / `ClipRSuperellipse` (`enjoyShape()` in `app_theme.dart`).
- Depth: `t.shadowCard` (resting), `t.shadowFloat` (floating chrome), `t.shadowPopover`; dark surfaces get a lit hairline instead of heavy shadow.
- Interaction: `EnjoyPressable` (press-scale, quiet hover / press wash, focus ring, keyboard activation, haptics). `NoSplash` globally.
- Motion: `EnjoyThemeTokens.ease` (soft landing) and `.emphasized` (selection travel); `motionFast 160 / Medium 220 / Standard 280 ms`. Page transition = `EnjoyGlidePageTransitionsBuilder` everywhere except iOS (`CupertinoPageTransitionsBuilder`). `MediaQuery.disableAnimations` respected.

**Enforcement (issue #793).** The shape / depth / interaction / type / icon rules above are pinned by `test/core/theme/aurora_design_language_test.dart`, which walks `lib/` and fails on a re-introduced `InkWell(` (a Material ink ripple), a Material `Icons.` reference, a raw `fontFamily: 'monospace'` (bypasses Geist Mono — use `enjoyMonoStyle()`), or a literal `Color(0x…)` outside `lib/core/theme/`. `lib/core/theme/` is exempt from the color rule because the palette itself lives there, and `appNoticeBackground()` stays a standalone `Brightness`-keyed function because ADR-0089 §9 sanctions the dark toast as its own surface. The `enjoySegmentedButtonStyle()` shim in `enjoy_segmented_control.dart` exists only to keep legacy `SegmentedButton` call sites on-theme; once its last caller (Craft) has merged, delete it and use `EnjoySegmentedControl` directly.

## Theme mode

Duet light + dark `ThemeData` (`buildAppTheme(Brightness)`, ADR-0091); `duet_tokens_test.dart` pins each theme's values to `tokens.json`. `MaterialApp.themeMode` follows persisted `prefs.theme_mode` (`system` | `light` | `dark`, default **system**). Settings → Appearance exposes the three options. See [ADR-0083](../decisions/0083-paper-graphite-light-dark.md) (supersedes [ADR-0011](../decisions/0011-dark-mode-only.md)).

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

Duet tokens ([ADR-0091](../decisions/0091-duet-design-language.md)) come from [`docs/design/duet/tokens.json`](../../design/duet/tokens.json); `test/core/theme/duet_tokens_test.dart` pins every color, radius, size, breakpoint, motion, opacity, and stroke value to that file in light and dark. Aurora-named fields (`canvas`, `card`, `popover`, `fill`, `hairline`, `textFaint`, …) alias the Duet values until the rename pass.

```
Surfaces:   ground / paper / raised / sunk / line         (sidebar+pages / cards / menus / control fill / separators)
Inks:       ink / ink2 / ink3 · primary + onPrimary (ink fill) · danger · shape · tick · scrim · video
Voices:     original · originalInk · originalSoft          (blue — playback, spoken word, reference pitch, Listen)
            you · youInk · youSoft · youLine · onYou       (violet — Echo loop, Record, takes, your pitch)
            brandInk · brandSoft                           (readable brand-gradient end)
Gradients:  brand #2563EB → #7C3AED (buttons, Pro) · logo #4797F5 → #A855F7 (mark, rings, covers) — `t.brand` / `t.logo`
Vocabulary: vocabNew / vocabLearning / vocabReviewing / vocabMastered
Spacing:    4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48
Radii:      keycap 5 · badge 7 · segment thumb 9 · control / segment track / input 12 · tile 14
            card 20 · cardLarge / dialog 24 · sheet 26 · pill (legacy radiusXs 6 … radius2xl 30)
Controls:   32 / 40 / 50                        (controlHeightSm / controlHeight / controlHeightLg)
Sizes:      touch 44 · icon button 40 (44 phone) · segment 38 · chip 34 · take chip 42
            play 60 (68 phone) · record 62 (76 phone) · Original pill 150 × 52 (56 phone)
Shell:      sidebar 244 · brand row 52 · tab bar 84 + 26 safe inset · player top bar 60 · subpage header 64
Player:     ruler hit 34 · margin 380 · Listen column 780 · Echo column 880 · video column min(520 px, 46 %)
Pages:      browse 1180 · craft 1080 · hub 840 · form 680 · gutter 40 (16 phone)
Breakpoints: compact 600 · rail 900 · margin drawer 1100 · transcript side-by-side 720
Motion:     160 fast / 220 margin / 280 lens · echo lens opacity 1 / .65 / .35 / .2 · reference pitch band .35
Strokes:    reference pitch 9 · your pitch 3 · loop bracket 2 · ruler track 4 · focus ring 2
Shadows:    lift (cards) · float (chrome, popovers) · brandButton · recordButton
Legacy:     `auroraStart`/`auroraEnd`/`aurora` = logo stops · `shadowCard`=lift · `shadowFloat`=`shadowPopover`=float
```

## Widgets reference

| Widget | File | Purpose |
|--------|------|---------|
| `EnjoyIcons` | `core/theme/enjoy_icons.dart` | Semantic Phosphor glyphs (`const IconData`) |
| `EnjoyChromeIcon` | `core/theme/widgets/enjoy_chrome_icon.dart` | Shell / transport glyph enum → `EnjoyIcons` (`filled:` for active) |
| `EnjoyPressable` | `core/interaction/enjoy_pressable.dart` | Press-scale + hover wash + focus ring + keyboard activation + haptics (no ripple); wash/ring default to a superellipse from `borderRadius`, `shape` overrides it (e.g. `CircleBorder` for circular chrome) |
| `EnjoyTappableSurface` / `EnjoyTappableIcon` | `core/interaction/enjoy_tappable.dart` | Legacy API over `EnjoyPressable` / `IconButton` |
| `EnjoyButton` (`brand` / `primary` / `secondary` / `ghost` / `destructive`, `small` / `medium` / `large`, `expand`) | `core/theme/widgets/enjoy_button.dart` | Action buttons at 32 / 40 / 50, radius 12, Geist 600 14: `brand` is the gradient with a white label and the brand-button shadow (one per screen), `primary` is the ink fill, `secondary` paper + line (legacy `tonal` aliases it), `ghost` ink2 text, `destructive` solid danger with a white label |
| `EnjoyIconButton` | same | Square icon-only action in the same variants; 40 on desktop, 44 on phone |
| `EnjoyCard` / `enjoyCardDecoration` | `core/theme/widgets/enjoy_card.dart` | Hairline card with ambient depth |
| `EnjoyAvatar` / `EnjoyTierBadge` / `EnjoyKeycap` | `core/theme/widgets/enjoy_avatar.dart` | Gradient-initial avatar with an optional logo-gradient ring, brand-gradient tier pill (`leading` icon, `padding` scale, `shape`, solid `color` override — also the sidebar Upgrade pill and the tier-catalog badges), paper keycap with a line border and 1px drop |
| `EnjoyProgressRingPainter` | `core/theme/widgets/enjoy_progress_ring.dart` | Track circle + progress arc (solid color or aurora sweep gradient) — Today's Goal ring, record FAB countdown |
| `EnjoyIconTile` / `EnjoyTint` / `enjoyTintForIcon` | `core/theme/widgets/enjoy_icon_tile.dart` | Colored icon tiles for grouped lists |
| `EnjoySegmentedControl` / `EnjoySegment` | `core/theme/widgets/enjoy_segmented_control.dart` | Sliding-thumb segmented control — 38 sunk track (radius 12) with a raised thumb (radius 9, lift shadow); 30 compact (+ shared track/thumb helpers for segmented `TabBar`s) |
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
| `GlassSurface` | `core/theme/widgets/glass_surface.dart` | Frosted floating chrome (transport capsule, circular player collapse control); optional `shape` override for non-rectangular outlines |
| `SettingsRow` / `SettingsRowDivider` / `SettingsValuePill` | `features/settings/presentation/widgets/settings_row.dart` | Grouped-list row with icon tile, value, chevron |
| `AppNotice` | `core/notices/app_notice.dart` | Dark toast with semantic glyph |
| `Skeleton` (+ helpers) | `core/theme/widgets/skeleton.dart` | Shimmer placeholders; see [skeleton-loading.md](skeleton-loading.md) |
| `LoadingIcon` / `SectionLabel` | `core/presentation/` | Inline spinner; in-card section label |
| `AppSidebar` / `SidebarAccountChip` | `features/player/presentation/widgets/app_sidebar.dart`, `features/auth/presentation/widgets/sidebar_account_chip.dart` | Desktop navigation on the canvas |

## Dynamic color module

`lib/core/theme/dynamic_color/`
- `artwork_palette.dart` — `extractArtworkPalette(path)` extracts an `ArtworkPalette { dominant, accent, onAccent, vibrant }` from a local thumbnail via `palette_generator`. The provider it samples from (`artworkPaletteImageProvider`) is a `ResizeImage(FileImage, width: 200)` — `FileImage` ignores the generator's `ImageConfiguration.size`, and without the wrapper the full-resolution thumbnail would be decoded and quantized on the UI isolate on every first-open of a media item (issue #827 A1). Results are held in a process-wide **LRU cache** (cap = 32) keyed by `(path, size, mtime)`; lookups re-`stat` the file and evict any prior entry for the same path whose `(size, mtime)` no longer matches the live stat, so re-thumbnailing or rewriting the file in place correctly invalidates the cache. `ArtworkPalette` has value-equality on its four `Color` fields. `@visibleForTesting` seams (`artworkPaletteImageProvider`, `debugResetArtworkPaletteCache`, `debugArtworkPaletteCacheSize`, `debugArtworkPaletteCacheContainsPath`, `debugLookupArtworkPalette`, `debugPutArtworkPalette`) are the only supported access path for tests.
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
