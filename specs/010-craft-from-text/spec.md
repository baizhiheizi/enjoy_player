# Feature Specification: Craft from Text (AI-generated audio materials)

**Feature Branch**: `010-craft-from-text`

**Created**: 2026-07-09

**Status**: Draft

**Input**: User description: "Now Enjoy Player support using local video/audio and YouTube videos to practices. But some users want to homecook materials. Use AI to translate some text, then use TTS to generate the audio as shadow reading materials. Or they want to use some text to use TTS directly to generate the audio materials. Similar features has been implemented in `~/dev/enjoy` project, `apps/web`, as smart translation and voice synthesis. We need to port them into this flutter project. But we need to redesign the UX. We don't provide the `smart translation` and `voide synthesis` entries directly. When importing, beside `local` and `youtube`, we add another option `homecook`(or any better name you come up with). Then two options, any languages to learning lanuage audio(translate then synthesis; and synthesis the materials of the learning language directly). behind the hook, we use the AI services, and we need to extend the BYOK for more providers, like TTS."

## Scope

### In scope

- A third entry in the existing import chooser sheet: **Craft from text** (provider value `craft`), sitting beside **From file** and **From YouTube URL**. The label is localizable; `craft` is the canonical storage key for the resulting media row.
- A single Craft flow that internally offers two product modes, presented as the only ways to use the entry — there is no separate "Smart Translation" or "Voice Synthesis" navigation in the player:
  - **Translate then speak** — take text in any language, translate it into the learner's profile learning language, then synthesize audio in that learning language.
  - **Speak directly** — take text already in the learner's profile learning language and synthesize audio in that learning language.
- Behind the scenes: route through the existing `TranslationService` (LLM-backed, already BYOK-aware per ADR/spec 003) and `TtsService` (enjoy path + BYOK OpenAI/Azure per spec 003). Promote TTS BYOK from P3 to a first-class setting surface so this feature ships with vendor parity.
- Persist the result as a normal audio media item in the local library (Drift `AudioRow`, provider `craft`) with a paired primary transcript in the learning language and (for "Translate then speak") an optional original-source secondary transcript, so echo mode and transcript overlay work without extra wiring.
- Show a clear **Craft** badge in the library grid alongside the existing **YouTube** provider badge.
- Error, partial-failure, and "service unavailable" UX that follows the same calm, actionable patterns as the existing import flows; never expose raw exception text as the primary message; never burn TTS/translate calls on empty or trivially short input.
- New ADR for the import-flow decision (`docs/decisions/0043-craft-from-text-import.md`); updates to `docs/features/library.md`, `docs/features/ai.md`, and `docs/features/transcript.md`; setting-surface updates in `docs/features/settings.md`.

### Out of scope

- **Local / on-device AI** for translation or TTS — `AIProvider.local` stays unreachable from UI per spec 003 / ADR-0014.
- **Background music, video compositing, or any media beyond synthesized audio.** Resulting items are audio only; existing audio player and library affordances apply.
- **Per-call voice selection UI** in v1 — the TTS vendor's default voice for the target language is used (configurable per-provider in AI settings later). Users who want a specific voice pick that voice at the provider level in Settings → AI providers.
- **Cloud sync of TTS BYOK secrets** (stays out of scope per spec 003).
- **Sharing or exporting Craft-generated audio / transcripts** beyond the existing media row capabilities.
- **In-flow editing of the translated text** before TTS — the flow generates, not authors; if a learner wants to hand-edit the text, they can do so on the resulting audio's transcript later.
- **Standalone "Smart Translation" / "Voice Synthesis" navigation tabs** that mirror `apps/web`. The product decision is that both flow through the Craft import entry; the web routes remain a reference, not a port target.
- **Modifying existing import chooser entry order or labels** beyond adding the new entry.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover Craft from text in the import chooser (Priority: P1)

