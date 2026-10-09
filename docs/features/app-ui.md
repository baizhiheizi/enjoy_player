# App UI — Duet Design System

**Status**: Implemented ([ADR-0093](../decisions/0093-duet-design-language.md); replaces Aurora [ADR-0089](../decisions/0089-aurora-design-language.md), which was never released).

## Design direction

**Duet — two voices, flat ground.** Material is the widget toolkit, not the look: no ink ripples, continuous (superellipse) corners, flat surfaces with line borders and the lift shadow instead of elevation, one icon family, and one motion language on every platform. **Blue (original)** is the original speaker — playback, the spoken word, reference pitch, Listen; **violet (you)** is the learner — the Echo loop, Record, takes, your pitch. The brand gradient between them is Enjoy itself (logo, Play, primary buttons, goal ring, Pro). Everything else is ink. Modes are lenses: Listen reads like a book; Echo grows the loop in place and fades the rest. Feedback lands on the words (karaoke underline, hide-text shapes, practiced dots), never in chrome.

**Color** (`AppColors` in `lib/core/theme/colors.dart`, role tokens on `EnjoyThemeTokens`; Duet values per [ADR-0093](../decisions/0093-duet-design-language.md) — Aurora-named fields alias them until the rename pass, values from [`tokens.json`](../design/duet/tokens.json)):
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

