# Duet — design reference

**Status**: Being implemented on the `design-duet` branch. Decision: [ADR-0093](../../decisions/0093-duet-design-language.md), which replaces the unreleased Aurora look of [ADR-0089](../../decisions/0089-aurora-design-language.md).

**Plan**: [PLAN.md](PLAN.md) has the phases, tasks, rules and verification. **Tracker**: [STATUS.md](STATUS.md) shows task status, open decisions, and which task owns each board.

**This folder is self-contained.** Everything needed to build the design is here: a rendered image of every board, the board sources with exact values, and the tokens. The design was drawn on a private canvas (<https://claude.ai/artifact/WZWHs6XNPFoAYWeVR5Sqo1>); that is only needed to *change* the design, never to implement it.

**Rule for the refactor**: UI/UX only. No feature, behavior, or hotkey changes. The Echo loop keeps today's pause-and-rewind at the loop end; it never auto-repeats.

## What is in this folder

| Path | Contents |
|------|----------|
| `renders/<Board>.webp` | What each board looks like, rendered at its frame size (desktop 1440 × 900 at 1×, phone 390 × 844 at 2×). Lossless WebP; open it like any image. |
| `renders/<Board>.full.webp` | Full-length renders of app pages that scroll past the frame (Home, Library · Cloud, Vocabulary, Subscription, Credits, Keyboard shortcuts, and the phone Home, Discover, Library, Vocabulary, Profile). Player boards have no full-length render: the transcript scrolls by design, centred on the active line. |
| `boards/*.dc.html` | Source of every board: exact colors, sizes, spacing, copy, and states as HTML + inline CSS. The `<script data-dc-script>` block at the end of each file holds the board's sample data and, for `Main` and `Phone`, the prototype's interaction logic. The files need the canvas runtime to display, so read them as text and look at `renders/` for the picture. `/_blob/747775ae97e736fcc52ae3074fe11fa4` inside them is [`assets/logo-light.svg`](../../../assets/logo-light.svg). |
| `boards/canvas.json` | Board index: page, title, and frame size of every board. |
| `tokens.json` | Design tokens: light/dark colors, gradients, opacity steps, type scale, radii, sizes, breakpoints, shadows, motion, generated-cover recipe. |
| `PLAN.md`, `STATUS.md` | Implementation plan and its tracker. |

## Implementing from this folder

1. **Behavior comes from the code and [`docs/features/`](../../features/), never from a board.** The refactor changes how screens look and are laid out, not what they do. If a board seems to add, drop, or change a feature, hotkey, or rule, the board is wrong; keep today's behavior and flag it.
2. **Look at the render, then read the source.** `renders/<Board>.webp` shows the target; `boards/<Board>.dc.html` gives the exact pixel values. State boards (`DEcho`, `PScored`, `SettingsDark`, …) are thin wrappers: `<dc-import name="Main" mode="echo" …>` means "the `Main` board with these props", so their markup lives in the imported file.
3. **Take values from [`tokens.json`](tokens.json) first.** A value that appears only in a board's CSS is a one-off; promote it to a token only if a second place needs it. Colors in the boards are CSS variables set by a light and a dark class at the top of each `<style>` (`.e-light` / `.e-dark`; `Main` uses `.dt-*`, `Phone` `.ph-*`, `Sidebar` `.sb-*`, `TabBar` `.tb-*`). Their names are the `tokens.json` names in kebab-case (`--you-ink` = `youInk`, `--shadow` = `shadow.float`), except `--blue`, `--blue-ink`, `--blue-soft`, which are `original`, `originalInk`, `originalSoft`.
4. **Everything shown is sample data.** Alex Chen, *The Ferry at Six*, counts, dates, scores, and the illustrated video thumbnails are placeholders.
5. **Where the board and Flutter disagree on mechanics** (e.g. hover on touch devices, platform menus), keep the board's look and the platform's behavior.

## The language in one screen

- **Two voices.** Blue (the logo's start, `original`) is the original speaker: playback, the spoken word, reference pitch, Listen. Violet (the logo's end, `you`) is the learner: the Echo loop, Record, takes, your pitch, notes on a take. The brand gradient between them is Enjoy itself (logo, Play, primary buttons, goal ring, Pro). Everything else is ink.
- **Never by hue alone.** Blue and violet are close in hue, so the original is always the translucent layer and you the solid one (pitch band vs line, soft vs filled buttons) and they keep a ~1.9:1 lightness gap in both themes.
- **Modes are lenses.** Listen reads like a book; Echo grows the loop line in place and fades the rest through the logo's opacity steps (1 / 0.65 / 0.35 / 0.2). One transcript, no screen change.
- **Controls below, context beside.** Every player control lives in the dock. The side margin (340 px) opens only for a word lookup or a take's assessment; under 1100 px it is a drawer, on phones a bottom sheet. It replaces today's lookup dialog and assessment dialog.
- **Feedback on the words.** Mispronounced words get a wavy violet underline, a missing pause gets a violet pause mark, the recording countdown fills along the words. Scores are never colored: a number plus a four-step meter.
- **Danger is for failures, not for business states.** Red (`danger` / the Material `error` scheme) is reserved for real faults — a request that failed and needs a retry. Recoverable product states — credits exhausted, network flaking, sync pending — read as neutral content (sunk surface, ink text) with exactly **one** primary CTA into the fix (usually plans & packages, `/subscription`); never a red box, and never the same CTA repeated per section. A pre-failure threshold (today's credits ≥ 90% used) may tint the number `danger` to draw the eye (profile meter, lookup credits chip), but the surrounding surface stays calm.
- **Scores**: Excellent ≥ 91 · Good ≥ 81 · Fair ≥ 61 · Poor below (same thresholds as `score_level.dart`).

## Board → code map

Every screen board is one responsive file; the sidebar (≥ 900 px) becomes the bottom tab bar below 900 px, and the `Ph*` boards are the same files at 390 px.

### Shell

| Board | Replaces / maps to |
|-------|--------------------|
| [`Sidebar`](renders/Sidebar.webp) | `AppSidebar` + `SidebarAccountChip` (adds Vocabulary and Craft rows) |
| [`TabBar`](renders/TabBar.webp) | `EnjoyBottomNav` (Home, Discover, Library, Profile — unchanged) |

### Player (`/player/:mediaId`)

| Board | State |
|-------|-------|
| [`Main`](renders/Main.webp) | Listen, audio — interactive prototype (play, click a word, Echo, record, score) |
| [`DEcho`](renders/DEcho.webp) | Echo idle, IPA on |
| [`DRecording`](renders/DRecording.webp) | Recording a take (countdown on the words, Cancel / Stop in the dock) |
| [`DScored`](renders/DScored.webp) | Scored take: notes on words, pitch duet, assessment margin |
| [`DWord`](renders/DWord.webp) | Word lookup in the margin (replaces the `LookupCoordinator` dialog on wide windows) |
| [`DHide`](renders/DHide.webp) | Hide text (Blur practice, `H`) drawn as word shapes; hover / press-and-hold peeks |
| [`DSubtitles`](renders/DSubtitles.webp) | Subtitles & display popover (replaces the CC sheet on wide windows), word timings generating |
| [`DCompact`](renders/DCompact.webp) | 880 × 560 minimum window; margin as drawer |
| [`DVideo`](renders/DVideo.webp), [`DYoutubeDark`](renders/DYoutubeDark.webp), [`DDark`](renders/DDark.webp) | Video side-by-side, YouTube chips, dark mode |
| [`DEmpty`](renders/DEmpty.webp), [`DGenerating`](renders/DGenerating.webp), [`DLocate`](renders/DLocate.webp) | No transcript, AI transcript in progress, Locate media file |
| [`Phone`](renders/Phone.webp), [`PEcho`](renders/PEcho.webp), [`PRecording`](renders/PRecording.webp), [`PScored`](renders/PScored.webp), [`PWord`](renders/PWord.webp), [`PHide`](renders/PHide.webp), [`PVideo`](renders/PVideo.webp), [`PVideoEcho`](renders/PVideoEcho.webp), [`PDark`](renders/PDark.webp) | Phone player (portrait only, ADR-0059) |

### App

| Board | Route |
|-------|-------|
| [`Home`](renders/Home.webp), [`HomeImport`](renders/HomeImport.webp), [`HomeFirstRun`](renders/HomeFirstRun.webp), [`HomeDark`](renders/HomeDark.webp) | `/` — Continue practicing, Today's Goal, Community, Recent media; Import chooser; first-run onboarding tip |
| [`Discover`](renders/Discover.webp), [`DiscoverChannel`](renders/DiscoverChannel.webp), [`DiscoverManage`](renders/DiscoverManage.webp) | `/discover`, `/discover/channel/:channelId`, Manage channels |
| [`Library`](renders/Library.webp), [`LibraryAudio`](renders/LibraryAudio.webp), [`LibraryCloud`](renders/LibraryCloud.webp), [`LibraryDelete`](renders/LibraryDelete.webp), [`LibraryImporting`](renders/LibraryImporting.webp) | `/library`, `?source=cloud`, delete confirm, importing dialog |
| [`Vocabulary`](renders/Vocabulary.webp), [`VocabularyReview`](renders/VocabularyReview.webp) | `/vocabulary` (All Words, Review options) |
| [`Review`](renders/Review.webp), [`ReviewBack`](renders/ReviewBack.webp), [`ReviewDone`](renders/ReviewDone.webp) | `/vocabulary/review` (front, back with context, complete) |
| [`Craft`](renders/Craft.webp), [`CraftRewrite`](renders/CraftRewrite.webp), [`CraftAudio`](renders/CraftAudio.webp), [`CraftAdvanced`](renders/CraftAdvanced.webp), [`CraftHistory`](renders/CraftHistory.webp) | `/craft` (Express capture → rewrite → audio; Advanced), `/craft/history` |
| [`SignIn`](renders/SignIn.webp), [`SignInCode`](renders/SignInCode.webp) | `/sign-in`, `/sign-in/email` |
| [`Profile`](renders/Profile.webp), [`ProfileEdit`](renders/ProfileEdit.webp), [`ProfilePrefs`](renders/ProfilePrefs.webp) | `/profile`, `/profile/edit`, `/profile/preferences` |
| [`Subscription`](renders/Subscription.webp), [`SubscriptionPlans`](renders/SubscriptionPlans.webp) | `/subscription`, auto-renew plan sheet |
| [`Credits`](renders/Credits.webp) | `/credits` |
| [`Settings`](renders/Settings.webp), [`SettingsAbout`](renders/SettingsAbout.webp), [`SettingsDark`](renders/SettingsDark.webp) | `/settings` (two-pane rail ≥ 900 px, grouped list below), About with update dialog |
| [`Sync`](renders/Sync.webp), [`Keyboard`](renders/Keyboard.webp), [`KeyboardCheatsheet`](renders/KeyboardCheatsheet.webp), [`AiProviders`](renders/AiProviders.webp) | `/settings/sync`, `/settings/keyboard`, shortcuts cheatsheet (`?`), `/settings/ai-providers` |
| [`Poster`](renders/Poster.webp), [`NotFound`](renders/NotFound.webp) | Share practice poster sheet, router `errorBuilder` |
| [`PhSignIn`](renders/PhSignIn.webp) … [`PhSettings`](renders/PhSettings.webp) | Phone renders of the screens above |
| [`System`](renders/System.webp) | The design language board |

## Token mapping from Aurora

The step-by-step migration (interim values, final names, deletions) is in [PLAN.md → Tokens](PLAN.md#tokens-alias-then-migrate-then-delete).

| Aurora (`EnjoyThemeTokens` / `AppColors`) | Duet token |
|---|---|
| page (`cs.surface`), `canvas` | `ground` (sidebar and pages share it; no floating content panel) |
| `card` | `paper` |
| `popover` | `raised` |
| `fill` | `sunk` |
| `hairline` | `line` |
| `textFaint` | `ink3` |
| iris accent fill / `accentInk` / `accentSoft` | `brand` gradient / `brandInk` / `brandSoft` |
| `aurora` gradient | `logo` gradient |
| `echoActive` / `echoInk` (coral) | `you` / `youInk` |
| `intelligenceInk` | `brandInk` |
| `blurActive` (teal) | removed — Hide text uses ink |
| `scoreGood` / `scoreWarn` / `scoreBad` | removed from scores (ink number + four-step meter); non-score error uses of `scoreBad` become `danger` |
| `AuroraGlow`, `GlassSurface` transport capsule, `PlayerAmbientBackdrop` | removed — flat surfaces; the dock is a solid `paper` bar |

## Fonts

All weights the design uses are bundled in [`assets/fonts/google_fonts/`](../../../assets/fonts/google_fonts/) in the `google_fonts` asset layout, byte-identical to the files `google_fonts` 8.2.0 would fetch (SHA-256 verified), so `GoogleFonts.config.allowRuntimeFetching = false` keeps working:

| Family | Weights | Files |
|--------|---------|-------|
| Literata (content, page titles, big numbers) | 400, 500, 600 | `Literata-Regular.ttf`, `Literata-Medium.ttf`, `Literata-SemiBold.ttf` (new), `OFL-literata.txt` |
| Geist (interface) | 400, 500, 600 | `Geist-Regular.ttf`, `Geist-Medium.ttf`, `Geist-SemiBold.ttf` (new) |
| Geist Mono (time, scores, keys, IDs) | 500, 600 | `GeistMono-Medium.ttf`, `GeistMono-SemiBold.ttf` (new) |
| Noto Sans (IPA) | 400 | `NotoSans-Regular.ttf` |

When the theme starts requesting a new variant, add it to `_bundledVariants` in `test/core/theme/bundled_google_fonts_test.dart`. Instrument Serif and Source Serif 4 stay bundled until the code stops requesting them; then delete the files and their test entries. Playfair Display stays only if the share poster keeps it (the Duet poster uses Literata).

The static Literata files carry the default optical size. The canvas uses Literata's `opsz` axis for display sizes; if that matters on device, bundle the variable font and pass `FontVariation('opsz', size)` instead.

## Icons and imagery

- Icons stay **Phosphor** (`EnjoyIcons`); the boards' inline SVGs are stand-ins with the same stroke weight. Outline at rest, fill when selected.
- The play glyph everywhere is the logo's rounded triangle.
- Media without artwork gets the generated cover in `tokens.json → generatedCover` (it replaces today's generative cover painter). The illustrated video thumbnails on the boards (talk, city, harbour, hills, cup, street) are placeholders for real thumbnails and are **not** shipped.
- Empty states use the logo's three triangles at low opacity; the sign-in art is the logo at large scale.

## Decisions

Accepted in [ADR-0093](../../decisions/0093-duet-design-language.md):

1. Violet replaces coral for "you"; scores lose their colors.
2. Literata replaces Source Serif 4 (transcript) and Instrument Serif (display). The transcript stays serif; today's `useSerif: true` has no user-facing switch, and the design adds none.
3. Hide text renders as word shapes instead of a Gaussian blur, with the same reveal rules; they are cheaper to paint.

Open, tracked in [STATUS.md → Decisions](STATUS.md#decisions): the Listen dock's Repeat button (R1), and the desktop sidebar's new Vocabulary, Craft and Settings rows plus the sync line (S1).

## Re-rendering

When the design changes on the canvas, refresh this folder in one go so renders never drift from sources:

1. Download the canvas's `project/*.dc.html` and `project/canvas.json` into `boards/`.
2. Download the canvas runtime, `artifact-type/dc-runtime.js` from the same canvas. It belongs to the canvas tool, not to this repo, so it is never committed; keep it outside the tree.
3. Run `node tool/render_design_boards.mjs <path/to/dc-runtime.js>` from the repo root (Node 22+, Chrome or Chromium — set `CHROME=` if it is not on `PATH` — and ImageMagick with WebP). It serves `boards/` locally, renders every board in `canvas.json` order into `renders/`, and adds the full-length renders. Pass board names after the runtime path to re-render only those.
4. Update `tokens.json` and the tables above if a token or a board changed.

New boards that scroll past their frame and need a full-length render go into `fullLength` in the script.

## Not drawn yet

AI playground (developer builds), YouTube sign-in web view, vocabulary clip practice and echo-reading overlay, language picker sheets, playback speed sheet, YouTube-URL import dialog, subtitle-import language dialog, the onboarding tips other than Home → Import, and the phone renders of the Subscription and Credits screens (`PhSubscription` / `PhCredits` — the 2026-10-09 phone review, issue #870 §1.5, had to judge `/subscription` against the desktop `Subscription` board for this reason).
