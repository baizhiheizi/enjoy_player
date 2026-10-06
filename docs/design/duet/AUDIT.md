# Duet — implementation audit (2026-10-06)

[STATUS.md](STATUS.md) reports 40 of 44 tasks done. A side-by-side walkthrough of the app against the boards shows that most screens still have the pre-Duet layout and information architecture. They picked up the Duet tokens (ground, fonts, buttons) but were never rebuilt to the boards. This file records the evidence, the root causes, and the plan to close the gaps.

## How this was checked

- `flutter test --tags gallery --run-skipped test/duet_gallery` shoots each scene, then `tool/duet_compare.sh` puts the board render (left) beside the app (right) in `build/duet_gallery/compare/`.
- New: `test/duet_gallery/audit_scenes_test.dart` adds Discover, Craft history, Sync, Keyboard, AI providers, Profile (+ edit, preferences), Credits, Subscription, Vocabulary at 1440 × 900, and the phone Home, Library, Discover, Vocabulary, Profile, Settings at 390 × 844.
- The gallery now runs desktop frames on a desktop target platform and puts the player transcript inside `AudioPlayerLayout`. Before this, every frame rendered with the phone layout.
- Each gap below is marked **code** (the screen differs from the board) or **fixture** (the harness data was too thin to show the screen, so the comparison is inconclusive).

## Root causes

1. **Tasks were closed on primitives, not screens.** Most Phase 4 rows say "board deltas were covered by D1/D2 primitives" and "gallery verified". The primitives changed the colors and fonts, but the layouts stayed as they were.
2. **Phase 4 closed on unfinished foundations.** D1.2 (color scheme + component themes), D1.5 (controls) and D1.6 (surfaces) are still `todo`, yet every Phase 4 task that depends on them is marked `done`. Material date fields, dropdowns, and spinners still show up on Duet screens.
3. **The gallery could not show the gaps.**
   - It had 4 screens.
   - The player scene mounted only `TranscriptPanel`, with no top bar.
   - Every frame rendered with the phone layout.
   - Fixtures stub out the data the boards draw: the continue-practice entry, library rows, translations, IPA, takes, and the credit log.
   - No phone screen was ever captured.
4. **The renders are stale.** `renders/*.webp` predate the canvas density revision of `Main` and `Phone` (D3.14), so even an accurate comparison would be against the old design.

## Gaps

### Systemic (every screen)

| # | Gap | Board | App |
|---|---|---|---|
| S1 | Icon tiles | Neutral `sunk` tile, ink icon ("everything else is ink") | Multi-hue tiles: orange, teal, blue, violet, amber, red (Profile, Settings, phone Settings) |
| S2 | Page header | Overline (`ON THIS DEVICE`, `YOUR WORD BOOK`, `YOUTUBE CHANNELS YOU FOLLOW`) + Literata title + right-aligned actions on one row | Title only, actions float right, no overline; Settings adds a subtitle the board doesn't have |
| S3 | Material controls leak through | Paper pill filters, inline date pills, keycaps | Material `TextField` date pickers, `DropdownButton`, `CircularProgressIndicator` (Credits, Subscription) — this is D1.2 / D1.5 still being `todo` |
| S4 | Sidebar | Placeholder "Search library"; account chip with **Upgrade** pill on Free | "Search"; chip with chevron, no Upgrade |
| S5 | Destructive / sign-out | Ghost `Sign out` button | Red text + icon link, centered |

### Screens

