# Feature Specification: Craft Voice-Express Redesign

**Feature Branch**: `028-craft-voice-express`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "Redesign the Craft (self-made materials) flow. As a language learner, I can't speak fluently not because my skills are poor, but because I don't have enough to say. When I have daily thoughts I want to express, I want to speak them in my native language, have the AI understand my real meaning and personal style, rewrite them idiomatically in my target language, generate audio, and save them as practice material — building a personal library of things I can genuinely say. The default input should be voice. The AI should infer my style automatically (not impose a fixed style). The old two-tool layout should be kept as Advanced mode for power users."

**Supersedes**: [011-craft-studio-redesign](../011-craft-studio-redesign/spec.md)

**Related**: [Design spec](../../docs/superpowers/specs/2026-07-23-craft-voice-express-design.md) | [Issue #439](https://github.com/baizhiheizi/enjoy_player/issues/439)

## Scope

### In scope

- **Dual-mode Craft screen** (`/craft`) with a segmented control: **Express** (default, voice-first linear flow) and **Advanced** (redesigned two-tool panel). Both modes share one controller state; switching mid-session preserves work.
- **Express mode — three-stage evolving canvas**:
  - **Stage 1 Capture**: voice-first input via microphone (default), text fallback. Captures native-language speech, transcribes via existing ASR.
  - **Stage 2 Rewrite**: single LLM call takes raw native transcript → idiomatic target-language rewrite. Default style "Auto" infers the user's personal style from input. Result is editable. Collapsible style chip for power-user override (literal / natural / casual / formal / simplified / detailed / custom).
  - **Stage 3 Audio**: TTS auto-generates audio with a sensible default voice. Inline preview player. Collapsed voice chip. Two save paths: "Practice now" (opens player) or "Say something else" (rapid-capture loop — saves + resets to Stage 1).
- **Advanced mode — redesigned Translate + Synthesize panels**: unified card styling, improved pickers, side-by-side on desktop/tablet, stacked on mobile. Includes the new "Auto" style. Full voice picker with Azure Neural voice chips.
- **"Auto" translation style**: a new default style where the AI reads the user's raw input, understands their real meaning and personal register/tone, and produces an idiomatic spoken-form rewrite in the target language that mirrors the learner's own voice.
- **Responsive layout**: Express uses a single centered column at all breakpoints. Advanced switches from stacked (phone) to side-by-side (tablet/desktop). Breakpoints match existing app patterns (<600px / 600-899px / ≥900px).
- Localization updates (English + Chinese ARB) for all new user-facing strings.
- New ADR documenting the voice-first dual-mode decision and the "Auto" style prompt strategy.
- Updates to `docs/features/` and the craft `README.md`.

### Out of scope

- Local / on-device AI for ASR, translation, or TTS — stays server-side per ADR-0014.
- Background music, video compositing — audio only.
- Cloud sync of BYOK secrets.
- Translation history or TTS history as separate tabs (deferred).
- Chunked synthesis for very long inputs (v1 truncates at 5,000 characters with a clear notice).
- Draft persistence when navigating back before saving (v1 does not auto-save drafts).
- OpenAI-compatible TTS voice picker in the Craft UI (BYOK OpenAI TTS still works via AI settings; the Craft voice picker lists Azure Neural voices only).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a thought by speaking (Express, voice-first) (Priority: P1)

A learner is going about their day and has a thought they want to be able to express in their target language — "I want to grab an onigiri from the convenience store after work and watch that new drama." They open Import → Craft from text, land on the Express screen, tap the large microphone button, and speak naturally in their native language — fragments, half-sentences, rambling is fine. They tap stop. The raw transcript appears (muted/grey). The flow auto-advances to the rewrite stage.

**Why this priority**: Voice-first capture is the core differentiator. Without it, the feature is just a prettier version of the existing text-paste flow. This is the hero user story.

**Independent Test**: Open Craft on any platform, tap the mic button, speak a sentence in the native language, tap stop. Confirm a raw transcript appears and the flow advances to the rewrite stage.

**Acceptance Scenarios**:

1. **Given** the Craft screen in Express mode, **When** the learner first sees it, **Then** a large microphone button is centered, the language pair (native → learning) is displayed above it, and a "type instead" fallback link is visible below.
2. **Given** the Craft screen in Express mode, **When** the learner taps the mic button, **Then** recording starts — a red stop button replaces the mic, a live timer counts up, and a waveform animation is visible.
3. **Given** recording is active, **When** the learner taps the stop button, **Then** recording stops, the audio is transcribed, and the raw transcript appears (muted/italic) above the rewrite area.
4. **Given** the Craft screen, **When** the learner taps "type instead", **Then** a text input replaces the mic area; text entered here feeds directly into the rewrite stage without an ASR call.
5. **Given** the learner's profile, **When** the Craft screen initializes, **Then** the source language defaults to the profile native language and the target language defaults to the profile learning language.

---

### User Story 2 - Get an idiomatic rewrite in "Auto" style (Priority: P1)

After capturing their thought, the learner sees the AI's rewrite in the target language. Because the default style is "Auto", the AI has read their raw native speech, understood their real meaning and personal style, and rewritten it the way they would actually say it as a fluent speaker — idiomatic, conversational, preserving their intent and personality. The learner can edit the result, switch styles via a collapsible chip, regenerate, or proceed to audio generation.

**Why this priority**: "Auto" style is what makes the library feel like the learner's own voice in another language — the key differentiator from a generic translator.

**Independent Test**: Record or type a native-language thought, confirm the rewrite appears in the target language with a spoken/conversational tone matching the input register, edit it, and switch to a different style to see the difference.

**Acceptance Scenarios**:

1. **Given** the learner has captured a native-language thought (voice or text), **When** the rewrite completes, **Then** the target-language text appears in an editable field, with the raw native transcript shown muted above for reference.
2. **Given** the rewrite result, **When** the learner looks at the style chip, **Then** it shows "Auto ✨" as the default and can be expanded to reveal: literal, natural, casual, formal, simplified, detailed, custom.
3. **Given** the rewrite result, **When** the learner taps into the target text field, **Then** they can edit it inline (fix words, adjust phrasing); the edited text is what gets passed to audio generation.
4. **Given** the rewrite result, **When** the learner changes the style and taps "Regenerate", **Then** a fresh rewrite replaces the current result using the new style.
5. **Given** the rewrite result, **When** the learner taps "Re-record", **Then** the flow returns to Stage 1 (capture) and the mic re-activates.

---

### User Story 3 - Generate audio and save to library (Priority: P1)

After confirming the rewrite, the learner taps "Generate audio". TTS runs automatically with a sensible default voice for the target language. An inline preview player appears with a collapsed voice chip. The learner can preview, expand the voice chip to pick a different voice and re-synthesize, or proceed to save. They choose "Practice now" (opens the player for shadow reading) or "Say something else" (saves and loops back to capture for the next thought).

**Why this priority**: Without audio generation and the rapid-capture loop, the feature does not produce rehearseable material or encourage library-building.

**Independent Test**: Complete a rewrite, tap "Generate audio", hear the preview, tap "Say something else", confirm a toast appears and Stage 1 resets. Then tap "Practice now" on a second item and confirm the player opens.

**Acceptance Scenarios**:

1. **Given** the learner has confirmed a rewrite, **When** they tap "Generate audio", **Then** TTS produces audio automatically and a preview player appears inline with a progress bar and time labels.
2. **Given** the preview player, **When** the learner taps play/pause, **Then** the audio responds; the progress bar tracks position.
3. **Given** the preview player, **When** the learner expands the voice chip and selects a different voice, **Then** re-synthesis produces new audio with the selected voice.
4. **Given** the preview player, **When** the learner taps "Practice now", **Then** the item is saved to the library and the player opens with the new audio item ready for shadow reading.
5. **Given** the preview player, **When** the learner taps "Say something else", **Then** the item is saved, a brief confirmation toast appears, and Stage 1 resets (mic re-activates) for the next capture.

---

### User Story 4 - Advanced mode for prepared text (Priority: P2)

A power learner already has a block of target-language text (a textbook passage, a dialogue) and wants to synthesize it directly. They switch to Advanced mode via the segmented control. The redesigned Translate + Synthesize panels appear — side-by-side on desktop, stacked on mobile. They can paste text, pick style and voice, translate, edit, send to synthesis, preview, and save — with full manual control over each step.

**Why this priority**: Power users with prepared text need the manual path. Express doesn't serve this well. Keeping Advanced honors both audiences without cluttering the primary experience.

**Independent Test**: Switch to Advanced mode, paste target-language text into the Synthesize panel, pick a voice, synthesize, preview, and save to library.

**Acceptance Scenarios**:

1. **Given** the Craft screen, **When** the learner taps "Advanced" in the segmented control, **Then** the redesigned Translate + Synthesize panels replace the Express flow; switching back to Express preserves any in-progress work.
2. **Given** Advanced mode on desktop/tablet, **When** the learner views the layout, **Then** Translate and Synthesize panels are side-by-side; on phone they are stacked vertically.
3. **Given** the Translate panel, **When** the learner opens the style dropdown, **Then** "Auto ✨" appears as the first option alongside the existing presets.
4. **Given** the Synthesize panel, **When** the learner pastes target-language text and taps Synthesize, **Then** audio is produced and a preview player with a full voice picker appears.
5. **Given** a synthesized preview in Advanced mode, **When** the learner taps Save to library, **Then** the item is saved and the player opens with the new audio item.

---

### User Story 5 - Responsive layout across devices (Priority: P2)

The Craft screen adapts cleanly to phone, tablet, and desktop. Express mode uses a single centered column at all sizes (only max-width and spacing scale). Advanced mode switches from stacked (phone) to side-by-side (tablet/desktop). All controls, text, and touch targets remain comfortable on every breakpoint.

**Why this priority**: The app supports five platforms (Android, iOS, macOS, Windows, Linux). Layout must work from 375px phone to 1200px+ desktop.

**Independent Test**: Open Craft in Express and Advanced modes at 375px, 768px, and 1200px widths. Confirm layouts are appropriate, text is readable, and buttons are tappable at each size.

**Acceptance Scenarios**:

1. **Given** Express mode at phone width (<600px), **When** the learner views any stage, **Then** content uses full width with 14px gutters; all elements are comfortably sized for touch.
2. **Given** Express mode at tablet width (600-899px), **When** the learner views any stage, **Then** content is centered with max-width 400-420px and 20px gutters.
3. **Given** Express mode at desktop width (≥900px), **When** the learner views any stage, **Then** content is centered with max-width 420-480px and 28px gutters.
4. **Given** Advanced mode at phone width, **When** the learner views the layout, **Then** Translate and Synthesize panels are stacked vertically with a directional indicator between them.
5. **Given** Advanced mode at tablet or desktop width, **When** the learner views the layout, **Then** Translate and Synthesize panels are side-by-side.

---

### User Story 6 - Calm failure and recovery (Priority: P2)

ASR fails (network drop), the LLM rewrite returns an error, TTS fails (BYOK misconfigured, credits exhausted), or the save step fails. In every case the learner sees a calm, localized message naming the stage that failed and offering a concrete next action (Retry / Re-record / Open AI settings / Sign in). No raw exception text. No phantom audio or transcript is left behind.

**Why this priority**: Craft is the first AI authoring surface in the player. Broken failure UX poisons the feature.

**Independent Test**: Force ASR failure (offline), LLM failure (misconfigured), and TTS failure (BYOK unconfigured). Confirm each surfaces the right action without orphans.

**Acceptance Scenarios**:

1. **Given** the learner is recording or has just stopped, **When** ASR fails (network drop), **Then** a calm message appears with Retry; no partial transcript is shown.
2. **Given** the rewrite stage, **When** the LLM call fails, **Then** the rewrite area shows a calm message with Retry and a suggestion to try a different style.
3. **Given** the audio stage, **When** TTS fails (BYOK misconfigured or credits exhausted), **Then** a calm message names TTS as the failing stage and offers "Open AI settings" when BYOK is the cause.
4. **Given** any stage, **When** the learner is signed out or the token expires, **Then** the existing sign-in affordance is shown; no silent failure.
5. **Given** a save failure, **When** the error surfaces, **Then** no orphan audio file or transcript row is left in storage.

### Edge Cases

- Empty or very short recording (< 1 second): ASR is not called; the learner is asked to try again.
- ASR returns empty or near-empty transcript: the learner is asked to re-record; no rewrite call is made.
- Empty, whitespace-only, or trivially short text input (< 10 characters): the rewrite / synthesize action is disabled with an inline hint.
- Text > 5,000 characters: truncation notice shown; only the first 5,000 characters are processed.
- TTS vendor does not support the target language: voice picker shows "no voices for this language" and the synthesize action is disabled with guidance.
- Rapid re-rewrite / re-synthesize: the latest request wins; stale results are discarded (generation counter).
- User navigates back before saving: unsaved work is lost (no draft persistence in v1).
- Same content saved twice (same text, same voice, same language): dedupe surfaces "Already in your library" with an Open action.
- Microphone permission denied: a calm message guides the learner to system settings to grant permission.
- Device offline at Craft open: ASR and LLM calls fail with a calm network error; text editing and style selection remain available.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Craft screen MUST offer two modes via a segmented control in the app bar: **Express** (default) and **Advanced**. Switching modes MUST preserve any in-progress work in the shared controller state.
- **FR-002**: Express mode MUST default to voice input: a large, centered microphone button. A "type instead" fallback MUST be available to switch to text input.
- **FR-003**: Express mode voice capture MUST record native-language audio using the existing microphone infrastructure (16kHz mono WAV). A live timer and waveform animation MUST be visible during recording.
- **FR-004**: On recording stop, Express mode MUST transcribe the audio via the existing ASR service and display the raw transcript (muted/italic) above the rewrite area.
- **FR-005**: Express mode text entry (fallback path) MUST skip ASR and feed the entered text directly into the rewrite stage.
- **FR-006**: The rewrite stage MUST produce a target-language rewrite via a single LLM call that takes the raw native transcript (or text) and outputs an idiomatic spoken-form result.
- **FR-007**: The default rewrite style MUST be "Auto" — the AI infers the user's personal style from the raw input and reflects it in the target-language output while staying idiomatic and natural-spoken.
- **FR-008**: The rewrite result MUST be editable inline by the learner.
- **FR-009**: A collapsible style chip MUST allow the learner to override "Auto" with: literal, natural, casual, formal, simplified, detailed, custom (custom reveals a free-form prompt input).
- **FR-010**: A "Regenerate" action MUST re-run the rewrite with the currently selected style. A "Re-record" action MUST return to the capture stage.
- **FR-011**: The audio stage MUST automatically generate TTS audio with a sensible default voice for the target language when the learner taps "Generate audio".
- **FR-012**: An inline preview player MUST appear after audio generation, with play/pause and progress tracking.
- **FR-013**: A collapsed voice chip MUST be visible next to the preview player; expanding it reveals the full voice picker for the target language.
- **FR-014**: Two save actions MUST be available after preview: "Practice now" (saves + opens the player) and "Say something else" (saves + resets to the capture stage for the next thought).
- **FR-015**: "Say something else" MUST show a brief confirmation toast upon saving before resetting the capture stage.
- **FR-016**: Advanced mode MUST present redesigned Translate and Synthesize panels: side-by-side on tablet/desktop (≥600px), stacked on phone (<600px).
- **FR-017**: The Advanced Translate panel MUST include: source/target language pickers with swap, style dropdown (with "Auto" as default), source text input, translate button, editable result, copy, re-translate, and "Send to synthesis".
- **FR-018**: The Advanced Synthesize panel MUST include: language picker, full Azure Neural voice picker (as filtered chips), text input (pre-filled from Translate), synthesize button, inline preview player, re-synthesize, and save to library.
- **FR-019**: The "Auto" style MUST use a system prompt that instructs the AI to understand the speaker's real meaning and personal style from the raw input and produce an idiomatic, conversational target-language rewrite preserving intent and personality.
- **FR-020**: Previous stages in Express mode MUST collapse to summary blocks (language pair + style + truncated text) when the learner advances, so the full context stays visible without overwhelming.
- **FR-021**: The Craft screen MUST be responsive: Express uses a single centered column at all breakpoints; Advanced switches layout at the 600px breakpoint.
- **FR-022**: Source language MUST default to the profile native language; target language MUST default to the profile learning language, in both modes.
- **FR-023**: All user-facing copy MUST be localized via ARB files (English + Chinese baseline) and MUST follow existing calm, actionable patterns.
- **FR-024**: All failure states MUST surface a calm, localized message with a concrete next action (Retry / Re-record / Open AI settings / Sign in). Raw exception text MUST NOT be the primary message.
- **FR-025**: Craft-generated items MUST persist via the existing `importCraftedFromText` path with `provider = 'craft'`. Dedupe, delete, and library badge behavior MUST match existing Craft items.
- **FR-026**: The source text persisted with each Craft item MUST be the raw native transcript (from ASR or text entry), preserved on the audio row's `sourceText` column for reference.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture (Craft lives in `lib/features/craft/{application,data,domain,presentation}` with persistence via Drift DAOs).
- **QR-002**: Every behavior change MUST ship with automated tests or a documented manual-verification reason.
- **QR-003**: Craft UI MUST reuse existing shared primitives (`EnjoyButton`, `EnjoyTappableSurface`, `showContentLanguagePicker`, existing badge slot) and follow localization / haptics / tooltip conventions.
- **QR-004**: Voice recording, ASR, LLM, and TTS calls MUST keep the UI responsive. Heavy operations (audio file write, audio decode for duration) MUST run off the main isolate.
- **QR-005**: The Express flow (capture → rewrite → audio generation) for a ~30-second recording targeting a common language MUST complete within **45 seconds** on a normal connection (Enjoy AI default), from tapping stop to preview player appearing.
- **QR-006**: Feature behavior changes MUST update `docs/features/`, the craft `README.md`, and a new ADR capturing the voice-first dual-mode and "Auto" style decision.

### Key Entities

- **Craft captured audio**: The raw native-language recording from the Express capture stage. Stored in-memory during the session; not persisted as a standalone artifact.
- **Craft raw transcript**: The ASR output from the captured audio (or the directly-entered text in fallback mode). Persisted as the audio row's `sourceText` for reference.
- **Craft rewrite**: The in-session target-language result of the LLM rewrite. Editable. What flows to audio generation and becomes the primary transcript.
- **"Auto" translation style**: A new default style preset where the AI infers the user's personal style from raw input and produces an idiomatic spoken-form target-language rewrite preserving intent and personality.
- **Craft screen mode**: One of `express` or `advanced`. Determines which UI layout is shown. Both modes share the same controller state.
- **Craft stage**: The position in the Express flow: `capture`, `rewrite`, `audio`, or `done`.
- **Craft media item**: The persisted artifact (`AudioRow`, provider `craft`) — identical entity to existing Craft items. Has a word-segmented timestamped primary transcript (from Azure word boundaries) and the raw native text on `sourceText`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least **90%** of participants can open Craft, record a native-language thought, and reach the rewrite stage within **20 seconds** on first try, on any supported platform.
- **SC-002**: The "Auto" style rewrite of a ~100-word native-language recording produces a target-language result that a fluent speaker rates as "natural and idiomatic" in at least **80%** of cases.
- **SC-003**: The full Express flow (capture → rewrite → audio generation) for a ~30-second recording completes within **45 seconds** on a normal connection (Enjoy AI default).
- **SC-004**: At least **70%** of participants who complete one Craft item choose "Say something else" (rapid-capture loop) at least once in a session, indicating the loop encourages library-building.
- **SC-005**: **100%** of failure states (ASR failure, LLM failure, TTS failure, save failure, sign-out mid-flow) surface a localized, actionable message — no raw exception text.
- **SC-006**: Craft-generated items show the Craft badge in the library grid in **100%** of regression checks and reopen instantly with audio + transcript (no AI calls).
- **SC-007**: The Craft screen renders correctly at 375px, 768px, and 1200px widths in both Express and Advanced modes, with no overflow, clipped text, or untappable controls.
- **SC-008**: Switching between Express and Advanced modes mid-session preserves all in-progress work (entered text, rewrite results, preview audio) in **100%** of cases.
- **SC-009**: Same-content dedupe: saving the same text + voice + language twice does not create a duplicate in **100%** of regression checks.

## Assumptions

- The existing ASR infrastructure (`AsrService` / `AsrCapability`, Enjoy AI Whisper and BYOK Azure/OpenAI) supports short-form native-language transcription for all profile native languages. No new ASR vendor is added.
- The existing `record` package and microphone permission (already used in shadow reading) cover Craft's voice capture needs. No new permission flow is required.
- The existing LLM infrastructure (`ChatService` / `ChatCapability`, Enjoy AI and BYOK) supports the "Auto" style system prompt and all other style prompts. No new LLM capability is added.
- The existing TTS infrastructure (`TtsService` / `TtsCapability`, Enjoy AI Azure and BYOK Azure) covers Craft's audio generation. The voice picker lists Azure Neural voices only in v1.
- The existing `MediaLibraryRepository.importCraftedFromText` method handles the new `sourceFlag = 'craft-express'` without schema changes (the `Audios.source` column already accepts any string).
- The Craft screen is reached exclusively from the import chooser at `/craft`. No new top-level route or home-screen entry is added.
- Title for a new Craft audio item is auto-generated from the first ~40 characters of the primary transcript, with ellipsis if truncated. The learner can rename later via existing media-edit affordances.
- Echo / shadow-reading mode works out of the box because Craft creates a real audio media item with a real timestamped transcript. No echo-specific wiring is required.
- V1 does not persist drafts when the learner navigates back before saving. Unsaved work is lost.
- V1 truncates text input > 5,000 characters with a clear notice. Chunked synthesis is a future enhancement.
- The rapid-capture loop resets the Express flow state but does NOT auto-save drafts — only completed items (those that reached the audio stage and were saved) are persisted.
- "Auto" style quality depends on the LLM's ability to infer register and tone from short informal input. Very short inputs (< 20 characters) may produce less personalized results; this is accepted in v1.
