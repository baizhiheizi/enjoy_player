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
| S1 ✅ | Icon tiles | Neutral `sunk` tile, ink icon ("everything else is ink") | Multi-hue tiles: orange, teal, blue, violet, amber, red (Profile, Settings, phone Settings) |
| S2 | Page header | Overline (`ON THIS DEVICE`, `YOUR WORD BOOK`, `YOUTUBE CHANNELS YOU FOLLOW`) + Literata title + right-aligned actions on one row | Title only, actions float right, no overline; Settings adds a subtitle the board doesn't have |
| S3 (inputs ✅) | Material controls leak through | Paper pill filters, inline date pills, keycaps | Material `TextField` date pickers, `DropdownButton`, `CircularProgressIndicator` (Credits, Subscription) — this is D1.2 / D1.5 still being `todo` |
| S4 ✅ | Sidebar | Placeholder "Search library" | "Search" (the Upgrade pill on Free is present — the first capture used a Pro fixture) |
| S5 ✅ | Destructive / sign-out | Ghost `Sign out` button | Red text + icon link, centered |

### Screens

| Screen | Kind | Gaps |
|---|---|---|
| **Home** (`Home`, `PhHome`) ✅ C1 | **code** | **Continue practicing is missing**: `continuePracticeResumeProvider` exists but nothing in `lib/` uses it. D2.1 deleted `SidebarContinuePracticeCard` on the promise that Home keeps it, and Home never got it, so the entry point was lost. Layout: hero card (cover + quote + Continue) beside a stacked Goal / Community column; the app has two equal cards in a row. Goal ring reads `12 of 15 min` + "Almost there"; the app shows a percentage. Media tile meta is `Audio · today`; the app shows a language icon + `English • Video`. Craft is a labeled secondary button, not an icon. |
| **Library** (`Library`, `PhLibrary`) ✅ C3 | code + fixture | Local / Cloud as a **capsule segmented control** next to the title (app: a `Local ⌃` dropdown); Video / Audio segments carry counts; a search field sits right of the segments (missing); tiles show title + language badge + `Opened Sep 29`. The grid itself was empty in the fixture. |
| **Discover** | code + fixture | Overline + header actions **All languages** and **Manage channels** (missing); the channel strip is avatars with labels plus a **Subscribe** tile (app: `All` chip + `+`); tiles have a channel avatar, meta, and an **Add to library** button. The feed was empty in the fixture. |
| **Vocabulary** (`Vocabulary`, `PhVocabulary`) ✅ C2 | **code — different IA** | Board: page header + **due hero** (logo, `24 due today`, estimate) + **status card** (4-step bar, New / Learning / Reviewing / Mastered counts) + All Words / Review segmented + search + Status / Language filters + **word table** (term, IPA, context, status chip, next due, language, delete). App: subpage bar with back + Review / All Words tabs + a centered "14 Due · Start review" card. |
| **Profile** (`Profile`, `PhProfile`) ✅ C4 | **code** | Board: hero card (avatar ring, Literata name, plan chip, `Enjoy ID` in mono with copy, **Edit profile** / **Upgrade to Pro** buttons) + Practice and Credits-today cards side by side + one neutral list (Vocabulary, Subscription, Credits usage, Preferences, Edit profile, Settings) + ghost Sign out. App: gradient hero with a chevron, a stats strip, multi-hue tiles split across three cards, red Sign out link. |
| **Subscription** | **code** | Board: summary strip (Current plan / Status / Expiration / Daily credits) + "Choose your plan" with **three plan columns** (Free / Lite / Pro, feature checklists, Recommended) + Credits packages row. App: gradient "You're on Pro" card + spinners. |
| **Credits** | **code** | Board: credit packages card (three amounts + Buy) + inline filter pills (Start / End / Service / Clear) + **table** (date, time, service, tier, required, used after, status chip). App: "Filters" heading with Material date fields + a dropdown + skeleton cards. |
| **Settings** (`Settings`, `PhSettings`) | **code** | Desktop: rail with an **Account** row and neutral icons; Appearance & Language selected by default with a Literata section title, description, grouped card (Theme segmented, language rows); search right-aligned in the header. App: no Account row, full-width search, Cloud sync selected. Phone: board is a **hub** (account card + six section rows with values, drill-in, version footer); the app is one long grouped list with multi-hue tiles. |
| **Sync** | **code** | Board: hero card (last successful sync, Literata time) + two stat tiles + Sync now / Retry buttons + Queue details list with type badges (REC / VOC / VID / AUD) and status chips. App: three thin rows + full-width buttons + collapsed "Queue details". |
| **Keyboard** | **code** | Board: group header = small letter badge + sans label + count; rows with keycaps (no `+` joiner), pencil + reset icons, `Custom` chip. App: multi-hue icon tile + Literata heading, `+` between keys, different action icons, extra subtitle line. |
| ProfileEdit, ProfilePrefs, AiProviders, CraftHistory | captured, not yet reviewed | Captures are in `build/duet_gallery/compare/`. |
| **Craft** (`Craft`, `PhCraft`) | **code** | Board: page header (overline `PRACTICE AUDIO FROM YOUR OWN WORDS`, Literata title, Express / Advanced segmented + History button) + Capture → Rewrite → Audio stepper + one card (record orb, Literata prompt, `中文 → English` chips, Type instead). App: subpage bar with back + centered segmented, no stepper, no card, mono `EN-US → EN-US`. |
| **SignIn** (`SignIn`, `PhSignIn`) | **code** | Board (desktop): dark split panel with the large logo art and "First the original voice. Then yours."; form with the logo, Literata title, Google (paper), Apple (ink), or, Email. App: centered form only, logo tile, brand Email button, Google / Apple behind "Other sign-in options" (check whether that is platform gating — keep the platform behavior if so). |
| Review, NotFound, Poster, dialogs (LibraryDelete, LibraryImporting, HomeImport, SubscriptionPlans, KeyboardCheatsheet, SettingsAbout update) | not captured | Fixtures land with the task that rebuilds them. |