A learner who has finished setting up local files and YouTube imports notices they still cannot study short material they have lying around — a paragraph from a textbook, a tweet in the target language, a recipe. They tap **Import** and, in the sheet they already know, see a third option labeled **Craft from text**. It reads as a peer of "From file" and "From YouTube URL", not as a settings or developer tool.

**Why this priority**: Without a discoverable entry that fits the existing import sheet, the feature never reaches anyone — every other user story depends on this surface.

**Independent Test**: Open the import chooser from Home or Library on Android, iOS, macOS, and Windows; confirm exactly three entries are visible, in a consistent order, with the Craft entry clearly distinguished from file / YouTube by label and icon.

**Acceptance Scenarios**:

1. **Given** the import chooser sheet, **When** the learner opens it, **Then** three entries are visible: **From file**, **From YouTube URL**, **Craft from text**; the labels and icons follow the existing list-tile pattern used for the first two.
2. **Given** the learner opens the chooser, **When** they tap **Craft from text**, **Then** the chooser closes and the Craft flow starts immediately — no extra "what is Craft?" modal is shown on first tap; brief in-flow copy explains the modes the first time only.
3. **Given** the learner is on a platform with reduced motion, **When** the chooser sheet animates in, **Then** no extra or longer animation is introduced beyond the existing sheet pattern.

---

### User Story 2 - Translate then speak (any language → learning language audio) (Priority: P1)

A learner pastes a paragraph in their native language (or any other language) into the Craft flow, picks **Translate then speak**, confirms the source language and the target learning language, taps a single action button, and within a reasonable wait ends up on a working audio item in the player with the translated learning-language text already laid out as the primary transcript and the original source text available as a secondary reference.

**Why this priority**: This is the headline use case the user described. If translation + TTS do not chain correctly into a playable media item, the feature does not exist for its main audience.

**Independent Test**: With Translation (LLM) and TTS providers configured (Enjoy default or BYOK), paste ~300 characters of English text, choose Translate then speak with target = the learner's profile learning language, complete the flow, and confirm the player opens an audio item whose primary transcript is in the target learning language and whose audio plays the spoken translation.

**Acceptance Scenarios**:

