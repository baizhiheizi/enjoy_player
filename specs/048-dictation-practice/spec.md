# Feature Specification: Dictation Practice (Voice Retelling & Text Input)

**Feature Branch**: `048-dictation-practice`

**Created**: 2026-11-11

**Status**: Draft

**Input**: User description: "我们来完善“听写”的功能。切换到听写模式时，字幕会被遮住，用户可以逐行进行听写（也可以多行，沿用跟读模式下的控制）。所谓“听写”，其实是“复述”，用户录音复述听到的句子。然后使用 asr 接口识别成文字，跟原文进行对比。用户也可以切换至文字输入的模式。如果使用录音，录音应该计入跟读记录，可回放，可评分。在听写模式下的录音，同样应该出现在跟读模式下。关于听写的相关功能，可以参考 ~/Projects/enjoy 中的实现，web 目前没有实现录音，只实现了文字输入听写。帮我设计完善这个功能。"

## Scope

### In scope

- **Loop-bound Dictation Mode (Dictate Lens)**: Switching to Dictation mode activates a bounded practice loop on the active transcript segment (single-line by default, expandable/shrinkable to multi-line using the same loop range controls and shortcuts as Shadow Reading / Echo mode). Switching between Echo and Dictate preserves the active loop region; switching to Listen exits the loop.
- **Hidden Reference & Karaoke Word Blocks**: While a dictation attempt is unchecked, context lines outside the loop are masked and the loop's reference words are hidden behind word-sized blocks that highlight in real time (karaoke progress) as the original media plays.
- **Voice Retelling Mode (Primary / Default)**: Learners record themselves repeating/retelling the heard sentence(s). The recording is automatically transcribed into text via speech-to-text (ASR) and compared word-by-word against the reference text.
- **Shared Shadow-Reading Recordings**: Every recording captured in Dictation mode is saved as a standard shadow-reading take for that segment. It counts toward practice records, can be replayed and scored (pronunciation assessment) directly in Dictation mode, and appears identically in Echo (Shadow Reading) mode.
- **Text Input Mode (Alternative)**: Learners can switch to a keyboard text-input mode to type what they heard, see a live word counter, and submit to check the word-level diff.
- **Word-Level Diff, Score Breakdown & History**: Checking an attempt (via voice retelling or text input) reveals the inline word-level diff inside the loop (correct, missed, and extra words with legend), displays an accuracy and word-count summary card with **Try again** and **Next line** actions, persists the dictation attempt, and shows previous dictation attempts for the current segment.

### Out of scope

- Adding voice recording dictation to the browser web app or browser extension (this specification covers the native cross-platform player app).
- Changing how pronunciation assessment scoring works on the server.
- Adding fill-in-the-blank (cloze) partial-word masking presets.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voice retelling dictation with automatic speech recognition and diff (Priority: P1)

A learner switches the player to **Dictate** mode while listening to an audio or video item. The active transcript line is framed in a practice loop with its words masked as proportional blocks, and surrounding lines are hidden. As the original audio plays, the hidden word blocks light up in rhythm with the speaker. The learner presses Record (via the dock button or keyboard shortcut) and retells the sentence aloud. When they stop recording, the app saves the audio take, transcribes their speech into text, and immediately reveals the word-by-word comparison in the loop (highlighting correct words, missed words in brackets, and extra spoken words struck through) along with an accuracy score and word-count breakdown. They can then tap **Try again** to repeat the same loop or **Next line** to advance the loop to the following sentence.

**Why this priority**: Voice retelling ("复述") is the core pedagogical workflow of dictation in this product—combining active listening, working-memory retelling, and immediate word-level feedback without forcing the learner to type on a keyboard.

**Independent Test**: Open a media item with a transcript, switch to Dictate mode, record a spoken retelling of the active line, and verify that the audio is transcribed, the loop transitions from hidden blocks to the word-level diff, the accuracy breakdown is displayed, and the dictation attempt is saved.

**Acceptance Scenarios**:

1. **Given** a media item with a transcript is open in the player, **When** the learner switches to Dictate mode (`H` or top-bar mode switch), **Then** the active line is placed into a practice loop with its words masked as word-sized blocks, translations/annotations inside the loop are hidden, and context lines outside the loop are masked.
2. **Given** Dictate mode is active and the attempt is unchecked, **When** the original media plays through the loop, **Then** the masked word blocks highlight progressively in time with the audio and playback pauses and rewinds at the end of the loop window.
3. **Given** Dictate mode is in Voice Retelling input mode, **When** the learner starts and stops a recording for the loop, **Then** the app shows a transcribing indicator, converts the recorded speech to text, and automatically checks it against the loop's reference text.
4. **Given** speech transcription completes with recognized text, **When** the check result is displayed, **Then** the loop reveals the inline word diff (correct words, missed words in brackets, extra words struck through, with a legend) and the panel below shows the accuracy percentage, Correct / Missed / Extra word counts, **Try again**, and **Next line** controls.
5. **Given** a checked dictation result is showing, **When** the learner activates **Next line**, **Then** the practice loop advances to the next transcript line, seeks playback to the start of that line, and resets the loop back to the unchecked masked-blocks state.

