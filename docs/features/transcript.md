# Feature: Transcript

## MVP behavior

- Primary transcript = `echo_sessions.transcript_id` for the latest session on `(targetType, targetId)` (same id as library media row).
- **Track list stream** ([`TranscriptRepository.watchTracks`](../../lib/features/transcript/data/transcript_repository.dart)) exposes `List<TranscriptTrack>` per media id and is consumed through `allTranscriptsForMediaProvider`. Each `TranscriptTrack` defines **value equality** across its 7 fields (`id`, `targetType`, `targetId`, `language`, `source`, `label`, `trackIndex`), and the stream applies [`StreamDistinctExt.distinctBy`](../conventions.md#stream-dedupe-long-live-streams) with an element-wise list comparator so identical Drift re-emissions (e.g. an `echo_sessions` bump that doesn't change the resolved track list) never reach Riverpod listeners. Always-mounted consumers like `TransportCcButton` (the transport-bar CC indicator) only rebuild on real track changes — see `test/features/transcript/transcript_tracks_dedupe_test.dart` (9 pinning tests for skip-on-no-op and re-emit-on-real-change).
- Import `.srt` / `.vtt` via `SubtitleParserFacade` storing JSON in `transcripts.timeline_json`. Imports use `source: user` and a user-chosen BCP-47 **language** (one row per `(target, source, language)` via deterministic id).
- Tap line → seek + optional echo region update (via `PlayerInteractions`) **except** on the **active** cue and cues inside the **echo window**, where the row is **selectable** for dictionary lookup (no tap-to-seek on those rows). See [dictionary-lookup](dictionary-lookup.md).
- **Track / import entry**: Use the player **CC** control (opens subtitle sheet). While cloud fetch runs and no tracks exist yet, the CC icon shows a **spinner**; when tracks exist, a **badge** appears. The transcript panel shows **Fetching subtitles…** during load, **friendly error + Retry** on failure, and the confirmed empty state only after resolution completes. Manual **Extract** / **Add subtitle** / **Refresh from cloud** actions show inline spinners (picker and empty state).
- Subtitle track picker: **narrow** viewports use a draggable **Enjoy** bottom sheet; at **≥ `breakpointRail` (900px)** the same UI opens as a **centered dialog** (max width 560) for mouse-first layouts. The sheet body no longer nests an extra **SafeArea** (the modal already applies safe-area padding). **Loading** / **error** / **empty** states: errors show **friendly** title + hint strings plus **Retry** (raw exception text is not surfaced in the primary message). Each track shows **provider** (`official` / `auto` / `ai` / `user`) and language. **Deleting** any transcript clears `echo_sessions` primary/secondary references when that track was selected, reassigns primary using **source priority** (`official` → `auto` → `ai` → `user`, then `createdAt`), and clears secondary if it would duplicate the new primary.
- **Dictionary / translation lookup** ([ADR-0019](../decisions/0019-transcript-dictionary-lookup.md)): opened from transcript text selection. **Narrow**: `showEnjoySheet` + `DictionaryLookupSheet` (draggable). **Wide (≥ rail breakpoint)**: `showEnjoyDialog` with the same content in a bounded **dialog** (no double safe-area wrapper on the sheet body).
- **Import subtitle language** dialog: the language field uses a visible **label** (`subtitlesImportLanguageFieldLabel`) in addition to the hint copy.
- **Accessibility**: `TranscriptScrollableList` exposes a **list** semantics label. Each `TranscriptLineTile` exposes a **combined** semantics label (timestamp + snippet, with optional state prefix for current line / echo region). When `AppLocalizations` is absent (e.g. bare widget tests), semantics fall back to non-localized cue text only.
- **Cloud transcripts**: In the **background when you open** a library item, the app runs **`resolveOnOpen`**: auto-select primary when tracks exist, import adjacent **sidecar** `.srt`/`.vtt` for local files, then call `/api/v1/transcripts` when signed in. Fetch lifecycle is observable in the UI (**CC spinner**, transcript panel **Fetching subtitles…**, picker banner). Outcomes persist in `transcript_fetch_states` (`lastStatus`, `lastError`). Cloud fetch runs once per target until **Refresh transcripts from cloud** in the picker. The same scheduling runs alongside opening the media engine (not gated on the play button). **Signed-out** users still get sidecar import and primary auto-select; cloud fetch is skipped.
- **YouTube (Worker)**: For rows that resolve to YouTube playback (`provider` / URL / `vid` inference), the app calls the Enjoy Worker `POST /youtube/transcripts` using **`VideoRow.vid`** as `video_id` (not the Enjoy library `id`). Caption language follows **`videos.language`** (primary subtag sent to the worker). When language is missing or `und`, the worker fetch is **skipped** — the user must set content language first; correcting language clears fetch state so **Retry** can run with the new locale. Responses are polled until `ready` or `failed` (or timeout); transcripts are stored locally with `targetId` = library media id. The worker origin defaults to `https://worker.enjoy.bot` (`kDefaultAiApiBaseUrl` in `lib/data/db/settings_keys.dart`); users can override it via the **AI API base URL** setting in Developer settings, or tap **Use API URL** to make the AI URL follow the main API URL (in-memory until the next override).
  - **Bilingual fetch** ([ADR-0036](../decisions/0036-youtube-bilingual-transcripts.md)): the learner's `effectiveNativeLanguage` is read inside `TranscriptFetchCtrl._runResolve` (the shared helper used by both `resolveOnOpen` and `refreshFromCloud`, so a manual refresh re-requests both) and passed down as a `nativeLanguage` parameter — the repository itself stays UI-/provider-free. When a valid native base code **differs** from the source, the app sends `pollTranscripts({ languages: [source, native], waitMs })`; otherwise it keeps the single-language path. The original caption is stored as **primary** and the native translation as **secondary** (explicit `updatePrimaryTranscriptForTarget` / `updateSecondaryTranscriptForTarget`, not source-priority sort).
  - **Request body** ([`youtube_transcripts_api.dart`](../../lib/data/api/services/ai/youtube_transcripts_api.dart)): single-language `pollTranscript` sends `{ videoId, language, captionFetch: "auto", forceRefresh?, waitMs? }`; multi-language `pollTranscripts` sends `{ videoId, languages: [source, native], captionFetch: "auto", forceRefresh?, waitMs? }`. `ApiClient` converts camelCase keys to snake_case on the wire. `videoId` is `VideoRow.vid` when it matches the Worker's 11-character YouTube id pattern (`^[a-zA-Z0-9_-]{11}$`); otherwise the client falls back to `youtubePlaybackVideoId(...)` derived from provider / `mediaUrl` / source. `language` / `languages` are base subtags from `workerLanguageBase`.
  - **Poll semantics** (`TranscriptRepository._fetchYoutubeWorkerTranscripts`): the client uses the Worker's **server-side long-poll** — every POST carries a non-zero `waitMs` (default 20000, capped at 25000 by the worker) and, on a `generating` (HTTP 202) response, the client waits a 5 s backoff (the worker's `Retry-After` value — a constant, since `ApiClient.postJson` does not expose response headers) before re-POSTing. The loop is bounded by a small attempt budget sized for ~60–75 s total (configurable via `TranscriptRepository` constructor params, for tests). `forceRefresh` is sent as `true` only on the **first** attempt of a forced refresh (`attempt == 0 && force`); later attempts send `forceRefresh: false` so a retry does not repeatedly invalidate the Worker's cache mid-poll.
  - **Outcomes**: multi-language `status: "ready"` or `"partial"` upserts every entry in `transcripts[]` (distinct rows via `enjoyTranscriptId('Video', mediaId, language, source)`) and returns `success` with the stored count (or `empty` if nothing stored). A `partial` logs `missingLanguages` through `logNamed`; if the *source* language itself is the missing entry, no primary is invented from a non-existent row — the `ensurePrimaryTranscript` source-priority sort picks a readable track instead. Single-language `status: "ready"` stores the flat transcript and returns `success`. `status: "failed"` logs the response `error` and returns `error` immediately (no further polling). Exhausting the attempt budget while the Worker keeps returning `generating` returns `error` (`"Timed out waiting for YouTube transcripts"`) **without** writing a `transcript_fetch_states` row for that attempt. A `failed`/error outcome never wipes already-stored tracks.
  - **Label / metadata**: the stored transcript's `label` prefers `response.metadata.title` (trimmed, if non-empty); otherwise it falls back to the hardcoded (non-localized) string `"YouTube captions (<language>)"` where `<language>` is the same base subtag sent in the request.