1. **Given** the Craft flow is open with **Translate then speak** selected, **When** the learner enters text, picks a source language, and confirms the target learning language, **Then** a single **Craft** action starts the work (no extra "translate now / speak now" two-step confirm).
2. **Given** the Craft action runs successfully, **When** it finishes, **Then** the learner is taken to the player with a new audio item whose primary transcript lines match the translated learning-language text and whose audio duration matches the synthesized speech (allowing for ±5% TTS drift).
3. **Given** the Craft action runs, **When** it succeeds, **Then** the original source text is also stored on the item as a secondary transcript so bilingual overlay works on first play (consistent with spec 009's auto-translate convention).
4. **Given** the learner is signed out, **When** they tap Craft, **Then** they are sent through the same sign-in affordance used by other AI surfaces (per spec 003), with a calm "sign in to use Craft" explanation; the chooser does not silently fail.
5. **Given** the learner enters text in the target learning language while Translate then speak is selected, **When** the flow detects same-language input, **Then** the UI offers a one-tap switch to Speak directly without losing the entered text; no translation call is burned.
6. **Given** the source-language picker, **When** the learner opens it, **Then** it lists the same content-language options used elsewhere in the app (per `kSupportedNativeLanguageTags` / media catalog) and remembers the most recent pick for the next Craft.

---

### User Story 3 - Speak directly (learning-language text → audio) (Priority: P1)

A learner who has a block of text already in their profile learning language (a vocabulary list, a dialogue, a passage they are about to memorize) wants to turn it into a shadow-reading audio. They tap Import → Craft from text → **Speak directly**, paste the text, confirm the target language is their profile learning language, tap Craft, and land in the player with an audio item they can echo against.

**Why this priority**: Equal to P1 translate flow — the user described both modes explicitly and Speak directly is the simpler half that should ship first if anything needs to be cut.

**Independent Test**: Paste ~200 characters of learning-language text, choose Speak directly, complete the flow, and confirm the player opens an audio item whose primary transcript equals the entered text and whose audio plays the entered text.

**Acceptance Scenarios**:

1. **Given** the Craft flow is open with **Speak directly** selected, **When** the learner enters text and taps Craft, **Then** a single synthesize call runs and the resulting audio item's primary transcript is the entered text (no translation layer involved).
2. **Given** Speak directly is selected, **When** the flow starts, **Then** no source-language picker is shown — the only language picker is the target learning language, defaulting to the profile learning language.
3. **Given** Speak directly completes, **When** the learner lands in the player, **Then** the audio item plays the entered text and echo mode (shadow reading) is immediately usable against the primary transcript.
4. **Given** Speak directly is selected, **When** the learner enters text that is clearly in a different language from the target (e.g. by length or by later hint), **Then** the flow does not auto-correct; if the user wants translation they can switch modes via the same one-tap affordance as user story 2.

---

### User Story 4 - BYOK TTS provider parity for Craft (Priority: P2)

A learner who already uses BYOK for LLM / translation wants TTS to use their own subscription too — both OpenAI-compatible and Azure Speech — without sending their audio back through Enjoy workers. They open AI settings, configure TTS BYOK for their preferred vendor (same per-modality form spec 003 already supports), and Craft starts using that vendor on the next run.

**Why this priority**: Spec 003 already lists TTS BYOK as P3. With Craft shipping, TTS BYOK becomes a meaningful surface — it is no longer a stub. Promoting it to a first-class setting card mirrors what LLM / ASR / assessment already are.

**Independent Test**: Configure TTS BYOK for an OpenAI-compatible endpoint (or Azure Speech), disable Enjoy network access in a controlled test, run Craft end-to-end, and confirm synthesized audio is produced by the BYOK vendor and the player opens normally.

**Acceptance Scenarios**:

1. **Given** AI provider settings, **When** the learner opens the TTS card, **Then** it is presented with the same affordances (vendor dropdown, base URL, API key, model / voice defaults, validation, masked secrets) as ASR and assessment cards in spec 003.
2. **Given** TTS is set to a configured BYOK vendor, **When** the learner runs Craft, **Then** the synthesize call uses that vendor and Enjoy worker TTS routes are not invoked (verifiable in network logs / provider labels).
3. **Given** TTS BYOK is selected but misconfigured, **When** the learner runs Craft, **Then** the error message points them at the TTS card in Settings and offers a one-tap "Open AI settings" action; raw exception text is never the primary message.
4. **Given** TTS BYOK is removed or reverts to Enjoy AI, **When** the next Craft runs, **Then** the routing flips on the next user-initiated action (no app restart needed) — same rule as spec 003 SC-006.

---

### User Story 5 - Library badges, replay, and parity with other providers (Priority: P2)

After Craft succeeds, the new audio item sits in the library with a clear **Craft** badge so learners can tell at a glance which items were AI-generated from text. From the library grid it behaves like any other audio item: tap to play, edit language, delete, see in recent, sync through the same sync queue (provider value `craft` participates in normal sync).

**Why this priority**: Discoverability and trust — without a badge, learners lose track of what was synthesized vs. imported, and the AI-cost story becomes opaque.

**Independent Test**: Run Craft twice (Translate then speak, Speak directly), open Library, confirm both items show the Craft badge and behave like any audio item (tap → player; delete → library removes; edit language → reflects in player).

**Acceptance Scenarios**:

1. **Given** a Craft-generated audio item, **When** it appears in the library grid, **Then** it shows a **Craft** provider badge in the same position the YouTube badge uses, with an accessible tooltip / label.
2. **Given** a Craft-generated audio item, **When** the learner taps it, **Then** it opens in the player with its primary transcript ready and (for Translate then speak) its source-text secondary transcript ready, identical to non-Craft audio behavior.
3. **Given** a Craft-generated audio item, **When** the learner deletes it, **Then** both the audio file and any associated transcripts are removed via the existing `deleteMedia` path; nothing is left orphaned in app storage.
4. **Given** a Craft-generated audio item, **When** sync runs, **Then** the item participates in the existing sync queue with provider `craft` — no separate sync path is introduced.

---

### User Story 6 - Calm, honest failure and recovery (Priority: P2)

Things go wrong: the network drops mid-translate, the TTS vendor rejects the target language, BYOK is missing, the AI worker returns 402 credits exhausted. In every case the learner sees a calm, localized message that names what failed (translate / synthesize / save) and offers a concrete next action — never a raw exception, never a silent success with missing audio.

**Why this priority**: Trust — Craft is the first AI import path in the player; bad failure UX poisons the whole feature.

**Independent Test**: Force three failure modes (network drop mid-flow, BYOK TTS unconfigured, credits exhausted) and confirm each surfaces the right next action without leaving the learner stuck on a spinner or in a half-imported state.

**Acceptance Scenarios**:

1. **Given** the Craft flow is running, **When** the network drops or the AI worker fails, **Then** the learner sees a calm failure message with a **Retry** action; nothing is partially saved to the library; no raw exception text is shown.
2. **Given** TTS BYOK is selected but not configured (or revoked), **When** Craft runs, **Then** the error names TTS as the failing stage and offers an **Open AI settings** action; the translation result (if any) is discarded so the learner does not see a phantom transcript with no audio.
3. **Given** Enjoy AI credits are exhausted for the failing modality, **When** Craft runs, **Then** the message uses the same credits guidance as other AI surfaces (per spec 002) — no special Craft-only copy.
4. **Given** the synthesized audio fails to save to local storage after a successful TTS response, **When** the flow recovers, **Then** the learner is told the audio was generated but could not be saved; the bytes are discarded (no audio is silently dropped without notice); no orphaned transcript row is left behind.

### Edge Cases

- Empty input, whitespace-only input, or text below a sensible minimum (~10 characters) → Craft action is disabled with an inline hint; no AI call is made.
- Very long input (≥ ~5 000 characters) → flow warns and either truncates with a clear notice or chunks synthesis (concatenating audio clips) per implementation; learner sees exactly what happened.
- TTS vendor does not support the target language → fail with a message that says which language is unsupported and recommends switching target language or TTS vendor; do not fall back silently to a different voice.
- Translation result is empty or returns an error from the LLM → no TTS call is made; learner gets a translate-stage error with Retry.
- Synthesized audio is shorter / longer than the primary transcript text implies → primary transcript timings are derived from the text only; UI shows transcript text alongside audio; off-by-some-seconds drift is accepted and surfaced in the player (not masked).
- Sign-in state changes mid-flow (sign out, token expired) → in-flight work fails with the same calm "sign in to use Craft" copy; no half-imported rows persist.
- Device offline at Craft open → message at the top of the flow: "You're offline. Craft needs an internet connection."; Craft action is disabled.
- Craft fails repeatedly for the same input → learner can switch modes (Translate then speak ↔ Speak directly) without re-entering text; the picker remembers the previous pick.
- Same text pasted twice (or near-identical hash) → library does not duplicate the audio row; second Craft surfaces "Already in your library" with a one-tap **Open** action (consistent with YouTube import dedupe).
- Platform input patterns (Android, iOS, macOS, Windows): paste-from-clipboard works on all four; the Craft flow respects the same sheet vs dialog conventions the existing import chooser uses; on desktop, Enter / Cmd-Enter submits the Craft action when input is valid.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The import chooser sheet MUST add a third entry labeled **Craft from text** alongside **From file** and **From YouTube URL**, following the existing list-tile pattern (leading icon + label, sheet opens on tap).
- **FR-002**: The Craft entry MUST start a single Craft flow that exposes exactly two mode choices to the learner: **Translate then speak** and **Speak directly**. There MUST NOT be a separate top-level navigation route or home-screen entry for "Smart Translation" or "Voice Synthesis".
- **FR-003**: In Translate then speak mode, the Craft flow MUST translate the entered text into the learner's profile learning language using the existing translation / LLM capability layer, then synthesize speech in that learning language.
- **FR-004**: In Speak directly mode, the Craft flow MUST synthesize speech directly from the entered text in the learner's profile learning language; no translation step is performed.
- **FR-005**: Synthesized audio MUST be persisted as a local audio file in the player's existing file storage so playback uses the normal audio media path (no special "TTS stream" player).
- **FR-006**: Craft MUST persist a primary transcript for the new audio item in the learning language: the translated text in Translate then speak mode, the entered text in Speak directly mode.
- **FR-007**: For Translate then speak mode, Craft MUST also persist the original source text as a secondary transcript on the same audio item, so bilingual overlay works without extra steps on first play.
- **FR-008**: Craft MUST store the new media row with `provider = 'craft'` so library badges, sync routing, and library queries can distinguish Craft-generated items from local / YouTube items.
- **FR-009**: Craft MUST reuse the existing `TranslationService` and `TtsService` capability wiring (per spec 003 / ADR-0014) so modality resolution (Enjoy AI vs BYOK) and credit consumption follow the same rules as other AI surfaces.
- **FR-010**: TTS BYOK MUST be promoted from spec 003's P3 to a first-class setting card that supports OpenAI-compatible and Azure Speech vendors, with the same field set, validation, masked secrets, and base-URL rules as ASR BYOK.
- **FR-011**: The Craft flow MUST show a single progress affordance while translate + synthesize run; it MUST NOT block on two separate confirm steps ("translate now?" / "speak now?") for Translate then speak mode.
- **FR-012**: When the source language equals the target learning language in Translate then speak mode, the flow MUST offer a one-tap switch to Speak directly without losing the entered text and MUST NOT issue a translation API call.
- **FR-013**: If translation succeeds but synthesis fails, Craft MUST discard the translation result and surface a calm TTS-stage error with Retry; no orphan transcript row is left in the database.
- **FR-014**: If synthesis succeeds but local file storage fails, Craft MUST discard the audio bytes and surface a calm save-stage error; no orphan audio file or transcript row is left.
- **FR-015**: Craft MUST handle sign-in / token-expiry cases by routing through the same auth affordance used by other AI surfaces; a signed-out learner MUST NOT see Craft silently fail.
- **FR-016**: Craft MUST respect the existing per-modality AI provider settings: the TTS modality config drives synthesis, the translation / LLM modality config drives translation. There is no Craft-specific provider picker that bypasses the shared modality layer.
- **FR-017**: The library grid MUST show a **Craft** provider badge for items with `provider = 'craft'`, in the same position the YouTube badge uses, with an accessible localized tooltip / label.
- **FR-018**: Craft MUST dedupe by content fingerprint: pasting the same text twice (or near-identical content hash) MUST NOT create a duplicate audio row; the second attempt offers **Already in your library** with a one-tap **Open**.
- **FR-019**: Deleting a Craft-generated audio item MUST use the existing `deleteMedia` path and MUST remove the audio file and any associated transcripts; no orphan rows or files are left.
- **FR-020**: Craft-generated items MUST participate in the existing sync queue using provider value `craft`; no separate sync path is introduced.
- **FR-021**: User-facing copy for Craft (mode labels, hints, errors, badges) MUST live in ARB localization files (English + Chinese baseline) and MUST follow the existing localized patterns from the import flows and AI surfaces.
- **FR-022**: All failure copy MUST be friendly and actionable (Retry / Switch mode / Open AI settings / Open sign-in); raw exception text MUST NOT be the primary message.
- **FR-023**: Empty, whitespace-only, or trivially short input MUST disable the Craft action with an inline hint and MUST NOT issue any AI call.
- **FR-024**: When the learner is offline at Craft open, the flow MUST show an offline banner and disable the Craft action until connectivity returns; no AI call is attempted.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture (Craft lives in a dedicated feature module under `lib/features/craft/{application,data,domain,presentation}` with persistence via Drift DAOs); it MUST NOT shortcut across feature boundaries except via documented contracts.
- **QR-002**: Every behavior change MUST ship with automated tests or a documented manual-verification reason in the implementation plan.
- **QR-003**: Craft UI MUST reuse existing shared primitives (`EnjoyTappableSurface`, `EnjoyTappableIcon`, `EnjoyButton`, `showEnjoySheet`, `showEnjoyAlertDialog`, `AppNotice`) and existing import-flow patterns (`showContentLanguagePicker`, paste-from-clipboard affordance, blocking-import dialog). Icon-only actions MUST expose localized tooltips; keyboard affordances MUST remain documented.
- **QR-004**: The Craft flow MUST remain responsive while translate + synthesize run on supported platforms. Translation + synthesis for ~500 characters of text MUST complete on a normal connection in under **30 seconds** for the headline flow; partial progress must keep the import-blocking dialog cancellable / clearly bounded.
- **QR-005**: Synthesized audio bytes MUST be written to local storage in a worker isolate or via streaming write so the import-blocking dialog never freezes the UI thread on long inputs.
- **QR-006**: Re-opening a previously Crafted item MUST be instantaneous (no re-translate, no re-synthesize); results are stored as durable media + transcript rows.
- **QR-007**: Feature behavior changes MUST update `docs/features/library.md`, `docs/features/ai.md`, `docs/features/transcript.md`, and `docs/features/settings.md` in the same change; a new ADR MUST be added at `docs/decisions/0043-craft-from-text-import.md` capturing the import-flow decision (single entry, two modes, BYOK parity for TTS, provider value `craft`).
- **QR-008**: Tests MUST cover: Translate then speak end-to-end on a stub translation + stub TTS; Speak directly end-to-end; same-language switch affordance; TTS-stage failure discards translation; save-stage failure discards audio; dedupe on repeated input; deletion cleanup; library badge; TTS BYOK vendor routing.
- **QR-009**: Generated Drift schema changes (if any) MUST regenerate `*.g.dart` via `dart run build_runner build` and the outputs MUST be committed in the same change.

### Key Entities

- **Craft media item**: A new audio media item in the user's library (`AudioRow`, provider `craft`) created from text via the Craft flow. Has a primary transcript in the learning language, an optional secondary transcript in the source language, and a locally stored audio file. Participates in the existing sync queue like any other audio item.
- **Craft source text**: The literal text the learner pasted into the Craft flow. Persisted as `Audios.sourceText` so it is recoverable even after the secondary transcript is removed.
- **Craft source language**: The language the learner indicated for the input text in Translate then speak mode (or null / equals learning language in Speak directly). Persisted as a fingerprint on the secondary transcript for cache / staleness checks.
- **Craft mode**: One of `translateThenSpeak` or `speakDirectly`. Persisted as part of the secondary transcript `source` value (`'ai'` is reused per spec 009; the source-text presence distinguishes Craft from auto-translate) and as `Audios.source` value (`'craft'` or `'craft-direct'`).
- **Craft job (logical)**: The in-flight work for one Craft attempt (translate → synthesize → write file → write transcripts). Owned by the Craft controller; cancellable; idempotent on retry.
- **TTS BYOK config**: The existing per-modality BYOK bundle for TTS (vendor: OpenAI-compatible or Azure; base URL; API key; model / voice defaults; region for Azure), promoted from P3 to a first-class setting card. No new fields are introduced; this requirement surfaces it.
- **Translation BYOK config**: The existing LLM BYOK config (spec 003). Reused unchanged by Craft; documented as the dependency that drives Translate then speak.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In usability checks, at least **90%** of participants can find and start Craft from text from the import chooser in under **30 seconds** without help, on first try across Android, iOS, macOS, and Windows.
- **SC-002**: Translate then speak on a ~300-character English sample targeting the user's profile learning language produces a playable audio item in the library within **30 seconds** on a normal connection (Enjoy AI default), with primary transcript in the target language and source-text secondary transcript present.
- **SC-003**: Speak directly on a ~200-character learning-language sample produces a playable audio item within **20 seconds** on a normal connection (Enjoy AI default) with primary transcript equal to the entered text.
- **SC-004**: TTS BYOK end-to-end (OpenAI-compatible) on a ~200-character sample completes without invoking Enjoy worker TTS routes; the resulting audio is produced by the configured vendor.
- **SC-005**: **100%** of failure states (network drop, BYOK unconfigured, credits exhausted, save failure) surface a localized, actionable message — no raw exception text in the primary message; no silent half-imported rows in regression checks.
- **SC-006**: Re-opening a previously Crafted audio item shows transcripts and audio in under **1 second** with no re-translate / re-synthesize call.
- **SC-007**: Craft-generated items show the **Craft** badge in the library grid in **100%** of regression checks across Android, iOS, macOS, and Windows.
- **SC-008**: All new Craft user-facing strings exist in English and Chinese ARB files; **100%** of them follow the existing import / AI copy patterns (calm, actionable, no jargon).
- **SC-009**: Same-text dedupe: pasting the exact same input twice does NOT create a duplicate audio row in **100%** of regression checks; the second attempt surfaces **Already in your library** with an **Open** action.
- **SC-010**: TTS-stage failure discards the translation result in **100%** of regression checks; no orphan `Transcripts` rows are left behind when synthesize fails.
- **SC-011**: Delete on a Craft-generated item removes the audio file and any associated transcripts in **100%** of regression checks; no orphan files remain in app storage.
- **SC-012**: Switching TTS modality from BYOK back to Enjoy AI takes effect on the next Craft run without an app restart, matching spec 003 SC-006.
- **SC-013**: The Craft entry is reachable in **≤ 2 taps** from the Home or Library screen (one tap on Import, one tap on Craft from text) on every supported platform.

## Assumptions

- The chosen entry label is **Craft from text** (localizable via ARB; English baseline). The canonical storage value is `craft`. The short feature directory name is `craft-from-text`. Alternate labels ("Homecook", "Make from text", etc.) can be substituted by editing ARB strings without schema changes — the spec is label-agnostic.
- The chosen provider value `craft` is stored in `AudioRow.provider`. Library badges, sync routing, and provider-specific UI keys off this value. No new migration is required because the column already accepts any string (Drift `Audios.provider` is `text().withDefault(const Constant('user'))`).
- Craft stores source text in `Audios.sourceText` (column already exists) and the source-language pick in the secondary transcript's `referenceId` for cache keying. No new columns are required.
- TTS BYOK is promoted to a first-class setting card in this change. The capability layer (`byok_tts_openai_capability.dart`, `byok_tts_azure_capability.dart`, the OpenAI speech client, and the Azure Speech SDK / REST wiring) already exists in spec 003; this change only adds the AI settings UI surface (already mirrored from spec 003 for ASR / assessment) and the Craft user flow that exercises it.
- Speak directly mode does not use translation at all; no LLM call is issued. Translate then speak mode uses the existing `TranslationService` (LLM-backed, BYOK-aware).
- V1 does not expose per-call voice selection in the Craft flow. The TTS vendor's default voice for the target language is used (OpenAI TTS default `alloy` for OpenAI-compatible; provider-default voice for Azure Speech). Per-vendor voice preferences live in AI settings later if needed.
- V1 uses a hard length cap with a clear truncation notice rather than chunked synthesis; chunking is documented as a future enhancement (concatenation of TTS clips with silence padding). The exact cap is a tuning detail (≈5 000 characters as a starting point) — it lives in the implementation plan.
- Echo / shadow-reading mode works out of the box because Craft creates a real audio media item with a primary transcript. No echo-specific wiring is required.
- Craft does not introduce a new top-level route. The flow is reached exclusively from the import chooser sheet, consistent with the user's "redesign the UX" requirement.
- Title for the new audio item is auto-generated from the first ~40 characters of the primary transcript (the learning-language text), with an ellipsis if truncated. The learner can rename later via existing media-edit affordances.
- Craft inherits existing sign-in, credits, and Pro-tier rules from spec 003 / spec 002 — there is no Craft-specific tier or credit type.
- Web targets remain out of scope per product platform policy.
- Cloud sync of Craft items uses the existing audio sync path (provider `craft` participates in the same SyncEnqueueFn calls as `user` and `youtube`); no separate sync logic is added.

## Dependencies

- Existing import chooser sheet (`lib/features/library/presentation/library_actions.dart`) and content language picker (`lib/features/library/presentation/widgets/content_language_picker.dart`).
- Existing translation / LLM capability layer (`lib/features/ai/`) — `TranslationService`, `translationCapabilityProvider`, including all BYOK vendors from spec 003.
- Existing TTS capability layer (`lib/features/ai/`) — `TtsService`, `ttsCapabilityProvider`, plus the BYOK TTS implementations (`byok_tts_openai_capability.dart`, `byok_tts_azure_capability.dart`) and the OpenAI speech client.
- Existing AI settings UI (`lib/features/ai/presentation/settings/ai_providers_screen.dart` and the per-modality cards) — promote TTS card to first-class.
- Existing media library persistence (`MediaLibraryRepository`, Drift `AudioRow`, Drift `Transcripts`, file storage) — extend `MediaLibraryRepository` with a `importCraftedFromText(...)` method.
- Existing AI provider / BYOK error handling (`byok_not_configured_failure.dart`, `ai_byok_error_mapping.dart`, `ai_api_failures.dart`).
- Existing localization infrastructure (`lib/l10n/app_en.arb`, `app_zh_CN.arb`).
- Existing audio player + echo flows (no change; Craft integrates via the standard media path).

## Reference (Enjoy monorepo)

| Area | Enjoy reference | Player port |
|------|-----------------|-------------|
| Smart translation flow | `apps/web/src/routes/smart-translation.tsx`, `apps/web/src/hooks/ai/use-smart-translation.ts`, `packages/ai/src/services/smart-translation-service.ts` | Reused as the "Translate then speak" half of the Craft flow via `TranslationService`; no standalone route. |
| Voice synthesis flow | `apps/web/src/routes/voice-synthesis.tsx`, `apps/web/src/hooks/ai/use-tts.ts`, `packages/ai/src/services/tts-service.ts` | Reused as the synthesis step for both Craft modes via `TtsService`; no standalone route. |
| Voice / language pickers | `apps/web/src/components/voice-synthesis/voice-selector.tsx`, `apps/web/src/components/smart-translation/language-selector.tsx` | Not ported as standalone pickers in v1; defer per-call voice selection; language selection reuses `showContentLanguagePicker`. |
| TTS BYOK wiring | `apps/web/.../byok-config.tsx`, `packages/ai/src/capabilities/tts/byok.ts`, `packages/ai/src/capabilities/tts/byok-azure.ts` | Already ported as `byok_tts_openai_capability.dart` / `byok_tts_azure_capability.dart`; this change only promotes the AI settings surface. |
| TTS cache / dedupe | `apps/web/src/db/repositories/tts-cache-repository.ts`, `apps/web/src/types/db/tts-cache.ts` | Replaced by Drift `AudioRow` + content-hash dedupe in `MediaLibraryRepository.importCraftedFromText`. |