---

### User Story 2 - Unified recordings across Dictate and Echo modes (Priority: P1)

When a learner records a voice retelling in Dictate mode, that audio recording is stored as a first-class shadow-reading take for the active segment. Without leaving Dictate mode, the learner can replay their recording, request or view a pronunciation assessment score, or open the takes list. If the learner switches the mode selector from **Dictate** to **Echo** (or vice versa), the loop stays on the exact same line(s) and all takes recorded in Dictate mode are present in Echo mode (and takes recorded in Echo mode are visible in Dictate mode). The recording also counts toward the learner's overall practice statistics and per-line practiced indicators.

**Why this priority**: Recording in Dictate mode is spoken practice; fragmenting recordings between Dictate and Echo would force learners to record twice and lose their spoken history and pronunciation scores when switching lenses.

**Independent Test**: Record a take in Dictate mode, verify it appears in the takes summary row under the loop and can be replayed and scored, then switch to Echo mode on the same segment and verify the exact same take and score appear there and in practice statistics.

**Acceptance Scenarios**:

1. **Given** the learner finishes recording a voice retelling in Dictate mode, **When** the recording is saved, **Then** it is stored as a shadow-reading take for that segment and increments the segment's take count and the learner's practice statistics.
2. **Given** at least one take exists for the current loop in Dictate mode, **When** the learner views the area below the loop, **Then** they can replay the selected take, trigger or view pronunciation assessment (**Score** / **Assessment**), and open the full takes list.
3. **Given** the learner recorded a take in Dictate mode on line 5, **When** they switch the lens from **Dictate** to **Echo**, **Then** the loop remains on line 5 and the take recorded in Dictate mode is immediately listed and selected in Echo mode.
4. **Given** speech recognition fails (for example due to network unavailability or exhausted AI credits) after the learner stops recording in Dictate mode, **When** the error notice is shown, **Then** the recorded audio take is still preserved in the segment's takes list for replay and later pronunciation assessment or retry.

---

### User Story 3 - Multi-line loop control in Dictate mode (Priority: P2)

A learner wants to dictate a complete thought that spans two or three subtitle cues. In Dictate mode, they use the same loop expansion and contraction controls as in Echo mode (the `+ line` and `−` edge controls above and below the loop, or the `[` `]` `{` `}` keyboard shortcuts) to include multiple lines in the active loop. The masked word blocks, audio loop bounds, reference text for diffing, and saved recording/dictation time window all span the combined multi-line segment.

**Why this priority**: Subtitle cues frequently split sentences mid-clause; reusing Echo mode's multi-line loop controls gives learners consistent control over practice granularity.

**Independent Test**: Enter Dictate mode on a single line, expand the loop to include the next line using the `+ line` control or `]` shortcut, verify the masked blocks and loop duration update to cover both lines, and complete a dictation check against the combined text.

**Acceptance Scenarios**:

1. **Given** Dictate mode is active on a single line, **When** the learner activates the `+ line` control (or presses `[` / `]`), **Then** the adjacent line is added to the dictation loop, its words join the masked word blocks in the loop, and the audio loop window expands to cover all lines in the loop.
2. **Given** Dictate mode is active on a multi-line loop, **When** the learner activates the `−` control (or presses `{` / `}`), **Then** the corresponding edge line is removed from the loop and any active check state resets for the updated region.
3. **Given** a multi-line loop is active in Echo mode, **When** the learner switches to Dictate mode, **Then** the exact multi-line loop range is preserved in Dictate mode.
4. **Given** the learner clicks or taps a masked context line outside the current loop in Dictate mode, **When** the line is activated, **Then** the dictation loop moves to that line, seeks playback to its start, and resets the current check state.

---

### User Story 4 - Switchable Text Input dictation mode and attempt history (Priority: P2)

A learner is in a quiet environment (such as a library or transit) where speaking aloud is inconvenient, or wants to practice spelling specifically. They switch the dictation input mode from **Voice Retelling** to **Text Input**. A text field appears with a live word counter (`X of about Y words`) and a **Check Dictation** button. Pressing `Enter` (or tapping **Check Dictation**) compares their typed text against the reference sentence, displays the same inline word-level diff and accuracy breakdown, and saves the dictation attempt. Below the dictation controls, the learner can view their **Previous Dictations** for the current segment and inspect earlier attempts.