- **Embedded subtitles (video)**: No automatic demux. The picker and the transcript **empty state** offer **Extract** (video only); streams are saved as `source: user` (same uniqueness as imports). If `media_kit` has not listed subtitle tracks yet, the app falls back to **`ffmpeg -i`** stderr to find `Subtitle:` streams and demuxes with `-map 0:s:N` (same as before when tracks were known). **Windows**: Demux uses **`ffmpeg.exe`** next to `enjoy_player.exe` (installed from [`windows/ffmpeg/ffmpeg.exe`](../../windows/ffmpeg/ffmpeg.exe) when present at build time) or **`ffmpeg` on PATH**. If neither is available, extraction no-ops; users can still import `.srt` / `.vtt`. Details: [`windows/ffmpeg/README.md`](../../windows/ffmpeg/README.md).
- **On-video subtitles**: Disabled by default (`SubtitleTrack.no()` after open + `SubtitleViewConfiguration.visible: false` on [`Video`](../../lib/features/player/presentation/layouts/video_player_layout.dart)); cues are shown in the transcript panel instead.
- **Markup**: SSA/HTML-like cues (`<font color="…">`, `<b>`, `<i>`, `<br>`, etc.) are parsed in the transcript panel via `parseSubtitleMarkup` (`lib/data/subtitle/subtitle_markup_parser.dart`); colors and styles render as rich text instead of raw tags.
- **Line UI**: Each cue has a **header row** (timestamp first; **recording count** badge with mic icon when shadow-reading takes overlap that cue by time range). Body text follows on the next lines. Row backgrounds are **transparent** by default; **hover**, **active playback**, **echo-range**, and **active inside echo** use distinct tints (playback within the echo region blends echo orange with primary vs plain active vs echo-only lines).
- **Active-line rail**: the **active** playback line carries a **3px left rail** (rounded ends) colored **primary** for a plain active cue and **echo orange** for a cue inside the echo region — also when both apply. Cues outside the active/echo set have no rail.
- **Secondary (translation) track hierarchy**: when a translation track is rendered alongside the primary line, it sits below the primary with a **2px left border** tinted `onSurfaceVariant @ 22%` to keep reads ordered without italic. Rendered through `Noto Sans SC` with the same CJK fallback chain as the primary track — see [app-ui § Typography](app-ui.md#typography).
- **Auto translate** ([ADR-0037](../decisions/0037-transcript-auto-translate.md)): the translation picker offers **Auto translate** after **None** (AI `source: ai` tracks are hidden from the generic list to avoid duplicate rows). Selecting it creates/resumes a durable AI secondary track keyed by native language, runs a lazy playback-priority job via `AutoTranslateCtrl` (≤2 concurrent `translationService` calls, per-line retry), and shows progressive secondary text under primary cues. Finished lines are **cached locally** — switching away to None and back to Auto translate resumes without re-requesting ready lines. Each translated line has an inline **refresh** control to re-translate that line only. Pending lines show a compact “Translating…” placeholder. Coexists with YouTube bilingual secondary tracks and imported captions.
- **Recording counts** read from local Drift (`recordings` table); when signed in, cloud metadata sync runs on media open ([`schedulePlayerOpenSideEffects`](../../lib/features/player/application/player_open_side_effects.dart)) and counts update live when new takes are saved in echo mode.
- **Auto-follow**: While the engine is **playing**, the list auto-scrolls when the target would be off-screen (`Scrollable.ensureVisible`). **Non-echo**: the **active cue** is brought into view with a mid-viewport bias (`alignment ~0.42`). **Echo mode**: the merged **echo block** (controls + cue card + shadow-reading stack) is the scroll target and is aligned to the **top** of the transcript viewport to leave more vertical room for the shadow panel. When paused, the list does not auto-scroll.
- **Echo region** (echo mode on): **Expand / shrink** controls sit **between** the transcript list and the shadow panel as separate rows (not inside the cue card). **Cue lines** use one merged rounded **transcript card**; **shadow reading** is a **compact stack** below with an **idle toolbar** (pitch **icon** toggle, **centered** 56pt record FAB, play + **more** menu **grouped at center**; **delete** is in the menu as a **list-style row** (leading delete icon, same column as take checkmarks), with a **confirm dialog** before removal), **pitch chart** when expanded (headerless body only), and **recording focus** (centered FAB + elapsed vs segment target; over-target warning only). Long hint is in the record control **tooltip** (shortcut + `shadowReadingHint`) — see [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart). Take duration is derived from the **WAV header** (see [`wav_duration_ms`](../../lib/core/audio/wav_duration_ms.dart)). Take playback uses a dedicated **`media_kit`** preview player ([`recording_preview_player`](../../lib/core/audio/recording_preview_player.dart)), separate from lesson playback so the loaded lesson is not replaced.

## Code layout

The subtitle track picker is split into focused modules under
[`lib/features/transcript/presentation/`](../../lib/features/transcript/presentation/),
organized by dependency layer (helpers → primitives → tiles → sections →
actions → sheet). The public API is unchanged; `showSubtitleTrackPicker`,
`SubtitleTrackPickerSheet`, and `SubtitleTrackPickerPresentation` continue to
be exported from [`subtitle_track_picker_sheet.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_sheet.dart).

| File | Responsibility |
|------|----------------|
| [`subtitle_track_picker_helpers.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_helpers.dart) | Pure helpers (`sheetHorizontalPadding`, `trackOptionPadding`, `trackPickerRadioTheme`, `trackLabel`, `findTrack`, `providerLabel`, `providerBadgeColors`), the `kExpandedTrackListMaxHeight` const, and the `PickerSection` enum. No widgets. |
| [`subtitle_track_picker_primitives.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_primitives.dart) | `MetaChip` — the rounded pill used for provider / language badges, shared by `SelectionSummary` and `TrackOptionTile`. |
| [`subtitle_track_picker_tiles.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_tiles.dart) | `TrackOptionTile<T>` (per-track radio row with provider + language chips and delete action) and `NoneOptionTile` (the explicit "none" row in the translation list). |
| [`subtitle_track_picker_sections.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_sections.dart) | `CollapsibleTrackSection` (the expandable card used for both primary and translation lists) and `SelectionSummary` (collapsed-state label + chip summary). |
| [`subtitle_track_picker_actions.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_actions.dart) | `SubtitleActionsSection` — the leaf widget that renders the Extract / Refresh from cloud / Import subtitle list. Wraps the tile column in a transparent `Material` so `ListTile` ink splashes render correctly. |
| [`subtitle_track_picker_sheet.dart`](../../lib/features/transcript/presentation/subtitle_track_picker_sheet.dart) | Slimmed sheet: `SubtitleTrackPickerPresentation` enum, `showSubtitleTrackPicker` launcher, and `SubtitleTrackPickerSheet` + its state class. Owns the `PickerSection` expand/collapse state and provider interactions (import file, extract embedded, refresh cloud, delete track). |

Smoke coverage lives in
[`subtitle_track_picker_sheet_test.dart`](../../test/features/transcript/subtitle_track_picker_sheet_test.dart)
(pumps the sheet in dialog presentation with faked providers and asserts the
empty-tracks hint plus primary + translation section headers for a single
track). The split is also recorded as
[`2026-07-07-subtitle-track-picker-split-design.md`](../superpowers/specs/2026-07-07-subtitle-track-picker-split-design.md).

## Blur practice (listening-focus) mode

A "Blur practice" toggle in the bottom transport bar (next to the Echo
button) renders every transcript cue body text with a CSS-style
`ImageFilter.blur` filter so the user can practice listening first and
then peek at the text to check themselves. The mode is deliberately
hearing-focused:

- The **active playback cue is never auto-revealed**. Even when
  playback runs through the transcript, every cue — including the
  currently playing one — stays blurred. See
  [`specs/006-transcript-blur-practice/spec.md`](../specs/006-transcript-blur-practice/spec.md)
  § Clarifications (Session 2026-07-08) for the user-facing rationale
  and the rule.
- The only ways to see a cue's text in blur practice mode are
  pointer hover (macOS, Windows) or a tap that starts a hold
  (every platform).

### Toggle, hover, and tap-reveal

- The **toggle** lives in the bottom transport bar's secondary tool
  cluster, immediately after the Echo button
  ([`global_transport_bar.dart`](../../lib/features/player/presentation/widgets/global_transport_bar.dart)).
  It mirrors the Echo button styling (active state tinted with the
  `blurActive` token) and carries a hotkey hint in its tooltip. The
  same global state is also exposed as a switch in **Settings →
  Transcript → Listening-focus practice**, and the `H` key toggles it.
- On macOS and Windows, **hovering a cue unblurs it**; pointer-out
  re-blurs it within one frame. The hover state is owned by the tile
  widget itself so per-frame hover changes do not invalidate unrelated
  cues. This now applies to active and echo cues too — selectable tiles
  carry the same `MouseRegion` as plain cues.
- On every platform (including desktop as a fallback), **tapping a
  blurred cue starts a configurable hold** (default 3 seconds) that
  reveals it. For plain cues the tap also seeks playback to that cue;
  for selectable (active / echo) cues the tap reveals without seeking.
  During the hold the cue is unblurred; when the hold expires it
  re-blurs. Tapping a different cue replaces the hold (the prior cue
  re-blurs immediately, the new cue reveals).

### Persistence

Two new Drift `settings` keys (device-local UI preferences, **not**
synced to the server profile):

- `prefs.transcript_blur_practice_enabled` — boolean (`'true'` /
  `'false'`, default off).
- `prefs.transcript_blur_tap_reveal_seconds` — integer `'1'`…`'15'`
  (default 3).

Both live in
[`lib/data/db/settings_keys.dart`](../../lib/data/db/settings_keys.dart)
and are read/written through the existing `SettingsDao` by
`TranscriptBlurPreferencesCtrl`
([`lib/features/transcript/application/transcript_blur_preferences_provider.dart`](../../lib/features/transcript/application/transcript_blur_preferences_provider.dart)).
The hold duration is also editable from **Settings → Transcript →
Listening-focus practice**, which hosts a slider row in the new
section
([`lib/features/settings/presentation/widgets/sections/transcript_blur_section.dart`](../../lib/features/settings/presentation/widgets/sections/transcript_blur_section.dart)).

### Rendering

The blur is applied via `TranscriptBlurText`
([`lib/features/transcript/presentation/transcript_blur_text.dart`](../../lib/features/transcript/presentation/transcript_blur_text.dart))
inside `TranscriptLineTile`. Only the body text widgets are wrapped —
timestamps, recording badges, hover tints, the active-line rail, and
the merged echo card chrome (rails / dividers / controls) are never
blurred; the cue text inside the echo card is. When the toggle is off
the cue renders exactly as before (zero overhead).

### Active-line and active-cue rule (the 2026-07-08 clarification)

The original draft proposed an "always reveal the active line" rule
as the bridge between desktop hover and mobile interactions. The user
corrected this: the purpose of the mode is hearing-focused practice,
so revealing the active line defeats the goal. The active cue has no
privileged state — `transcriptCueRevealProvider`
([`lib/features/transcript/application/transcript_cue_reveal_provider.dart`](../../lib/features/transcript/application/transcript_cue_reveal_provider.dart))
explicitly does NOT read
`transcriptPlaybackHighlightProvider`, and the widget-level OR
(`!blurEnabled || _hover || providerRevealed`) treats the active cue
exactly like every other cue.

### Echo mode

Blur practice mode continues to apply to cues rendered inside the
echo region, including the active echo cue. Hover and tap-reveal work
the same way as plain cues: the echo tiles carry a `MouseRegion`
(hover reveal) and tapping the cue text starts the reveal hold. Only
the cue body text is blurred — the echo card chrome and the
shadow-reading panel are not.

### Tests

Coverage lives under
[`test/features/transcript/`](../../test/features/transcript/):

- `transcript_blur_preferences_provider_test.dart` — hydration,
  default fallbacks, clamping of `tapRevealSeconds`, persistence,
  read-only projection during loading.
- `global_transport_bar_test.dart` (under
  [`test/features/player/`](../../test/features/player/)) — the blur
  toggle's off/on icon states, disabled state when there are no
  transcript lines, and that a tap flips `setEnabled`.
- `transcript_blur_hover_test.dart` — pointer-enter reveals;
  pointer-out re-blurs; toggle-off bypass.
- `transcript_blur_selectable_reveal_test.dart` — the active / echo
  (selectable) cue reveals on hover and tap-reveal, matching plain cues.
- `transcript_blur_hold_test.dart` — tap seeks + reveals; expiry
  re-blurs; second tap replaces the hold; toggle-off bypass.
- `transcript_blur_active_line_stays_blurred_test.dart` — drives the
  active cue through several indices while blur is on and asserts the
  active cue never auto-reveals (the spec's hard rule).
- `transcript_blur_settings_test.dart` — settings UI renders ARB
  strings; slider drag persists.
- `transcript_blur_long_list_perf_test.dart` — 10 000-line smoke
  under `ImageFiltered`; per-frame budget assertion.

## Future

- Multiple languages, editing timelines, export — parity with web `TranscriptDisplay`.