### Player

Re-checked after A2 (the gallery now mounts the real player screen with the board's sample data: *The Ferry at Six*, Chinese translation, IPA, three takes).

| Area | Kind | Gaps |
|---|---|---|
| Time format ✅ | **code** | Board writes `0:04` / `0:55` everywhere (gutter, ruler, top-bar meta); the app writes `00:04` / `00:55`. |
| Top bar meta | **code** | Board: `Audio · 0:55 · English · 中文` (learning language name + translation language); app: `Audio · 00:55 · en`. |
| Top bar segmented | **code** | Board label `Echo`; app `Echo mode`. |
| Top bar, phone | **code** | Board: chevron · text-only Listen / Echo segmented · Share icon · CC, then a second row with the title and `Line 6 of 14 · looping`. The app has one row (icons + `E` keycap in the segmented, no Share, no title row). |
| Top bar, desktop | code | **More (⋯)** menu missing (deferred in D3.1). |
| Dock frame | **code** | `RootShell` wraps the dock in `SafeArea(minimum: 16 / 4 / 16 / 12)`, so it floats as an inset card; the board's dock is a full-bleed paper bar with a top line. |
| Dock, desktop Listen | code | The board **does** draw replay ↺ and the Repeat ⟲ button (decision R1); the app has replay but no Repeat (R1 still open). Skip glyphs filled on the board, outline in the app; speed is mono `1.0×` text, the app shows a `1x` pill; Hide shows eye-slash. |
| Dock, phone | **code** | Listen: one row (Hide · prev · play · next · speed), no replay. Echo: prev · Original (labelled) · Record (labelled) · next, no Hide. The app uses two rows (eye on its own row) and keeps the sunk group. |
| Ruler | **code** | Practiced dots above the ticks are missing. |
| Practiced dots in the gutter | verify | Seeded takes on line 6 show no gutter dot in the app; check `transcriptLineRecordingCountsProvider` against the seeded rows. |
| Echo context lines | **code** | Board: the lines around the loop show the English only; the app also shows the translation under each. |
| Takes strip | **code** | Board: newest take first with the selected take carrying a `Score` action, `Pitch` as its own toggle; app shows `Pitch contour` inline, no Score action on the unscored take. Phone: the strip falls below the fold because the loop sits low — check the scroll alignment against the board, which puts the loop in the upper third. |
| Assessment margin (D3.8) | code | Not built: margin assessment and wavy notes on words. Docked margin at ≥ 1100 still deferred. Decisions R1 (Repeat) and R2 (take management) open. |
| Harness | note | A few CJK glyphs (六, 是, 一 …) still draw as boxes in the gallery behind a Latin primary font — a `flutter test` engine limitation, not an app bug. |

## Plan

Each phase ends with its compare images attached to the PR. **A board's task cannot be marked `done` without its side-by-side compare.**

### Phase A — Honest verification (first)

1. **A1** Re-render the boards from the canvas (`tool/render_design_boards.mjs`, with the runtime from the canvas's `artifact-type/dc-runtime.js`) so `renders/` matches the current `Main` / `Phone`.
2. **A2** Player gallery mounts the real expanded-player body (`ExpandedPlayerChromeBody`: top bar + layout + dock), with fixtures for translation, IPA, takes with scores — **done 2026-10-06** for Main, DDark, DEcho, DCompact, Phone, PEcho, PDark; video, recording, scored, word, hide, subtitles and empty states follow in A5.
3. **A3** Fixtures that match the boards: continue-practice resume, library rows (video + audio, local + cloud), discover feed + channels, vocabulary items across all four statuses, credit log rows, a Free-plan subscription, sync queue rows — **done 2026-10-06** (`test/duet_gallery/board_data.dart`).
4. **A4** Harness gaps: a fake `record` platform channel (Craft), a signed-out auth fixture (SignIn), a review session (Review / ReviewBack / ReviewDone), a dialog opener helper (HomeImport, LibraryDelete, LibraryImporting, SubscriptionPlans, KeyboardCheatsheet, update dialog), and a pushed subpage so back buttons render.
5. **A5** One gallery scene per board in the [board → task index](STATUS.md#board--task-index); `duet_compare.sh` with no arguments then covers all of them. State boards (dialogs, Cloud / Audio tabs, review steps, player states) are added by the Phase C / D task that rebuilds them, so each rebuild lands with its compare.
6. **A6** Correct STATUS.md: reopen every task whose boards fail compare — **done 2026-10-06**.

### Phase B — Finish the foundations

1. **B1** D1.2 color scheme + component themes: Material date pickers, dropdowns, and progress indicators render in Duet (paper / line / ink, brand gradient only where the board uses it).
2. **B2** D1.5 controls: a capsule segmented control with counts, filter pills (date / select / clear), a search field with a keycap, status chips, and keycaps without joiners.
3. **B3** D1.6 surfaces: one neutral `EnjoyIconTile` (sunk + ink2), deleting the multi-hue variants (S1); grouped list card; stat tile; data table (header row, mono cells, status chip); hero card.
4. **B4** Page header primitive: overline + Literata title + trailing actions (S2), adopted by every page kind.
5. **B5** Sidebar "Search library" placeholder (S4); ghost Sign out (S5).

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

1. **D1** Top bar: `0:55` time format and language names in the meta, `Echo` label, phone two-row variant with Share, desktop More menu.
2. **D2** Dock to the board: full-bleed frame, filled skip glyphs, mono speed text, eye-slash Hide, the phone Listen and Echo rows (phone Listen drops replay — decision R3). Ship Repeat if R1 is accepted.
3. **D3** Ruler and gutter practiced dots; Echo context lines without translation; takes strip order, Score action, Pitch toggle; Echo scroll alignment.
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