**Why this priority**: Text input provides parity with the web dictation experience and ensures dictation remains usable when microphone capture is undesirable or unavailable.

**Independent Test**: In Dictate mode, switch to Text Input mode, type a sentence with one missing word and one extra word, submit with `Enter`, and verify the word-level diff, accuracy stats, and Previous Dictations list update accurately.

**Acceptance Scenarios**:

1. **Given** Dictate mode is active, **When** the learner switches the input mode toggle to **Text Input**, **Then** a text input area is shown with a live word count hint (`typed of about total words`) and a **Check Dictation** action.
2. **Given** the learner is typing in Text Input mode, **When** they press `Enter` (outside of active IME composition) or activate **Check Dictation**, **Then** the typed text is compared against the reference text, the inline diff and score card are shown, and the dictation attempt is persisted.
3. **Given** the learner presses `Shift+Enter` in Text Input mode, **When** the key is pressed, **Then** a newline is inserted without submitting the dictation.
4. **Given** one or more previous dictation attempts exist for the active loop window, **When** the learner views the dictation area, **Then** a **Previous Dictations** section shows the attempt history (accuracy badge, correct/missed/extra counts, and recognized/typed text) and allows switching between past attempts.

---

### Edge Cases

- **Empty or silent speech recognition result**: If the learner records a take that produces an empty transcript from speech-to-text (e.g., silence or background noise only), the audio take is still saved to the takes list (with the existing silence warning when applicable), no empty dictation diff is committed, and the learner is informed that no speech was detected with an option to retry transcription or record again.
- **Speech recognition network failure or AI credits exhausted**: If speech-to-text fails due to connectivity or exhausted AI credits, the recorded WAV take remains safely saved and selectable in the takes row; the learner sees a clear error or credits notice and can either retry transcribing that take, switch to Text Input mode, or assess/replay the recording.
- **Punctuation, casing, and contractions in diffing**: Word comparison normalizes case and strips punctuation (while keeping contractions such as `don't` as a single word and stripping pure-punctuation tokens like `—`) so learners are never penalized for capitalization, commas, periods, orASR punctuation differences.
- **Extra words in accuracy calculation**: The accuracy denominator includes extra words (`correctWords / (totalReferenceWords + extraWords)`) so repeating or typing extra words reduces accuracy below 100%.
- **Switching loop lines or media mid-recording or mid-transcription**: Moving the loop, switching back to Listen mode, or closing the media while recording cancels the in-flight capture cleanly; if transcription is in flight when the loop moves, its stale result does not overwrite the new loop's state.
- **Last line of transcript**: When the loop ends on the final line of the transcript, the **Next line** button in the checked result card is disabled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Selecting the **Dictate** lens MUST activate a practice loop on the active transcript line (falling back to the first line if playback is before the first cue) if no loop is currently active, or preserve the existing loop region when transitioning from **Echo** mode.
- **FR-002**: Transitioning from **Dictate** to **Echo** MUST preserve the current single-line or multi-line loop region; transitioning from **Dictate** to **Listen** MUST deactivate both Dictate mode and the practice loop.
- **FR-003**: While in **Dictate** mode, the learner MUST be able to expand or shrink the loop across multiple lines using the same loop edge controls (`+ line` / `−`) and keyboard shortcuts (`[` `]` `{` `}`) as Echo mode, and playback MUST enforce the same loop boundaries (pause and rewind at segment end).
- **FR-004**: In **Dictate** mode, context lines outside the active loop (including the `+ line` edge rows) MUST mask their transcript and translation text as word-shape bars while remaining interactive so tapping a context line moves the loop to that line.
- **FR-005**: Inside the active loop in **Dictate** mode, while the current attempt is unchecked, the reference text MUST be rendered as a **Dictation Band** of word-sized blocks (one block per normalized word, sized proportionally to letter count without punctuation) that highlight progressively (current word, heard words, upcoming words) as the original media plays, with secondary translations and phonetic overlays hidden.
- **FR-006**: **Dictate** mode MUST support two user-selectable input modes—**Voice Retelling** (default) and **Text Input**—and allow switching between them before checking an attempt.
- **FR-007**: In **Voice Retelling** mode, starting and stopping a recording (via the dock Record button, dictation panel control, or recording shortcut `R`) MUST capture and persist a standard shadow-reading recording associated with the current loop's media target, language, reference text, start time, and duration, and enqueue it for cloud sync.
- **FR-008**: Recordings captured in **Dictate** mode MUST be shared with **Echo** mode: they MUST appear in the segment's takes summary row and takes list in both Dictate and Echo modes, support take playback (`G`) and pronunciation assessment (**Score** / `V`), and count toward transcript line practiced indicators and learner practice statistics.
- **FR-009**: Upon completing a recording in **Voice Retelling** mode, the system MUST automatically send the captured audio to the configured speech-to-text service using the media/practice language, display a transcribing progress state, and upon receiving non-empty recognized text, evaluate the word-level diff and persist a dictation record.
- **FR-010**: If speech-to-text fails (network error, provider error, or exhausted AI credits) or returns empty text after a recording in **Voice Retelling** mode, the system MUST keep the recorded take saved, surface a user-friendly notice (including the standard credits notice when applicable), and allow the learner to retry transcribing the saved take without re-recording.
- **FR-011**: In **Text Input** mode, the dictation panel MUST provide a multi-line text input, display a live word count compared to the reference word count (`typed of about total words`), submit on `Enter` (when not in IME composition) or **Check Dictation** button activation, and insert a newline on `Shift+Enter`.
- **FR-012**: Word-level diffing and scoring for both **Voice Retelling** and **Text Input** MUST normalize words consistently (case-insensitive, punctuation stripped, contractions preserved as single words) and compute:
  - **Correct words**: matched words in order.
  - **Missed words**: reference words omitted by the learner.
  - **Extra words**: words spoken or typed by the learner not present in the reference.
  - **Accuracy**: `round(correctWords / (totalReferenceWords + extraWords) * 100)`.