| Screen | Kind | Gaps |
|---|---|---|
| **Home** (`Home`, `PhHome`) | **code** | **Continue practicing is missing**: `continuePracticeResumeProvider` exists but nothing in `lib/` uses it. D2.1 deleted `SidebarContinuePracticeCard` on the promise that Home keeps it, and Home never got it, so the entry point was lost. Layout: hero card (cover + quote + Continue) beside a stacked Goal / Community column; the app has two equal cards in a row. Goal ring reads `12 of 15 min` + "Almost there"; the app shows a percentage. Media tile meta is `Audio · today`; the app shows a language icon + `English • Video`. Craft is a labeled secondary button, not an icon. |
| **Library** (`Library`, `PhLibrary`) | code + fixture | Local / Cloud as a **capsule segmented control** next to the title (app: a `Local ⌃` dropdown); Video / Audio segments carry counts; a search field sits right of the segments (missing); tiles show title + language badge + `Opened Sep 29`. The grid itself was empty in the fixture. |
| **Discover** | code + fixture | Overline + header actions **All languages** and **Manage channels** (missing); the channel strip is avatars with labels plus a **Subscribe** tile (app: `All` chip + `+`); tiles have a channel avatar, meta, and an **Add to library** button. The feed was empty in the fixture. |
| **Vocabulary** (`Vocabulary`, `PhVocabulary`) | **code — different IA** | Board: page header + **due hero** (logo, `24 due today`, estimate) + **status card** (4-step bar, New / Learning / Reviewing / Mastered counts) + All Words / Review segmented + search + Status / Language filters + **word table** (term, IPA, context, status chip, next due, language, delete). App: subpage bar with back + Review / All Words tabs + a centered "14 Due · Start review" card. |
| **Profile** (`Profile`, `PhProfile`) | **code** | Board: hero card (avatar ring, Literata name, plan chip, `Enjoy ID` in mono with copy, **Edit profile** / **Upgrade to Pro** buttons) + Practice and Credits-today cards side by side + one neutral list (Vocabulary, Subscription, Credits usage, Preferences, Edit profile, Settings) + ghost Sign out. App: gradient hero with a chevron, a stats strip, multi-hue tiles split across three cards, red Sign out link. |
| **Subscription** | **code** | Board: summary strip (Current plan / Status / Expiration / Daily credits) + "Choose your plan" with **three plan columns** (Free / Lite / Pro, feature checklists, Recommended) + Credits packages row. App: gradient "You're on Pro" card + spinners. |
| **Credits** | **code** | Board: credit packages card (three amounts + Buy) + inline filter pills (Start / End / Service / Clear) + **table** (date, time, service, tier, required, used after, status chip). App: "Filters" heading with Material date fields + a dropdown + skeleton cards. |
| **Settings** (`Settings`, `PhSettings`) | **code** | Desktop: rail with an **Account** row and neutral icons; Appearance & Language selected by default with a Literata section title, description, grouped card (Theme segmented, language rows); search right-aligned in the header. App: no Account row, full-width search, Cloud sync selected. Phone: board is a **hub** (account card + six section rows with values, drill-in, version footer); the app is one long grouped list with multi-hue tiles. |
| **Sync** | **code** | Board: hero card (last successful sync, Literata time) + two stat tiles + Sync now / Retry buttons + Queue details list with type badges (REC / VOC / VID / AUD) and status chips. App: three thin rows + full-width buttons + collapsed "Queue details". |
| **Keyboard** | **code** | Board: group header = small letter badge + sans label + count; rows with keycaps (no `+` joiner), pencil + reset icons, `Custom` chip. App: multi-hue icon tile + Literata heading, `+` between keys, different action icons, extra subtitle line. |
| ProfileEdit, ProfilePrefs, AiProviders, CraftHistory | captured, not yet reviewed | Captures are in `build/duet_gallery/compare/`. |
| Craft, SignIn, Review, NotFound, Poster, dialogs (LibraryDelete, LibraryImporting, HomeImport, SubscriptionPlans, KeyboardCheatsheet, SettingsAbout update) | not captured | Need harness work: a fake recorder for Craft, a signed-out auth fixture for SignIn, session fixtures for Review, dialog openers. |

### Player

The player scene still omits the top bar and lacks translations, IPA, and takes, so the player comparison is partial.

| Area | Kind | Gaps |
|---|---|---|
| Top bar, phone | **code** | Board: chevron · Listen / Echo segmented · CC, then a second row with the title and `Line 6 of 14`. `PlayerTopBar` has no phone variant. |
| Top bar, desktop | code | The **More (⋯)** menu was deferred in D3.1. The bar needs a real-route capture to confirm the rest. |
| Dock, Listen | code | The board has no **replay** button (the app adds ↺; it is an existing feature, so this needs a decision). Skip glyphs are **filled** (app: outline). Speed is mono `1.0×` text, not a `1x` pill. The Hide control is an eye-slash. The phone dock is **one row** (Hide · prev · play · next · speed); the app uses two rows plus a speed pill. |
| Dock frame | verify | The gallery shows an inset floating card with side margins; the board is a full-bleed paper bar with a top line. Confirm on the real route before changing it; it may come from `RootShell` in the harness. |
| Ruler | code | Practiced dots above the ticks and a loop bracket are drawn on the board; check them against the app once fixtures have takes. |
| Echo | fixture | IPA under the words, translation under the loop, and a real takes strip all need fixtures. |
| Assessment margin (D3.8) | code | Not built: no margin assessment and no wavy notes on words. The docked margin at ≥ 1100 is still deferred. Decisions R1 (Repeat) and R2 (take management) are open. |

## Plan

Each phase ends with its compare images attached to the PR. **A board's task cannot be marked `done` without its side-by-side compare.**

### Phase A — Honest verification (first)