**Enforcement (issue #793).** The shape / depth / interaction / type / icon rules above are pinned by `test/core/theme/duet_design_language_test.dart`, which walks `lib/` and fails on a re-introduced `InkWell(` (a Material ink ripple), a Material `Icons.` reference, a raw `fontFamily: 'monospace'` (bypasses Geist Mono — use `enjoyMonoStyle()`), or a literal `Color(0x…)` outside `lib/core/theme/`. `lib/core/theme/` is exempt from the color rule because the palette itself lives there, and `appNoticeBackground()` stays a standalone `Brightness`-keyed function — the test keeps `app_notice.dart` exempt under its historical ADR-0089 §9 dark-toast rationale. The `enjoySegmentedButtonStyle()` shim in `enjoy_segmented_control.dart` exists only to keep legacy `SegmentedButton` call sites on-theme; once its last caller (Craft) has merged, delete it and use `EnjoySegmentedControl` directly.

## Theme mode

Duet light + dark `ThemeData` (`buildAppTheme(Brightness)`, ADR-0093); `duet_tokens_test.dart` pins each theme's values to `tokens.json`. `MaterialApp.themeMode` follows persisted `prefs.theme_mode` (`system` | `light` | `dark`, default **system**). Settings → Appearance exposes the three options. See [ADR-0083](../decisions/0083-paper-graphite-light-dark.md) (supersedes [ADR-0011](../decisions/0011-dark-mode-only.md)).

## Navigation

- **Mobile**: `EnjoyBottomNav` — a solid full-width paper bar (58pt content + the real bottom safe inset; 84pt on home-indicator devices) with a top `line`. The selected tab gets a 52×30 `brandSoft` pill, a filled glyph in `brandInk`, and a 600 label. **Four** destinations: Home, Discover, Library, **Profile** (Settings is reached from a tile inside Profile); the update badge stays on Profile. `RootShell` mounts it as `Scaffold.bottomNavigationBar` with `extendBody`; the routed body reserves `rootShellBottomNavClearance`.
- **Library source switch**: inside `LibraryScreen`, a compact **Local / Cloud** capsule (`LibrarySourceToggle`) beside the title; tap toggles source. Cloud mode uses `/library?source=cloud`; legacy `/cloud` redirects.
- **Desktop (≥ 900 px)**: `AppSidebar` sits on the flat **ground** with a right `line`; routed pages sit directly on the ground beside it — no floating panel. Sidebar (244px): brand row (logo + "Enjoy Player"), search field (paper, 38px, radius 11, `/` keycap), nav rows (`NavItemPill`, 38px, radius 11; the selected row is a paper plate with the lift shadow and a brandInk glyph): Home, Discover, Library, **Vocabulary** (a you-soft due-count pill from `vocabularyStatsProvider`), **Craft** (`C` keycap); footer: sync line (check + "Up to date" / counts → `/settings/sync`), **Settings** row, and `SidebarAccountChip` (34px logo-ring avatar, name, plan subtitle; Free users get a brand **Upgrade** pill). Route highlighting: `/vocabulary*`, `/craft*`, `/settings*`, `/profile` (the chip). The player and review routes still hide the sidebar.
- Page transitions: one glide everywhere, Cupertino on iOS.

## Page layout

Adaptive page families ([ADR-0055](../decisions/0055-adaptive-page-layout-system.md)):

| Kind | Width | Chrome | Examples |
|------|-------|--------|----------|
| `browse` | Centered `pageMaxBrowse` (1180) + `gutter` (40 / 16 phone) | `EditorialHeader` (gutter-aligned) | Home, Discover, Library, channel feed |
| `hub` | Centered `pageMaxHub` (840) | Editorial or `EnjoySubpageAppBar` | Profile, Settings, Subscription, Credits, Hotkeys, AI providers, Vocabulary |
| `form` | Centered `pageMaxForm` (680) | `EnjoySubpageAppBar` | Preferences, Edit Profile |
| `craft` | Centered `pageMaxCraft` (1080) | Craft header | Craft (adopted by the Craft rebuild, D4.6) |
| `auth` | Centered `modalMaxWidth` (400) | Auth scaffold | Sign-in |
| `playerChrome` | Player-owned | Player chrome | Expanded player |

`EnjoySubpageAppBar` is 64px (`subpageHeaderHeight`): a quiet back chevron and a Geist 600 title. Not-found renders the logo mark rotated 180° at 0.55 opacity over a centered 440px column with a Literata 40 title and one brand button.

Use `EnjoyPage` + `EnjoyPageMetrics` (or `pageGutterOf`) — never invent per-screen max widths or stretch form Save buttons to the full desktop pane.

### Page bodies must not host their own `LayoutBuilder` sizing

`EnjoyPage` and `Scaffold` already build their bodies inside a framework `LayoutBuilder`: the layout callback runs with render-tree mutations enabled, and a subtree that inflates there after its ancestors were laid out loses its relayout propagation (`markParentNeedsLayout` defers to the parent that is mid-callback) — the region then never lays out again, renders blank, and every pointer pass logs "Cannot hit test a render box that has never been laid out". Screens therefore take widths from the `EnjoyPageMetrics` handed to `body:` (Home's hero band does: `paneWidth - horizontalInset * 2`) instead of wrapping provider-driven cards in their own `LayoutBuilder`.

The same class of failure arrives through intrinsics: `RenderImage.computeMaxIntrinsicHeight` returns the widget's `height` verbatim, so an image given `width`/`height: double.infinity` makes any ancestor `IntrinsicHeight` query abort `flushLayout` mid-pass, which strands every render object already queued for layout that frame. `MediaCardThumbnail` consequently never passes infinite sizes to its images, and the Continue-practicing cover keeps its thumbnail under `Positioned.fill` so the image's natural size never enters intrinsic math (the cover reports its designed 230px minimum).

## System chrome

- **Mobile**: `MaterialApp.router` builder wraps content in `AnnotatedRegion<SystemUiOverlayStyle>` — transparent status bar with brightness-matched icons; system navigation bar follows porcelain / midnight.
- **Desktop**: native title bars (an integrated macOS title bar is a future option — see ADR-0089 consequences). `window_manager.setMinimumSize(880×560)`.

## Screen registry

Screens are built to their Duet boards: `renders/<Board>.webp` is the visual target, `boards/<Board>.dc.html` carries the exact values, and `boards/canvas.json` indexes every board. `tool/duet_compare.sh` pairs a running screen with its board render.

| Screen | Board(s) |
|--------|----------|
| `SignInScreen` | `SignIn`, `SignInCode` |
| `HomeScreen` | `Home` (variants `HomeDark`, `HomeFirstRun`, `HomeImport`) |
| `LibraryScreen` | `Library` (variants `LibraryAudio`, `LibraryCloud`, `LibraryDelete`, `LibraryImporting`) |
| `DiscoverScreen` | `Discover`, `DiscoverChannel`, `DiscoverManage` |
| `ExpandedPlayerScreen` | `Main` desktop · `Phone` mobile, with the `D*` / `P*` state boards (`DEcho`, `DScored`, `PEcho`, …) |
| `ProfileScreen` | `Profile`, `ProfileEdit`, `ProfilePrefs` |
| `SettingsScreen` | `Settings` (variants `SettingsDark`, `SettingsAbout`) |
| `VocabularyScreen` | `Vocabulary`, `VocabularyReview` |
| `NotFoundScreen` | `NotFound` |

The remaining boards map to their own surfaces by name: Craft (+ advanced / audio / history / rewrite), AI providers, Credits, Keyboard (+ cheatsheet), Review (+ back / done), Subscription (+ plans), Sync, System, TabBar, Sidebar, and the share Poster.

## Design token reference (`EnjoyThemeTokens`)

Duet tokens ([ADR-0093](../decisions/0093-duet-design-language.md)) come from [`docs/design/duet/tokens.json`](../design/duet/tokens.json); `test/core/theme/duet_tokens_test.dart` pins every color, radius, size, breakpoint, motion, opacity, and stroke value to that file in light and dark. Aurora-named fields (`canvas`, `card`, `popover`, `fill`, `hairline`, `textFaint`, …) alias the Duet values until the rename pass.

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
Player:     ruler hit 34 · margin 340 · Listen column 700 · Echo column 760 · video transcript column clamp(300 px, 28 %, 380 px) · take chip 36
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
| `EnjoyCard` / `enjoyCardDecoration` | `core/theme/widgets/enjoy_card.dart` | Paper card with a line outline and the lift shadow, radius 20 |
| `EnjoyAvatar` / `EnjoyTierBadge` / `EnjoyKeycap` | `core/theme/widgets/enjoy_avatar.dart` | Gradient-initial avatar with an optional logo-gradient ring, brand-gradient tier pill (`leading` icon, `padding` scale, `shape`, solid `color` override — also the sidebar Upgrade pill and the tier-catalog badges), paper keycap with a line border and 1px drop |
| `EnjoyProgressRingPainter` | `core/theme/widgets/enjoy_progress_ring.dart` | Track circle + progress arc (solid color or a sweep gradient — the `logo` stops for the Today's Goal ring) — Today's Goal ring, record FAB countdown |
| `EnjoyIconTile` / `EnjoyTint` / `enjoyTintForIcon` | `core/theme/widgets/enjoy_icon_tile.dart` | Colored icon tiles for grouped lists |
| `EnjoySegmentedControl` / `EnjoySegment` | `core/theme/widgets/enjoy_segmented_control.dart` | Sliding-thumb segmented control — 38 sunk track (radius 12) with a raised thumb (radius 9, lift shadow); 30 compact (+ shared track/thumb helpers for segmented `TabBar`s) |
| `AppBackground` | `core/theme/widgets/app_background.dart` | Flat ground fill (the glow is fully deleted in Duet) |
| `EnjoyPage` / `EnjoyPageKind` | `core/theme/widgets/enjoy_page.dart`, `core/layout/enjoy_page_kind.dart` | Adaptive page scaffold + width metrics |
| `EnjoySubpageAppBar` / `EnjoyBackButton` | `core/theme/widgets/enjoy_subpage_app_bar.dart` | Push-route chrome |
| `EditorialHeader` / `EnjoyOverline` / `EnjoySectionHeader` | `core/theme/widgets/editorial_header.dart` | Literata 42 / 32 page title (+ `overline`, `subtitle`), Geist 600 11 caps eyebrow in ink3, Literata 24 section heading |
| `EmptyState` / `EnjoyIconOrb` / `EnjoyLogoMark` | `core/theme/widgets/empty_state.dart`, `core/theme/widgets/enjoy_logo.dart` | The logo's three planes at low opacity + serif title + actions (`EnjoyIconOrb` survives only for surfaces not yet rebuilt) |
| `EnjoyBottomNav` | `core/theme/widgets/enjoy_bottom_nav.dart` | Full-width paper tab bar with a top line; the selected tab gets a `brandSoft` pill, a filled `brandInk` glyph, and a 600 label |
| `NavItemPill` | `core/theme/widgets/nav_item_pill.dart` | Sidebar / settings-rail row (ADR-0018) |
| `showEnjoySheet` / `showEnjoyAdaptiveSheet` / `showEnjoyAlertDialog` / `showEnjoyDialog` | `core/theme/widgets/enjoy_modal.dart` | Popover-surface sheets / dialogs, shared scrim + `enjoyDialogAnimationStyle` |
| `SheetDragHandle` / `PaddedSheetDragHandle` | `core/theme/widgets/sheet_drag_handle.dart` | 36×5 grabber |
| `MediaCardTile` / `MediaCardRow` | `core/theme/widgets/media_card.dart` (→ `media_card/`) | Poster tile (artwork is the card) with optional discover affordances (adding scrim, in-library chip, custom `meta` slot) / list row |
| `SettingsRow` / `SettingsRowDivider` / `SettingsValuePill` | `features/settings/presentation/widgets/settings_row.dart` | Grouped-list row with icon tile, value, chevron |
| `AppNotice` | `core/notices/app_notice.dart` | Dark toast with semantic glyph |
| `Skeleton` (+ helpers) | `core/theme/widgets/skeleton.dart` | Shimmer placeholders; see [skeleton-loading.md](skeleton-loading.md) |
| `LoadingIcon` / `SectionLabel` | `core/presentation/` | Inline spinner; in-card section label |
| `AppSidebar` / `SidebarAccountChip` | `features/player/presentation/widgets/app_sidebar.dart`, `features/auth/presentation/widgets/sidebar_account_chip.dart` | Desktop navigation on the canvas |

## ADRs

- [ADR-0093](../decisions/0093-duet-design-language.md) — Duet design language (current look)
- [ADR-0089](../decisions/0089-aurora-design-language.md) — Aurora design language (superseded in part by 0093; §4 icons, §6 interaction, §7 motion stand)

- [ADR-0007](../decisions/0007-dynamic-color-from-artwork.md) — Dynamic color from artwork (superseded by 0093; the module was removed)
- [ADR-0008](../decisions/0008-light-mode-parity.md) — Light mode parity (superseded by 0011)
- [ADR-0009](../decisions/0009-platform-adaptive-shell.md) — Platform-adaptive shell
- [ADR-0011](../decisions/0011-dark-mode-only.md) — Dark mode only (superseded by 0083)
- [ADR-0083](../decisions/0083-paper-graphite-light-dark.md) — Paper / graphite light+dark + System/Light/Dark appearance
- [ADR-0055](../decisions/0055-adaptive-page-layout-system.md) — Adaptive page layout system