- **FR-013**: When an attempt is checked, the loop's **Dictation Band** MUST replace the hidden word blocks with the inline word-level diff (distinguishing correct words, bracketed missed words, and struck-through extra words, accompanied by a visual legend), and the panel below MUST display the accuracy percentage, Correct / Missed / Extra counts, a **Try again** action (resetting the check to start a new attempt on the same loop), and a **Next line** action (advancing the loop to the following line, disabled when at the final line).
- **FR-014**: Every completed dictation check (from either Voice Retelling or Text Input) MUST be persisted locally with target metadata, reference start/duration, reference text, language, user input text, accuracy, and word counts.
- **FR-015**: When previous dictation attempts exist for the active loop window (matching target, language, and overlapping time range), the dictation panel MUST display a **Previous Dictations** section showing past attempts (newest first, with accuracy badge, word stats, and input text) and allow the learner to inspect previous attempts.
- **FR-016**: Transcript line practiced indicators (the practiced dot in the transcript gutter and sentence ruler, and the practiced lines count) MUST reflect lines practiced via either shadow-reading recordings or dictation attempts.

### Key Entities

- **Dictation Attempt**: A persisted record of a completed dictation check (whether produced via Voice Retelling speech recognition or Text Input), holding target media reference, segment start/duration, reference text, language, recognized/typed user input, accuracy (0–100), and counts of correct, missed, and extra words.
- **Shadow-Reading Recording**: A persisted audio take captured on a loop segment, shared across Dictate and Echo modes, supporting audio replay, pronunciation assessment scoring, and cloud sync.
- **Dictation Check Result**: The active evaluation of an attempt shared between the loop's inline diff view and the score breakdown panel, containing the ordered word diff chunks, computed accuracy/word statistics, and the learner's input string.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Learners can complete a full voice-retelling dictation cycle (listen to loop → record spoken retelling → view transcribed word diff and accuracy score → advance to next line) without touching the keyboard text input.
- **SC-002**: **100%** of recordings captured in Dictate mode are immediately available for playback and pronunciation assessment in both Dictate mode and Echo mode on the same segment, with zero duplicate recording steps required.
- **SC-003**: Switching between **Echo** and **Dictate** preserves the active single-line or multi-line loop boundaries **100%** of the time.
- **SC-004**: Word-level diff accuracy and counts (Correct, Missed, Extra) match deterministically between the inline loop diff and the saved dictation record across both Voice Retelling and Text Input submissions.
- **SC-005**: When speech-to-text fails after a voice recording, **0%** of captured audio takes are lost—the recording remains playable and assessable, and transcription can be retried in one tap.

## Assumptions

- The existing speech-to-text service (supporting both default cloud speech recognition and user-configured speech providers) is used to transcribe short voice-retelling takes in Dictate mode.
- Shadow-reading recording storage and pronunciation assessment flows are shared between Dictate and Echo modes so both lenses read and write the same segment recordings.
- Local dictation storage already includes the fields needed to persist both speech-derived and typed dictation attempts per segment.
- Visual styling follows the established Duet Design System and aligns with the shared dictation band and dictation panel design in the Enjoy web app.