1. **A1** Re-render the boards from the canvas (`tool/render_design_boards.mjs`, with the runtime from the canvas's `artifact-type/dc-runtime.js`) so `renders/` matches the current `Main` / `Phone`.
2. **A2** Player gallery mounts the real expanded-player body (`ExpandedPlayerChromeBody`: top bar + layout + dock), with fixtures for translation, IPA, takes with scores, and video media.
3. **A3** Fixtures that match the boards: continue-practice resume, library rows (video + audio, local + cloud), discover feed + channels, vocabulary items across all four statuses, credit log rows, a Free-plan subscription, sync queue rows.
4. **A4** Harness gaps: a fake `record` platform channel (Craft), a signed-out auth fixture (SignIn), a review session (Review / ReviewBack / ReviewDone), a dialog opener helper (HomeImport, LibraryDelete, LibraryImporting, SubscriptionPlans, KeyboardCheatsheet, update dialog), and a pushed subpage so back buttons render.
5. **A5** One gallery scene per board in the [board → task index](STATUS.md#board--task-index); `duet_compare.sh` with no arguments then covers all of them.
6. **A6** Correct STATUS.md: reopen every task whose boards fail compare — **done 2026-10-06**.

### Phase B — Finish the foundations

1. **B1** D1.2 color scheme + component themes: Material date pickers, dropdowns, and progress indicators render in Duet (paper / line / ink, brand gradient only where the board uses it).
2. **B2** D1.5 controls: a capsule segmented control with counts, filter pills (date / select / clear), a search field with a keycap, status chips, and keycaps without joiners.
3. **B3** D1.6 surfaces: one neutral `EnjoyIconTile` (sunk + ink2), deleting the multi-hue variants (S1); grouped list card; stat tile; data table (header row, mono cells, status chip); hero card.
4. **B4** Page header primitive: overline + Literata title + trailing actions (S2), adopted by every page kind.
5. **B5** Sidebar: "Search library" placeholder and the account chip with the Upgrade pill (S4); ghost Sign out (S5).

### Phase C — Rebuild screens to the boards

Ordered by user impact and gap size. Each item rebuilds layout and IA using the existing providers and actions, with no behavior changes. Anything a board seems to add or drop goes to STATUS → Decisions.

1. **C1 Home**: restore Continue practicing (regression) as the board's hero; the Goal / Community column; tile meta; the labeled Craft button. Phone order: hero → goal → community → recent.
2. **C2 Vocabulary**: due hero, status card, segmented control, filters, word table; phone list variant.
3. **C3 Library**: Local / Cloud capsule, counts, search, tile meta, Cloud and Audio states.
4. **C4 Profile**: hero card, Practice + Credits cards, one neutral list.
5. **C5 Settings**: desktop rail with Account and section pages to the board; phone hub with drill-in.
6. **C6 Discover**: header actions, channel avatar strip, tile with Add to library.
7. **C7 Subscription + Credits**: summary strip, plan columns, packages, credits table.
8. **C8 Sync, Keyboard, AI providers, Profile edit / preferences, Craft history**.
9. **C9 Remaining boards** once A4 lands: Craft, SignIn, Review, NotFound, Poster, dialogs.

### Phase D — Player

1. **D1** Phone top bar (two rows) and the desktop More menu (decide what it holds: today's top-bar overflow actions).
2. **D2** Dock to the board: filled skip glyphs, mono speed text, eye-slash Hide, single-row phone dock, full-bleed frame. The replay button needs a decision (new **R3**: the board drops it; the feature exists today).
3. **D3** Ruler practiced dots / loop bracket, verified with take fixtures.
4. **D4** D3.8 assessment margin + word notes; docked margin at ≥ 1100; resolve R1 / R2.
5. **D5** Echo with IPA, translation, and takes, verified against `DEcho`, `DRecording`, `DScored`, `PEcho`, `PRecording`, `PScored`.

### Phase E — Merge

The merge PR (#853) stays open until Phases A–D are green on compare. D5.4 / D5.5 platform QA runs on the rebuilt screens, not the current ones.

## STATUS.md corrections (applied 2026-10-06)

| Task | Current | Proposed | Why |
|---|---|---|---|
| D2.1 | done | in progress | Continue practicing was removed and never rehomed; sidebar search placeholder and Upgrade pill differ |
| D3.1, D3.2 | done | in progress | No phone top bar; dock glyphs, speed, phone layout, More menu |
| D3.13 | done | todo | Its compare excluded the top bar and ran with the phone layout |
| D4.1–D4.10 | done | todo / in progress | Screens differ from their boards in layout and IA (table above) |
| D5.1–D5.3 | done | keep | Rename / invariant / doc tasks are unaffected |
| D5.6 | review | blocked | On Phases A–D |
