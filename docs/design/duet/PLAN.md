# Duet — implementation plan

> **For agents:** pick work from [`STATUS.md`](STATUS.md), follow [§ How to work a task](#how-to-work-a-task), and keep the tracker current in the same PR. Steps are written so that every task lands green (`flutter analyze` + `flutter test`) on its own.

**Goal**: Replace the unreleased Aurora UI with Duet on every screen. Features, behavior, hotkeys, and data do not change.
**Decision**: [ADR-0091](../../decisions/0091-duet-design-language.md). **Design**: this folder ([README](README.md) → renders, boards, tokens).
**Branch**: `design-duet`, which merges to `main` as one release when Phase 5 is done.
**Stack**: Flutter 3.44 (`mise.toml`), Riverpod 3, `google_fonts` 8.2 with bundled fonts, Phosphor via `EnjoyIcons`.

---

## Contents

1. [Rules that never bend](#rules-that-never-bend)
2. [How to work a task](#how-to-work-a-task)
3. [Architecture of the change](#architecture-of-the-change)
4. [Phases and tasks](#phases-and-tasks)
5. [Performance goals](#performance-goals)
6. [Verification](#verification)
7. [Documentation map](#documentation-map)
8. [Risks](#risks)

---

## Rules that never bend

1. **UI/UX only.** No feature, behavior, data, hotkey, or analytics change.
   - When a board seems to require one, do the UI change without it. Mark the task `needs decision` in `STATUS.md` with a one-line question.
   - Open questions already found are in [STATUS.md → Decisions](STATUS.md#decisions).
2. **The Echo loop pauses and rewinds at the loop end.** It never auto-repeats. `EchoEnforcer` is not touched.
3. **Every hotkey keeps its key and action** ([hotkeys.md](../../features/hotkeys.md)). New tooltips show the key (`Record · R`).
4. **Video surfaces.** The native video and YouTube surfaces are positioned under Flutter, and WebView2 paints above Flutter overlays on Windows.
   - A panel that overlaps the video stage must be a route. `PlayerSurfaceOverlayCoordinator` parks the surface for every `PopupRoute`.
   - Or the panel must be a layout sibling that reflows `PlayerSurfaceTarget`.
   - Never use a non-route `Overlay`/`Stack` layer above the stage ([ADR-0066](../../decisions/0066-park-player-surface-for-overlays.md)).
5. **Repo rules apply unchanged** ([AGENTS.md](../../../AGENTS.md)): zero `//` comments in `lib/` / `test/`, no `print()`, single `media_kit` player, Drift DAOs only, `EnjoyPage` page kinds, codegen regenerated and committed, and ARB strings for en + zh + zh_CN.
6. **Behavior tests are frozen.** A Duet PR must not modify `lib/**/application/**`, `lib/**/domain/**`, `lib/data/**`, or their tests. There are three exceptions; name them in the PR body:
   - (a) new *presentation-state* providers, such as which margin panel is open;
   - (b) deleting the dynamic-color module (D3.1);
   - (c) renaming token call sites (D5.1).

   Check:

   ```bash
   git diff --stat origin/design-duet...HEAD -- ':(glob)lib/**/application/**' ':(glob)lib/**/domain/**' ':(glob)lib/data/**' \
     ':(glob)test/**/application/**' ':(glob)test/**/domain/**' ':(glob)test/data/**' docs/features/hotkeys.md
   ```

---

## How to work a task

1. **Read.** Read [README → Implementing from this folder](README.md#implementing-from-this-folder), ADR-0091, and the task below. Open every board render listed for the task (`renders/<Board>.webp`, plus `.full.webp` when present).
2. **Claim.**
   - Make sure nobody holds the task: `gh pr list --base design-duet --search "<ID>"`. Also check that its `Depends` rows are `done` in `STATUS.md`.
   - Open a draft PR titled `[duet <ID>] <task title>` early. The draft PR is the claim.
3. **Branch.** Use `duet/<id>-<slug>` from the latest `design-duet`, e.g. `duet/d3.2-dock`. A single agent working alone may commit straight to `design-duet`.
   - Run codegen in the main checkout, not an agent worktree ([AGENTS.md → Codegen](../../../AGENTS.md#codegen)).
4. **Build to the board.**
   - Take values from `tokens.json` through `EnjoyThemeTokens`. Read exact one-off values from `boards/<Board>.dc.html`.
   - Reuse the shared primitives from Phase 1 rather than restyling locally.
5. **Tests.**
   - Update the widget tests your change breaks, and add the tests the task lists.
   - Keep or move every `Key` / semantics label that tests or onboarding tips use (`lib/features/onboarding/presentation/onboarding_keys.dart`).
6. **Gallery.** Add or refresh the gallery scene for each board you touched (D0.2), then compare it with the render (`tool/duet_compare.sh <Board>`).
7. **Gates.** Run `bash .github/scripts/validate_ci_gates.sh` (or `--fix`), `flutter analyze`, `flutter test`, and the behavior-freeze check above.
8. **Docs.**
   - Update the feature doc named in the task and the matching part of [`app-ui.md`](../../features/app-ui.md).
   - Set the task row in `STATUS.md` to `done`, with the PR link, in the same PR.
9. **PR body.** Include:
   - the boards covered;
   - the gallery-vs-render compare images for those boards;
   - the freeze-check output;
   - perf evidence when the task names a perf goal;
   - anything deferred, with a new `STATUS.md` row.

Status values: `todo` · `in progress` · `review` · `done` · `blocked` · `needs decision`. Open PRs are the source of truth for in-flight work. `STATUS.md` shows what has merged.

---

## Architecture of the change

### Tokens: alias, then migrate, then delete

`EnjoyThemeTokens` (`lib/core/theme/enjoy_tokens.dart`, read in 160 files) stays the single theme extension. Changes happen in three steps so every commit compiles:

1. **D1.1** adds every Duet token as a new field and sets the Aurora color fields to the Duet values from the table below. The whole app changes color in one PR and no call site changes.
2. **Phases 2–4** migrate call sites to the Duet names as each screen is rebuilt.
3. **D5.1** renames whatever still uses an Aurora name, then deletes the aliases and the Aurora-only tokens.

| Aurora field | Duet value in D1.1 | Final name (D5.1) |
|---|---|---|
| `canvas` | `ground` | `ground` |
| `card` | `paper` | `paper` |
| `popover` | `raised` | `raised` |
| `fill` | `sunk` | `sunk` |
| `hairline` | `line` | `line` |
| `textFaint` | `ink3` (5.4:1, readable text now) | `ink3` |
| `accentInk` / `accentSoft` | `brandInk` / `brandSoft` | same |
| `intelligenceInk` | `originalInk` | `originalInk` |
| `echoActive` / `echoInk` | `you` / `youInk` | same |
| `blurActive` | `ink` (Hide text is ink) | delete |
| `scoreGood` / `scoreWarn` (+ containers) | `ink2` / `sunk` | delete: scores are uncolored |
| `scoreBad` (+ container) | `danger` / `sunk` | `danger` |
| `auroraStart` / `auroraEnd` / `aurora` | logo stops, unchanged values | `logoStart` / `logoEnd` / `logo` |
| `glassTint` / `glassBorder` | `paper` / `line` | delete with `GlassSurface` |
| `gradientStart` / `gradientEnd` | `ground` | delete |
| `topHighlight` | transparent | delete |
| `shellInset` / `panelRadius` | `0` / `0` | delete (D2.1 removes the panel) |
| `shadowCard` / `shadowFloat` / `shadowPopover` | `lift` / `float` / `float` | `shadowLift` / `shadowFloat` |
| `sidebarWidth` 236 | 244 | same |
| `pageGutter` 24 | 40 | same |
| `controlHeightLg` 48 | 50 | same |
| `contentMaxWidth` 720 | 780 | `transcriptMaxListen` (+ `transcriptMaxEcho` 880) |

New fields, all from `tokens.json`:
- **Colors:** `ground`, `paper`, `raised`, `sunk`, `line`, `ink`, `ink2`, `ink3`, `original`, `originalInk`, `originalSoft`, `you`, `youInk`, `youSoft`, `youLine`, `onYou`, `brandInk`, `brandSoft`, `primary` / `onPrimary` (ink fill), `danger`, `shape`, `tick`, `scrim`, `video`, and `vocabStatus` (×4).
- **Gradients:** `brand` and `logo`.
- **Radii:** `radiusKeycap` 5, `radiusBadge` 7, `radiusControl` 12, `radiusTile` 14, `radiusCard` 20, `radiusCardLarge` 24, `radiusDialog` 24, `radiusSheet` 26.
- **Sizes:** the `size` block (dock buttons, margin 380, top bar 60, subpage header 64, tab bar 84 / 26, browse 1180 / craft 1080 widths, gutters 40 / 16).
- **Breakpoint:** `breakpointMarginDrawer` 1100.
- **Motion:** `motionLens` 280 and `motionMargin` 220.
- **Opacity:** `echoLensOpacity` `[1, .65, .35, .2]` and `referencePitchOpacity` .35.
- **Strokes:** the `stroke` block.
- **Shadows:** `shadowBrandButton` and `shadowRecordButton`.

Pin it: `test/core/theme/duet_tokens_test.dart` parses `docs/design/duet/tokens.json` and asserts that every color, radius, size, breakpoint, and motion value matches `EnjoyThemeTokens` in light and dark. A design change then becomes a token change plus a failing test, never silent drift.

### Material `ColorScheme`

`AppColors.colorScheme` and the component themes in `app_theme.dart` map the stock widgets onto Duet:

| Role | Light / dark | Board evidence |
|---|---|---|
| `primary` / `onPrimary` | `brandInk` / white; dark `brandInk` / `ground` | Radio dot, selected sidebar / tab glyph (`on ? var(--brand-ink)`) |
| `primaryContainer` | `brandSoft` | Selected rows and the tab-bar pill |
| `secondary` | `original` | Player switches, the ruler, and the karaoke underline (`track = on ? var(--blue)`) |
| `tertiary` / `onTertiary` | `you` / `onYou` | Record and takes |
| `error` | `danger` | Delete |
| `surface` / `surfaceContainer*` | `ground` / `paper` / `raised` / `sunk` | — |
| `onSurface` / `onSurfaceVariant` | `ink` / `ink2` | — |
| `outline` / `outlineVariant` | `ink3` / `line` | — |

Filled text buttons never take `ColorScheme.primary`. `EnjoyButton` owns its fills:
- `brand` uses the brand gradient and white text, with `shadowBrandButton`.
- `primary` uses an ink fill (`Choose file`, `Continue with Apple`, `Create`).
- `secondary` is paper + line, `ghost` is ink2, and `destructive` is `danger` with white text.
- No "lit" sheen.

### Typography

`lib/core/theme/typography.dart` is the only place that names a font:

| Use | Face | Where in code |
|---|---|---|
| Display / page titles / big numbers | Literata 500 (`_display`, `enjoyDisplayStyle`) | replaces `GoogleFonts.instrumentSerif` |
| Transcript | Literata 400 / 500 (`TranscriptTypographyTokens`, `useSerif` stays `true`) | replaces `GoogleFonts.sourceSerif4TextTheme` |
| UI | Geist 400 / 500 / 600 | unchanged (`buildBaseTextTheme`); no 700 |
| Mono | Geist Mono 500 / 600 (`enjoyMonoStyle`) | unchanged; adds 600 |
| IPA | Noto Sans 400 | unchanged |

The type scale follows `tokens.json → typography.scale`. CJK fallbacks stay: the existing `kCjkSerifFallbacks` / `kCjkSansFallbacks`.

### The player, recomposed

| Today | Duet | Task |
|---|---|---|
| `PlayerFrostedBackButton`, `PlayerCollapseControl` floating over the transcript (ADR-0085) | Solid 60 px top bar: collapse · title + meta · Listen/Echo segmented control · Share · Subtitles · More | D3.1 |
| `PlayerAmbientBackdrop` + `dynamic_color/` artwork tint (ADR-0007) | Flat `ground`; deleted | D3.1 |
| `GlobalTransportBar` glass capsule + `NarrowTransportBudget` | Solid dock: ruler row + controls row, in Listen / Echo / Recording variants | D3.2 |
| `TransportProgressStrip` | Sentence ruler | D3.3 |
| `TranscriptLineTile`, `TranscriptScrollableList` | Listen lens (book-like reading) | D3.4 |
| `EchoRegionMergedCard` + `EchoRegionControlsBar` | Echo lens: loop line grows in place, corner brackets, Earlier / Later pills | D3.5 |
| `ShadowReadingPanel`, `ShadowRecordFab`, `PitchContourSection` | Takes row + pitch duet inside the loop; Original + Record in the dock | D3.6 |
| `LookupCoordinator` dialog (≥ 900) / sheet | Side margin on the player: docked ≥ 1100, drawer route 600–1100, sheet < 600 | D3.7 |
| `showAssessmentResultDialog` | Assessment in the margin + feedback on the words | D3.8 |
| `TranscriptBlurText` (Gaussian blur) | Word shapes | D3.9 |
| CC sheet + `TranscriptDisplaySettingsSheet` | Subtitles & display popover (sheet on phone) | D3.10 |

---

## Phases and tasks

Each task lists **Boards**, **Code** (where today's UI lives), **Change**, **Keep** (frozen behavior), **Tests**, and **Docs**. "Done when" is always: boards match in the gallery compare, gates are green, the freeze check is clean, and `STATUS.md` is updated.

```
Phase 0  D0.1 ─ D0.2
Phase 1  D1.1 → D1.2 → D1.3 → { D1.4, D1.5, D1.6, D1.7, D1.8 }
Phase 2  D2.1, D2.2, D2.3                        (after Phase 1)
Phase 3  D3.1 → { D3.2 → D3.3 } ; { D3.4 → D3.5 → D3.6 } ; D3.7 → D3.8 (needs D3.6) ;
         D3.9 (needs D3.4) ; D3.10, D3.11 (need D3.1) ; D3.12 (needs D3.6) ; D3.13 last
Phase 4  D4.1 … D4.11                             (after Phase 1 + Phase 2; parallel)
Phase 5  D5.1 → D5.2 → { D5.3, D5.4, D5.5 } → D5.6
```

Phases 2, 3, and 4 can run in parallel once Phase 1 is done. Inside Phase 3, follow the arrows.

### Phase 0 — Ready

#### D0.1 Design reference, ADR, plan, tracker
Already done: `docs/design/duet/`, ADR-0091, this plan, `STATUS.md`, the Literata / Geist / Geist Mono font files, and the pointers in `AGENTS.md` and the docs indexes.

#### D0.2 Gallery harness (opt-in screenshots)
- **Change:**
  - Add `test/duet_gallery/` with `gallery_support.dart`. It holds:
    - a `RepaintBoundary` capture;
    - board-size presets: desktop 1440 × 900 at 1×, compact 880 × 560, phone 390 × 844 at 2×;
    - a light/dark switch;
    - font loading from the bundle (`FontManifest.json` for Phosphor; `GoogleFonts.config.allowRuntimeFetching = false`). No network.
  - Write PNGs to `build/duet_gallery/<Board>.png`.
  - Add `dart_test.yaml` with a `gallery` tag that is skipped by default:
    ```yaml
    tags:
      gallery:
        skip: "Opt-in screenshots: flutter test --tags gallery --run-skipped test/duet_gallery"
    ```
  - Add `tool/duet_compare.sh [Board…]`. It writes `build/duet_gallery/compare/<Board>.png`: the render on the left, the app on the right, at the same scale (ImageMagick).
  - Seed it with one scene per existing screen (Home, Library, Settings, player Listen) using today's Aurora UI and ProviderScope fixtures (`test/support/fake_player_engine.dart`). Later tasks add their boards.
  - A maintainer-local, git-excluded prototype may exist at `test/_gallery/`. Borrow from it if present; do not depend on it.
- **Tests:**
  - Plain `flutter test` reports the gallery as skipped and stays green.
  - `flutter test --tags gallery --run-skipped test/duet_gallery` writes PNGs with real fonts.
- **Docs:** add a "Gallery" section to [testing.md](../../testing.md).

### Phase 1 — Foundations (the whole app changes color here)

#### D1.1 Duet tokens + parity test
- **Code:** `lib/core/theme/enjoy_tokens.dart` and `lib/core/theme/colors.dart`.
- **Change:** add the fields from [Tokens](#tokens-alias-then-migrate-then-delete); set the Aurora color fields to the Duet values (alias table). Add `AppColors` Duet constants (light / dark), kept in sync with `tokens.json`.
- **Keep:** field names that call sites use, so no call-site edits are needed.
- **Tests:** new `test/core/theme/duet_tokens_test.dart` (tokens.json parity); update `test/core/theme/enjoy_tokens_test.dart`.
- **Docs:** `app-ui.md` → "Design token reference" rewritten from `tokens.json`.

#### D1.2 Color scheme + component themes
- **Code:** `AppColors.colorScheme` and every `*Theme` in `lib/core/theme/app_theme.dart`.
- **Change:** apply the [ColorScheme](#material-colorscheme) table.
  - Inputs: radius 12, `sunk` fill, focus border `brandInk`.
  - Switch: on-track `brandInk` app-wide; the player popover overrides to `original` in D3.10.
  - Radio / checkbox: `brandInk`. Slider: `original`.
  - Dialogs: `raised`, radius 24, `scrim` token. Sheets: radius 26.
  - Menus / popovers: `raised` + `float` shadow. Tooltips: ink on `ground`, mono key suffix.
  - Snackbar: `AppNotice` stays a dark toast in `ink`.
  - Focus ring: 2 px `brandInk`.
  - Text selection: `originalSoft` + `original` handles.
  - Scrollbar thin, `ink3` at 40%.
- **Tests:** `test/core/theme/app_overlay_style_test.dart` and any theme tests that pin Aurora colors.
- **Docs:** `app-ui.md` → "Design direction", "Theme mode".

#### D1.3 Typography
- **Code:** `lib/core/theme/typography.dart`; `test/core/theme/bundled_google_fonts_test.dart` (`_bundledVariants`).
- **Change:** apply the [Typography](#typography) table and the `tokens.json` scale. Display moves from Instrument Serif 400 to Literata 500; `enjoyDisplayStyle` defaults to weight 500. The transcript moves from Source Serif 4 to Literata.
- **Keep:** CJK fallbacks; `useSerif: true` with no user setting; `enjoyMonoStyle` as the only mono path.
- **Tests:**
  - Add Literata 400 / 500 / 600, Geist 600, and Geist Mono 600 to `_bundledVariants`.
  - Remove the Instrument Serif / Source Serif 4 entries only when nothing requests them, then delete their font files. Playfair stays while the poster uses it; see D3.12.
- **Docs:** `app-ui.md` → "Typography".

#### D1.4 Buttons
- **Boards:** `System`, and any screen with buttons (`Home`, `SignIn`, `DLocate`, `LibraryDelete`).
- **Code:** `lib/core/theme/widgets/enjoy_button.dart` (`EnjoyButton`, `EnjoyIconButton`, `enjoyLitFill*`).
- **Change:**
  - Variants become `brand` / `primary` / `secondary` / `ghost` / `destructive` (see [ColorScheme](#material-colorscheme)). Map today's `primary` call sites to `brand` and `tonal` to `secondary`, each in its own feature task, or keep `tonal` as an alias until D5.1.
  - Sizes: 32 / 40 / 50, radius 12, Geist 600 14.
  - Icon buttons: 40 desktop / 44 phone.
  - Delete the lit sheen. The record FAB and play ring get their own looks in D3.2.
- **Tests:** `test/core/theme/widgets/` button tests; `test/helpers/pressable_finders.dart` stays valid.
- **Docs:** `app-ui.md` → "Widgets reference".

#### D1.5 Controls
- **Boards:** `System`, `Library` (segmented, chips, search), `Settings` (switches), `VocabularyReview` (radios), `Keyboard` (keycaps).
- **Code:**
  - `enjoy_segmented_control.dart`: `sunk` track 38 high, `raised` thumb with `lift`.
  - Chips: 34 high; pressed = ink fill with paper text.
  - `EnjoyKeycap` in `enjoy_avatar.dart`: Geist Mono, radius 5 / 7.
  - Search fields; `enjoy_progress_ring.dart` (logo gradient).
  - `EnjoyTierBadge` and the Upgrade pill: brand gradient.
  - `EnjoyAvatar`: logo-gradient ring.
- **Tests:** existing widget tests for these primitives.

#### D1.6 Surfaces and page furniture
- **Boards:** `System`, `NotFound`, `LibraryDelete` (dialog), `SubscriptionPlans` (sheet).
- **Code:**
  - `enjoy_card.dart`: `paper` + `line`, radius 20.
  - `enjoy_modal.dart`: `raised`, radius 24 / 26, `scrim`; `sheet_drag_handle.dart`.
  - `editorial_header.dart`: Literata 42 / 32 title; overline Geist 600 11 caps 0.08em `ink3`; `EnjoySectionHeader` Literata 24.
  - `empty_state.dart`: replace the icon orb with the logo's three triangles at low opacity, per `DEmpty` and `ReviewDone`.
  - `skeleton.dart`: `sunk` shimmer.
  - `core/notices/app_notice.dart`: errors in `danger`; success has no green.
- **Tests:** `skeleton_*`, `enjoy_adaptive_sheet_test.dart`, `enjoy_modal_root_navigator_test.dart`, empty-state tests.
- **Docs:** `app-ui.md`; [skeleton-loading.md](../../features/skeleton-loading.md) if colors are named there.

#### D1.7 Generated covers + media cards
- **Boards:** `Home`, `Library`, `LibraryAudio`, `Discover`, `CraftHistory`.
- **Code:** `lib/core/theme/generative_media_cover.dart` and `lib/core/theme/widgets/media_card/` (`tile.dart`, `row.dart`, `badges.dart`, `helpers.dart`).
- **Change:**
  - Replace the generative painter with the logo-plane recipe in `tokens.json → generatedCover`. Pick the palette by a stable hash of the media id.
  - Tiles: radius 14, mono duration pill, language chip, Craft / YouTube labels as drawn.
  - The illustrated scenes on the boards are placeholders; real thumbnails stay.
- **Keep:** thumbnail loading, caching, and the decode-size rules in [library.md](../../features/library.md).
- **Tests:** `generative_media_cover_test.dart` and `generative_media_cover_coverage_test.dart` are rewritten for the new recipe (deterministic per id, all 8 palettes reachable); media card tests.
- **Perf:** one `CustomPainter` per cover with `shouldRepaint` keyed on (id, size); no per-frame work in grid builders.
- **Docs:** [library.md](../../features/library.md) → thumbnails.

#### D1.8 Flat ground (remove the glow)
- **Code:** `lib/core/theme/widgets/app_background.dart` (`AppBackground`, `AuroraGlow`).
- **Change:** `AppBackground` paints `ground` only. Delete `AuroraGlow` once nothing calls it (sign-in uses it until D4.7; keep it as a no-op until then).
- **Tests:** any test that finds `AuroraGlow`.

### Phase 2 — Shell

#### D2.1 Desktop shell + sidebar
- **Boards:** `Sidebar`, `Home` (shell context), `HomeDark`.
- **Code:** `lib/features/player/presentation/root_shell.dart` (`_ContentPanel`), `lib/features/player/presentation/widgets/app_sidebar.dart`, `lib/core/theme/widgets/nav_item_pill.dart`, `lib/features/auth/presentation/widgets/sidebar_account_chip.dart`.
- **Change:**
  - Remove the floating content panel. Pages sit on `ground` beside a 244 px sidebar.
  - Top of the sidebar:
    - brand row: logo + "Enjoy Player";
    - search field with the `/` keycap;
    - rows for Home, Discover, Library, **Vocabulary** (due count from `vocabularyStatsProvider.due`) and **Craft** (`C` keycap).
  - Footer: sync status line, **Settings** row, account chip (avatar, name, plan, Upgrade pill).
  - Route highlighting: `/vocabulary*` → Vocabulary, `/craft*` → Craft, `/settings*` → Settings.
  - **Gated by decision S1** ([STATUS → Decisions](STATUS.md#decisions)).
- **Keep:** the routes and the `/` and `C` hotkeys. The player and review routes still hide the sidebar.
- **Tests:** the sidebar widget test shows the new rows and due count; route → selected-row mapping; `test/helpers/chrome_icon_finders.dart`.
- **Docs:** `app-ui.md` → "Navigation"; [settings.md](../../features/settings.md) if Settings entry points are listed.

#### D2.2 Phone tab bar
- **Boards:** `TabBar`, `PhHome`, `PhLibrary`.
- **Code:** `lib/core/theme/widgets/enjoy_bottom_nav.dart`, `lib/core/notices/root_shell_bottom_inset.dart` (`rootShellBottomNavClearance`).
- **Change:**
  - A solid bar replaces the glass capsule and gliding lens. Height is 84 including the 26 safe inset (use the real safe area).
  - The selected tab gets a `brandSoft` pill and a filled glyph in `brandInk`.
  - Same four destinations; the update badge stays on Profile.
- **Tests:** bottom-nav tests; bottom-clearance tests.
- **Docs:** `app-ui.md` → "Navigation".

#### D2.3 Page metrics + subpage chrome
- **Boards:** `Home` (browse), `Profile` (hub), `ProfileEdit` (form), `Craft` (1080), `Settings`, `NotFound`.
- **Code:** `lib/core/layout/enjoy_page_kind.dart`, `lib/core/theme/widgets/enjoy_page.dart`, `enjoy_subpage_app_bar.dart` (64 high; back chevron + Geist 600 title), `lib/core/routing/not_found_screen.dart`.
- **Change:** gutters are 40 desktop / 16 under 600. Max widths: browse 1180, hub 840, form 680, and a Craft width of 1080 (new kind, or a parameter on `browse`; record which in the PR).
- **Tests:** the page-kind metrics tests.
- **Docs:** `app-ui.md` → "Page layout" (ADR-0055 values amended by ADR-0091).

### Phase 3 — Player

Read [player.md](../../features/player.md), [transcript.md](../../features/transcript.md), [echo-mode.md](../../features/echo-mode.md), [shadow-reading.md](../../features/shadow-reading.md), and [dictionary-lookup.md](../../features/dictionary-lookup.md) before starting. The interactive prototype's logic is in `boards/Main.dc.html` and `boards/Phone.dc.html` (`<script data-dc-script>`).

#### D3.1 Player frame + top bar
- **Boards:** `Main`, `DEcho`, `DVideo`, `DYoutubeDark`, `DCompact`, `Phone`, `PVideo`.
- **Code:** `expanded_player_screen.dart`, `expanded_player_widgets.dart` (`ExpandedPlayerChromeBody`), `layouts/audio_player_layout.dart`, `layouts/video_player_layout.dart`, `widgets/player_collapse_control.dart`, `widgets/player_frosted_back_button.dart`, `lib/core/theme/dynamic_color/`.
- **Change:**
  - **Top bar** (60 px, `paper` with a bottom `line`):
    - collapse chevron (`Collapse player · Ctrl+Shift+P`);
    - title + meta (`Audio · 0:55 · English · 中文`);
    - centered Listen | Echo segmented control with the `E` keycap, driving today's echo-mode toggle;
    - Share, only under the ADR-0068 rule;
    - Subtitles (opens D3.10);
    - More (…). It holds the existing player actions that get no slot in the top bar or dock; list them in the PR.
  - **Phone top bar** per `Phone`: chevron · segmented · share · subtitles icon.
  - **Audio:** centered transcript column, 780 in Listen and 880 in Echo.
  - **Video:**
    - left column `min(520px, 46%)`, keeping the existing resize splitter;
    - paused title overlay;
    - YouTube chips (YouTube account, Open in browser) under the stage;
    - phone video stacked on top (`PVideo`).
  - **Delete:** `PlayerAmbientBackdrop`, `dynamic_color/` (`artwork_palette.dart`, `dynamic_color_provider.dart`) and their tests, and the floating collapse / back controls.
- **Keep:**
  - `PlayerSurfaceTarget` / `PlayerSurfaceHost` contracts, splitter persistence, fullscreen, and collapse-flush behavior;
  - the YouTube parking rules;
  - the 880 × 560 minimum window.
- **Tests:**
  - player chrome widget tests;
  - remove `artwork_palette_test.dart`;
  - the video layout still reports surface geometry after a splitter drag.
- **Docs:** [player.md](../../features/player.md): chrome, wide layout, ADR-0085 / ADR-0007 superseded.

#### D3.2 Dock
- **Boards:** `Main` (Listen), `DEcho` (Echo), `DRecording` (Recording), `DVideo` (fullscreen), `Phone`, `PEcho`, `PRecording`.
- **Code:** `widgets/global_transport_bar.dart` (including `NarrowTransportBudget`), `widgets/transport/` (`transport_play_ring_button.dart`, `transport_volume_button.dart`, `transport_cc_fullscreen.dart`, `transport_meta_row.dart`, `transport_playback_rate.dart`), `lib/features/shadow_reading/presentation/widgets/shadow_record_fab.dart`.
- **Change:** a solid `paper` dock: ruler row (D3.3) over a controls row.
  - **Listen:**
    - left: Hide text (`H` keycap) and `Line 6 of 14`;
    - center: Replay `S`, Prev `A`, **Play** (60 px brand gradient, logo-triangle glyph), Next `D`;
    - right: speed `1.0×`, volume, and fullscreen on video.
    - The board's Repeat button is **gated by decision R1**.
  - **Echo:**
    - left: Hide text and `Line 6 of 14 · looping`;
    - center: Prev, **Original** (150 × 52 soft `original` pill; plays the loop; `S`), **Record** (62 px `you`, `R`), Next;
    - right: speed and volume.
  - **Recording:** centered Cancel (`Esc`) and Stop (`R`).
  - **Phone:** play 68, record 76, original 56, with labels under the Echo buttons.
  - Speed still opens the existing speed sheet, restyled. Volume keeps its popover (#839 fix).
- **Keep:**
  - every action and hotkey;
  - nothing becomes unreachable at any width ≥ 880 or on a 390-wide phone. Volume may drop on phones (system volume), as today.
- **Tests:**
  - dock variant tests for listen, echo, and recording states;
  - replace the `NarrowTransportBudget` tests with the new width rules;
  - onboarding tip keys move to the new controls.
- **Perf:** position ticks rebuild only the ruler and time labels (rebuild-count test, [perf-measurement.md](../../perf-measurement.md) Pattern 2).
- **Docs:** [player.md](../../features/player.md) → "Global transport" becomes "Dock".

#### D3.3 Sentence ruler
- **Boards:** `Main`, `DEcho`, `Phone`, `PEcho`.
- **Code:** `widgets/transport/transport_progress_strip.dart`.
- **Change:**
  - 4 px track: `original` played, `sunk` rest.
  - One `tick` per transcript line start.
  - Loop bracket in `you` over the Echo region.
  - Practiced dots above the lines that have takes.
  - Mono times at both ends; thumb ring in `original`.
  - Hit height 34.
- **Keep:** seek and scrub behavior, keyboard seeking, and semantics value.
- **Tests:** tick positions from line timings; bracket follows the echo region; dots follow lines with recordings; seek callback.
- **Perf:** one `CustomPainter` behind `RepaintBoundary`. Ticks and dots are cached until the transcript or recordings change.
- **Docs:** [player.md](../../features/player.md).

#### D3.4 Listen lens (transcript reading)
- **Boards:** `Main`, `DDark`, `Phone`, `PDark`.
- **Code:** `lib/features/transcript/presentation/transcript_line_tile.dart`, `transcript_scrollable_list.dart`, `transcript_panel.dart`, `transcript_word_ipa_layer.dart`, `transcript_line_recording_badge.dart`, `transcript_markup.dart`.
- **Change:**
  - Line: Literata 20 (phone 18). Active line: 26 / 500 (phone 23).
  - Mono timestamps in the gutter.
  - Translation: Geist 14, active 15.5.
  - Karaoke: `original` underline on the spoken word.
  - IPA stacked under words (Noto Sans 14).
  - Practiced dot in the gutter (`you`).
  - No active-line plate and no iris rail.
- **Keep:** auto-scroll, selection, and lookup triggers; karaoke and IPA availability rules; the ADR-0075 / ADR-0076 layout rules.
- **Tests:** existing transcript tile and list tests updated; the large-list stress test (Pattern 4) still passes.
- **Perf:** see [Performance goals](#performance-goals).
- **Docs:** [transcript.md](../../features/transcript.md) → presentation.

#### D3.5 Echo lens
- **Boards:** `DEcho`, `PEcho`, `DCompact`.
- **Code:** `transcript_echo_region_merged_card.dart`, `echo_region_controls_bar.dart`, and the list from D3.4.
- **Change:**
  - The loop lines grow in place: Literata 500. Size by line count: 1 line 30–46 (`loopLine`), 2 lines 34, 3+ lines 25; video column 30; phone 28.
  - Corner brackets in `you`.
  - Label `LOOP · LINE 6 · 4.2 S`.
  - `+ Earlier line | −` pill above the loop and `− | Later line +` below, for expand / shrink backward / forward.
  - Neighbour lines fade by distance through `echoLensOpacity` and shrink to `lensLine` sizes.
  - Listen ↔ Echo animates in `motionLens` 280 ms. Under reduced motion it crossfades.
- **Keep:** `EchoEnforcer` pause-and-rewind, the region rules (`shrinkEchoBackward` = start + 1), and `[` `]` `{` `}`.
- **Tests:** loop-line sizing per line count; pill actions call the same controller methods; neighbour opacity steps; the reduced-motion path.
- **Perf:** the lens animates per visible row (implicit opacity/size), never by rebuilding the list.
- **Docs:** [echo-mode.md](../../features/echo-mode.md), [transcript.md](../../features/transcript.md).

#### D3.6 Takes, pitch, and recording in the loop
- **Boards:** `DEcho`, `DRecording`, `DScored`, `PEcho`, `PRecording`, `PScored`.
- **Code:** `lib/features/shadow_reading/presentation/shadow_reading_panel.dart`, `widgets/shadow_takes_toolbar_actions.dart`, `widgets/shadow_reading_toolbar_row.dart`, `widgets/shadow_recording_live.dart`, `widgets/shadow_recording_caption.dart`, `pitch_contour_section.dart`, `pitch_contour_chart.dart`, `recording_assessment_button.dart`.
- **Change:**
  - **Takes row** under the loop: `TAKES` label, then one chip per take (play `G`, duration, score chip or `Score` `V`), plus the Pitch toggle `P`.
  - **Pitch duet:** reference as a 9 px `original` band at 0.35 opacity, yours as a 3 px `you` line, with a legend.
  - **Recording:**
    - label `RECORDING TAKE n`;
    - the loop text's underline fills as the countdown runs, plus a thin progress bar with a `2.4 s / 4.2 s` readout under the loop;
    - Cancel / Stop sit in the dock (D3.2).
  - **Phone:** a score summary card (`84 Good · Take 3`) opens the assessment sheet (D3.8).
- **Keep:** the recording bus, take ordering, assessment cost and credits flow, the pitch computation (FFmpeg + YIN), and the "Play my recording" behavior.
- **Tests:** takes row states (no takes, unscored, scoring, scored); the pitch chart paints reference and take; recording-state widget test.
- **Docs:** [shadow-reading.md](../../features/shadow-reading.md).

#### D3.7 Side margin + word lookup
- **Boards:** `DWord`, `DCompact`, `PWord`.
- **Code:** `lib/features/lookup/application/lookup_coordinator.dart` (presentation branch only), `lib/features/lookup/presentation/dictionary_lookup_sheet.dart` and `sections/`, `widgets/`.
- **Change:**
  - A `PlayerMargin` container, sized by player width:
    - ≥ `breakpointMarginDrawer` (1100): docked in the layout at 380 px; the transcript column reflows; the video target reflows.
    - 600–1100: a right-edge drawer **route** with `scrim`, so the surface parks.
    - < 600: a bottom sheet (existing `showEnjoySheet`).
  - `Esc` closes it; close button `Close · Esc`; slides in over `motionMargin` 220.
  - Margin state (which panel, and for which word or take) lives in a presentation provider.
  - **Word panel:**
    - word + IPA + part of speech;
    - Pronounce / Save / Copy;
    - language pair with Swap;
    - Translation, Definition, and Contextual translation sections (expand to load).
  - `LookupCoordinator.open` uses the margin when called from the player route and keeps today's dialog / sheet elsewhere.
- **Keep:** lookup requests, caching, the auth gate, language rules (ADR-0042 / ADR-0087), add-to-vocabulary, and credits.
- **Tests:**
  - margin mode per width;
  - a drawer opened over video parks the surface (route present);
  - `Esc` closes;
  - lookup sections render in the margin;
  - the non-player caller still gets a dialog.
- **Docs:** [dictionary-lookup.md](../../features/dictionary-lookup.md), [player.md](../../features/player.md) (overlays).

#### D3.8 Assessment in the margin + feedback on the words
- **Boards:** `DScored`, `PScored`.
- **Code:** `assessment_result_dialog.dart`, `assessment_result_sheet.dart`, `assessment_result_body.dart`, `assessment_result_widgets.dart`, `recording_assessment_flow.dart`, `score_level.dart`.
- **Change:**
  - **Take panel:**
    - `TAKE 3 · ASSESSMENT`;
    - a big Literata score with the level word (Excellent / Good / Fair / Poor, new ARB strings) and a 4-step meter;
    - ink bars for accuracy, fluency, completeness, and prosody;
    - Play my recording · Re-assess.
  - **Pronunciation analysis:** word cards with error type and score, phoneme chips, and "Play my recording of this word"; a missing-break card.
  - **On the words:** mispronounced words get a wavy `you` underline in the loop line; missing breaks get a `you` pause mark. Tapping either opens its card.
  - On the player, `recording_assessment_flow.dart` opens the margin instead of the dialog. No score colors anywhere.
- **Keep:** thresholds (`score_level.dart`), assessment requests, re-assess cost, and error messages.
- **Tests:** level words per threshold; no score-color tokens used; the word underline maps to error types; the flow opens the margin on the player.
- **Docs:** [shadow-reading.md](../../features/shadow-reading.md).

#### D3.9 Hide text as word shapes
- **Boards:** `DHide`, `PHide`.
- **Code:** `lib/features/transcript/presentation/transcript_blur_text.dart`, `transcript_line_tile.dart`.
- **Change:**
  - Each hidden word is a rounded `shape` bar sized from the line's `TextPainter` word boxes.
  - Hint pill: `Text hidden · press and hold a line to peek` (phone) / `hover to peek` (desktop).
  - The dock's Hide text toggle is ink-filled when on.
- **Keep:** the reveal rules (hover / press-and-hold, active line), `H`, and semantics (`transcriptBlurSemanticsOn` / `Off`).
- **Tests:** shapes replace text when on; peek reveals; semantics unchanged.
- **Perf:** no `ImageFilter`. Word boxes are computed once per line layout.
- **Docs:** [transcript.md](../../features/transcript.md).

#### D3.10 Subtitles & display popover
- **Boards:** `DSubtitles` (wide); phone uses a sheet in the same style.
- **Code:** `subtitle_track_picker_sheet.dart` (and its `_sections` / `_tiles` / `_actions` / `_primitives`), `transcript_display_settings_sheet.dart`, `widgets/transport/transport_cc_fullscreen.dart`.
- **Change:**
  - **Wide:** an anchored popover under the top-bar Subtitles button. It is a `PopupRoute`, so it parks the surface.
  - **Contents:**
    - Primary and Translation track rows;
    - Display switches (on-track `original`): Highlight current word, Show pronunciation (IPA), Hide transcript text;
    - the enrichment progress card with Cancel generation;
    - actions: Import subtitle file…, Extract embedded subtitles, Re-generate transcript, Refresh transcripts from cloud.
  - Every label already exists in the ARB files.
- **Keep:** track selection, auto-translate, enrichment, import, extract, regenerate, and refresh behavior; the ADR-0065 / ADR-0066 parking.
- **Tests:** existing picker tests updated; the popover opens from the top bar; every action is reachable.
- **Docs:** [transcript.md](../../features/transcript.md) (CC sheet section).

#### D3.11 Player states
- **Boards:** `DEmpty`, `DGenerating`, `DLocate`.
- **Code:** `lib/features/transcript/presentation/transcript_empty_state.dart`, `lib/features/asr/presentation/`, `lib/features/player/presentation/locate_media_screen.dart`, `expanded_player_widgets.dart` (loading / error bodies), `transcript_busy_action.dart`, `transcript_embedded_extract.dart`.
- **Change:**
  - Empty: three option rows (AI transcript, Extract embedded subtitles, Add subtitle).
  - Generating: progress card with steps (Audio extracted · Uploading · Transcribing).
  - Locate: file row with the expected size and an ink-filled `Choose file`.
  - The dock stays, with Echo and Hide text disabled while there is no transcript.
- **Keep:** ASR pipeline steps and failure reasons ([asr.md](../../features/asr.md)) and the locate hash check.
- **Tests:** existing empty / ASR / locate tests updated; onboarding tip anchor on the empty state.
- **Docs:** [asr.md](../../features/asr.md) only if presentation is described.

#### D3.12 Share poster
- **Boards:** `Poster`.
- **Code:** `lib/features/share_poster/presentation/` (`practice_poster_preview_sheet.dart` etc.).
- **Change:**
  - A 9:16 poster: dark ground, logo planes, the `SHADOW READING` overline, the media title, a Literata quote, your pitch line, the stats (takes, sentences, time spoken), and the QR row.
  - The sheet has Share poster (brand), Save image, and Close.
  - Retire Playfair when nothing else uses it; update `_bundledVariants`.
- **Keep:** poster content rules and export ([share-poster.md](../../features/share-poster.md)).
- **Tests:** existing poster tests.
- **Docs:** [share-poster.md](../../features/share-poster.md).

#### D3.13 Player pass: dark, compact, video, phone
- **Boards:** `DDark`, `DYoutubeDark`, `DCompact`, `DVideo`, `PVideo`, `PVideoEcho`, `PDark`.
- **Change:** fix what earlier tasks left off-board in dark mode, at 880 × 560, in fullscreen video, and on phone video Echo.
- **Tests:** gallery scenes for all player boards; a manual Windows run of a YouTube item with the drawer and popover open.

### Phase 4 — App screens

Every task restyles the screen to its boards with the Phase 1 primitives, keeps every action, and updates that screen's widget tests and gallery scenes.

| ID | Screen(s) | Boards | Code | Notes |
|---|---|---|---|---|
| D4.1 | Home | `Home`, `HomeImport`, `HomeFirstRun`, `HomeDark`, `PhHome`, `PhHomeDark` | `library/presentation/home_screen.dart`, `todays_goal_card.dart`, `library/presentation/widgets/`, `community/presentation/` | Continue card with a cover and play overlay; goal ring (logo gradient); Community figures; Import chooser popover (`library_actions.dart`); onboarding tip on Import. |
| D4.2 | Discover | `Discover`, `DiscoverChannel`, `DiscoverManage`, `PhDiscover` | `discover/presentation/` (`discover_screen.dart`, `channel_feed_screen.dart`, `discover_manage_channels.dart`) | Channel strip; feed tiles with In-library chip; Manage channels dialog. |
| D4.3 | Library | `Library`, `LibraryAudio`, `LibraryCloud`, `LibraryDelete`, `LibraryImporting`, `PhLibrary` | `library/presentation/library_screen.dart` and widgets, `cloud/presentation/` | Local/Cloud capsule; Video/Audio segmented control; search with `/`; delete confirm (`danger`); importing dialog. |
| D4.4 | Vocabulary | `Vocabulary`, `VocabularyReview`, `PhVocabulary` | `vocabulary/presentation/vocabulary_screen.dart`, `vocabulary_word_list.dart`, `vocabulary_review_options.dart`, `widgets/` | Due card with logo mark; status bar in `vocabStatus` (4 indigo steps); review options radios (`brandInk`); Export to Anki (Pro). |
| D4.5 | Review session | `Review`, `ReviewBack`, `ReviewDone`, `PhReview` | `vocabulary_review_session_screen.dart`, `vocabulary_flashcard.dart`, `widgets/vocabulary_rating_bar.dart` | Rating buttons are uncolored, with bar glyphs and key hints; Context / Dictionary / Notes tabs; Play clip / Echo reading / Open in player. |
| D4.6 | Craft | `Craft`, `CraftRewrite`, `CraftAudio`, `CraftAdvanced`, `CraftHistory`, `PhCraft` | `craft/presentation/` (`craft_screen.dart`, `capture_stage.dart`, `rewrite_stage.dart`, `audio_stage.dart`, `advanced_tools.dart`, `translate_tool.dart`, `synthesize_tool.dart`, `style_picker.dart`, `voice_picker.dart`, `craft_history_screen.dart`, `widgets/craft_failure_card.dart`) | 1080 width; step header; record orb in `you`; style chips (pressed = ink); failure card in `danger` without score colors. |
| D4.7 | Sign-in | `SignIn`, `SignInCode`, `PhSignIn` | `auth/presentation/sign_in_screen.dart` | Dark art panel with the large logo and Literata tagline; provider buttons (Google secondary, Apple ink, Email secondary); 6-digit code. Then delete `AuroraGlow` (D1.8). |
| D4.8 | Profile | `Profile`, `ProfileEdit`, `ProfilePrefs`, `PhProfile` | `auth/presentation/profile_screen.dart`, `profile_edit_screen.dart`, `profile_preferences_screen.dart`, `widgets/profile_content.dart` | Hero card; practice stats; credits meter; grouped rows. |
| D4.9 | Subscription + Credits | `Subscription`, `SubscriptionPlans`, `Credits` | `subscription/presentation/`, `credits/presentation/credits_usage_screen.dart` | Plan cards with the amount and unit split; auto-renew sheet; credits table with neutral Allowed and ink Denied chips. |
| D4.10 | Settings family | `Settings`, `SettingsAbout`, `SettingsDark`, `Sync`, `Keyboard`, `KeyboardCheatsheet`, `AiProviders`, `PhSettings` | `settings/presentation/` (`settings_screen.dart`, `sync_status_screen.dart`, `hotkeys_settings_screen.dart`, `widgets/`), `hotkeys/presentation/hotkeys_help_dialog.dart`, `ai/presentation/settings/ai_providers_screen.dart`, `update/presentation/update_prompt_dialog.dart` | Two-pane rail ≥ 900, grouped list below; About + update dialog; shortcuts list and `?` cheatsheet; AI provider cards. |
| D4.11 | Surfaces not drawn | `System` only | `ai/presentation/ai_playground_screen.dart`, `player/presentation/youtube_login_screen.dart`, vocabulary clip practice / echo-reading overlay, language picker sheets, speed sheet, YouTube-URL import dialog, `transcript/presentation/import_subtitle_language_dialog.dart`, the other onboarding tips | Apply the system with no new layouts: Literata titles, Phase 1 primitives, sheet and dialog styles. List each surface in the PR. |

**Docs for Phase 4:** the `app-ui.md` screen registry (one row per screen). Update [library.md](../../features/library.md), [discover.md](../../features/discover.md), [vocabulary.md](../../features/vocabulary.md), [craft.md](../../features/craft.md), [auth.md](../../features/auth.md), [subscription.md](../../features/subscription.md), [credits-usage.md](../../features/credits-usage.md), [settings.md](../../features/settings.md), and [onboarding.md](../../features/onboarding.md) only where they describe presentation.

### Phase 5 — Cleanup, proof, merge

#### D5.1 Rename pass + delete Aurora
- **Change:**
  - Rename the remaining Aurora token names at call sites to the final names in the [alias table](#tokens-alias-then-migrate-then-delete).
  - Delete the aliases, the Aurora-only tokens, and the `AppColors` Aurora constants.
  - Delete `GlassSurface`, `AuroraGlow`, `PlayerAmbientBackdrop`, and the old cover painter if any is left.
  - Delete unused font files and their `_bundledVariants` entries.
- **Tests:** compile-only churn; the full suite stays green.

#### D5.2 Design-language invariants
- **Change:** rename `test/core/theme/aurora_design_language_test.dart` to `duet_design_language_test.dart`. Keep its scans (no `InkWell`, no Material `Icons`, mono through `enjoyMonoStyle`, no hard-coded colors outside `lib/core/theme/`, no `print()`). Add:
  - no `BackdropFilter` / `ImageFilter.blur` under `lib/features/player`, `lib/features/transcript`, or `lib/features/shadow_reading`;
  - no reference to deleted Aurora names;
  - `GoogleFonts` used only in `typography.dart`.

#### D5.3 Docs
- **Change:**
  - Rewrite `docs/features/app-ui.md` as "App UI — Duet design system".
  - Check every feature doc touched in Phases 1–4.
  - Mark ADR-0091 consequences done.
  - Note that the store screenshots in `assets/store/` need a re-shoot (a release task, not this branch).

#### D5.4 Performance evidence
- **Change:** collect the evidence for every [goal](#performance-goals) in profile mode (Windows and one phone), and attach it to the merge PR. Extend [perf-measurement.md](../../perf-measurement.md) if a new pattern was added.

#### D5.5 Platform QA
Run the manual matrix on Windows, macOS, Linux, Android, and iOS. Check each item:

| Check | What to try |
|---|---|
| Window size | Minimum window 880 × 560 |
| Theme | Light / dark / system |
| Language | CJK UI (zh, zh_CN) |
| Accessibility | Reduced motion; keyboard-only through the player; screen-reader labels on the dock and margin |
| Video surfaces | YouTube with the drawer, the popover, and the sheet open (Windows WebView2) |
| Video playback | Local video fullscreen |
| Phone | Portrait only |

Record the results in `STATUS.md` Notes.

#### D5.6 Merge
- **Status:** prepared, awaiting D5.4/D5.5 human verification. From a clean checkout: `git checkout design-duet && git merge main` (weekly merges already kept it current), re-run `bash .github/scripts/validate_ci_gates.sh --all`, then open the PR `design-duet → main` with release notes "New look: Duet — no behavior changes."
- **Change:**
  - Merge `main` into `design-duet` one last time and re-run every gate.
  - Open the PR `design-duet → main`.
  - Release notes: "New look: Duet" and no behavior changes.
  - Archive this plan: set its status to done; keep it for history.

---

## Performance goals

| Flow | Goal | Evidence |
|---|---|---|
| Transcript scroll | 60 fps on desktop and a mid phone, 1,000-line transcript, profile mode | DevTools frame chart; Pattern 4 stress test on the new row |
| Listen ↔ Echo | ≤ `motionLens` 280 ms; only visible rows animate; no list rebuild per frame | Rebuild-count test on rows outside the viewport |
| Playback ticks | Position updates repaint only the ruler, time labels, and the active line | Rebuild / emission count (Pattern 2) on the dock |
| Hide text | No `ImageFilter` in the player; word boxes computed once per layout | Invariant scan (D5.2) + tile test |
| Covers | Deterministic paint cached per (id, size); no work in grid builders | Painter `shouldRepaint` test |
| Startup | No runtime font fetch; bundle growth ≈ 0.5 MB (Literata ×3 + two semibolds) | `bundled_google_fonts_test.dart`; release size diff |
| Margin | Docked open/close ≤ 220 ms, with no surface flash on video | Manual on Windows / macOS with local video and YouTube |

---

## Verification

Every task runs these before push:

```bash
bash .github/scripts/validate_ci_gates.sh        # format + codegen drift (+ --fix)
flutter analyze
flutter test
git diff --stat origin/design-duet...HEAD -- ':(glob)lib/**/application/**' ':(glob)lib/**/domain/**' ':(glob)lib/data/**' \
  ':(glob)test/**/application/**' ':(glob)test/**/domain/**' ':(glob)test/data/**' docs/features/hotkeys.md
```

Visual check, after D0.2:

```bash
flutter test --tags gallery --run-skipped test/duet_gallery
bash tool/duet_compare.sh Main DEcho        # → build/duet_gallery/compare/*.png
```

Platform compile smoke tests run when a task touches platform-sensitive code (video surfaces, WebView, window): `flutter build windows|macos|linux --debug`, and an Android / iOS debug build when phone layouts change.

---

## Documentation map

| Doc | Changes in |
|---|---|
| [app-ui.md](../../features/app-ui.md) | D1.x (tokens, type, widgets), D2.x (navigation, layout), D4.x (registry), D5.3 (rewrite) |
| [player.md](../../features/player.md) | D3.1, D3.2, D3.3, D3.7 |
| [transcript.md](../../features/transcript.md) | D3.4, D3.5, D3.9, D3.10 |
| [echo-mode.md](../../features/echo-mode.md) | D3.5 |
| [shadow-reading.md](../../features/shadow-reading.md) | D3.6, D3.8 |
| [dictionary-lookup.md](../../features/dictionary-lookup.md) | D3.7 |
| [share-poster.md](../../features/share-poster.md) | D3.12 |
| [testing.md](../../testing.md) | D0.2 |
| Screen feature docs | D4.x, where they describe presentation |
| [hotkeys.md](../../features/hotkeys.md) | never; hotkeys are frozen |
| `docs/design/duet/` | when the design changes: re-render (`tool/render_design_boards.mjs`), then tokens and parity test |

---

## Risks

| Risk | Mitigation |
|---|---|
| `design-duet` drifts from `main` | Merge `main` in weekly (merge commit; never rebase a shared branch). Behavior fixes land on `main` first and flow in. |
| A board quietly changes behavior | Rule 1, the freeze check, and the `needs decision` status. Known cases are in [STATUS → Decisions](STATUS.md#decisions). |
| Video surface paints over new panels (Windows) | Rule 4: routes or layout siblings only; D3.13 / D5.5 manual checks. |
| Widget tests churn hides regressions | Behavior tests are frozen. Widget-test edits are limited to finders and visuals; every removed assertion gets a replacement in the PR. |
| Parallel agents collide on shared primitives | Phase 1 lands before screens start. Changes to a primitive after Phase 1 get their own small PR. |
| Token drift between design and code | `duet_tokens_test.dart` pins `tokens.json`. |
| Missing translations | Every new key in en, zh, and zh_CN in the same PR; `tool/untranslated_messages.json` must not grow. |
