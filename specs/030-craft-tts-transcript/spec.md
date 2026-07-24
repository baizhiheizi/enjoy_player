# Feature Specification: Craft TTS Transcript Quality

**Feature Branch**: `030-craft-tts-transcript`

**Created**: 2026-07-24

**Status**: Draft

**Input**: User description: "For now, let's fix the Azure TTS to make the transcript as correct as possible. If it's still not perfect, user could use STT to re-generate it. Help me to improve the flow. Defer the force alignment flow."

## Clarifications

### Session 2026-07-24

- Q: When synthesis cannot produce a solid timed transcript, what should Craft save? → A: Leave the transcript blank; the learner generates it later in the player with speech-to-text. Do not fabricate coarse estimated cues.
- Q: What counts as a “solid” transcript worth saving from synthesis? → A: Non-empty word timings plus the improved segmenter emitting ≥1 valid line (after punctuation fixes); otherwise blank.

## Scope

### In scope

- Improve how Craft turns synthesized speech into a time-aligned practice transcript so lines break at natural sentence (or short phrase) boundaries and punctuation does not appear at the start of a line — **only when solid word timings are available**.
- Preserve the learner’s crafted practice text as the transcript wording whenever a synthesis-built transcript is saved (do not replace that text with a speech-to-text rewrite during Craft save).
- When a solid timed transcript cannot be built, save the Craft audio **without** a primary timed transcript (blank / empty transcript state) so the learner can generate one in the player via speech-to-text.
- Ensure Craft library items remain first-class for the existing “generate transcript with speech-to-text” path (including the empty-transcript entry).
- Make generating a transcript via STT discoverable for Craft items that saved without cues, and for items whose synthesis cues the learner still wants to replace.

### Out of scope

- **Forced alignment** (local or cloud) that re-times known text against audio with a dedicated aligner — deferred; may be specified later.
- **Fabricated / proportional duration estimation** as a substitute primary transcript when word timings are missing or not solid.
- **Changing the default Craft TTS provider** (e.g. switching Enjoy default away from the current Azure-backed path) or adding Deepgram TTS.
- **New TTS vendors** (ElevenLabs, Cartesia, etc.) solely for character/word alignment APIs.
- **Automatic silent STT after every Craft save** — generation stays user-initiated in the player.
- **Editing transcript line text inside Craft before save** beyond existing rewrite/synthesize text editing.
- **Changing echo-mode interaction design** beyond benefiting from better cue boundaries when a transcript exists.
- **Linux-specific TTS plugin work** beyond whatever the shared transcript-building path already does with available timings.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Craft cues break cleanly on sentences (Priority: P1)

A learner synthesizes a short paragraph with normal punctuation (periods, question marks, etc.) in Express or Advanced Craft on a path that supplies solid word timings. After save, they open the item in the player: each transcript line starts with a word (never a lone punctuation mark), sentence-ending punctuation stays with the sentence it belongs to, and lines follow sentence boundaries rather than arbitrary mid-phrase cuts whenever the text has clear sentence endings.

**Why this priority**: Wrong line breaks and leading punctuation break shadow reading and echo practice; this is the core quality complaint with today’s Craft transcripts.

**Independent Test**: Craft a multi-sentence paragraph (≥2 sentences, ≥12 words) with Enjoy default TTS on a platform that supplies word timings; open the primary transcript and verify no line starts with punctuation-only text and that sentence ends align with line ends for well-punctuated input.

**Acceptance Scenarios**:

1. **Given** synthesis returns word timings that include standalone punctuation tokens, **When** Craft builds the saved transcript, **Then** no transcript line’s visible text starts with sentence-ending or clause punctuation alone (e.g. `.` `?` `!` `。` `？` `！`).
2. **Given** well-punctuated multi-sentence practice text, **When** Craft saves the item with solid timings, **Then** line boundaries prefer sentence endings over fixed word-count chops inside a sentence when a sentence end is available.
3. **Given** the same practice text used for synthesis, **When** the primary transcript is saved from synthesis timings, **Then** the transcript wording matches that practice text (modulo normal whitespace joining), not a speech-to-text rewrite.

---

### User Story 2 - No solid timings → blank transcript, generate in player (Priority: P1)

A learner synthesizes Craft audio on a path that cannot produce a solid timed transcript (for example, no word timings from synthesis). Craft still saves the audio successfully, but the item opens in the player with an **empty transcript** state. The learner uses the existing generate-transcript (speech-to-text) flow to create cues, then practices.

**Why this priority**: Fabricated duration-based cues are worse than none; blank + STT is the product rule for this release.

**Independent Test**: Complete Craft save on a path with no word timings; confirm audio is in the library, transcript panel shows the empty/generate state (no fake multi-line estimate), and STT generation can create a timed transcript.

**Acceptance Scenarios**:

1. **Given** synthesis completes without solid word timings, **When** Craft saves, **Then** the media item is saved with playable audio and **no** primary timed transcript lines (blank transcript / empty state).
2. **Given** a Craft item saved with a blank transcript, **When** the learner opens the player transcript UI, **Then** they can start speech-to-text generation using the same flow as other local audio with no transcript.
3. **Given** speech-to-text generation succeeds on that item, **When** practice continues, **Then** the new timed transcript is used and the Craft audio file is unchanged.
4. **Given** synthesis has no solid timings, **When** Craft saves, **Then** the app MUST NOT invent proportional sentence/character duration estimates as the primary transcript.

---

### User Story 3 - Replace imperfect synthesis cues with speech-to-text (Priority: P2)

After practicing a Craft item that **did** receive a synthesis-built transcript, a learner decides the cues are still not good enough. From the player’s transcript controls they start speech-to-text transcript generation for that media, wait for completion, and continue practice with the new timed transcript. The crafted audio file is unchanged.

**Why this priority**: Even improved word-timing cues are not guaranteed perfect; STT remains the escape hatch (and is the only path when the transcript was left blank).

**Independent Test**: Save a Craft item that has a synthesis-built transcript; from the player transcript UI run Generate / replace with ASR; confirm a new timed transcript replaces or supersedes the practice track per existing ASR rules and audio still plays.

**Acceptance Scenarios**:

1. **Given** a saved Craft media item with a synthesis-built transcript, **When** the learner opens transcript controls, **Then** they can start the same speech-to-text generation flow available for other local audio items.
2. **Given** speech-to-text generation succeeds, **When** the learner returns to practice, **Then** playback uses the new timed transcript and the original audio file is unchanged.
3. **Given** speech-to-text generation fails on an item that already had a synthesis-built transcript, **When** the error is shown, **Then** the previous synthesis transcript remains available.
4. **Given** speech-to-text generation fails on an item that had a blank transcript, **When** the error is shown, **Then** the transcript remains blank / empty-state (learner can retry).

---

### User Story 4 - Discover STT generate / replace for Craft (Priority: P2)

A learner who just finished Craft (or opened a Craft item) understands they can generate or replace transcript timings with speech-to-text in the player. When the transcript was left blank, the empty state itself is the primary CTA; when synthesis cues exist, a short non-blocking hint may point to replace-via-STT if needed.

**Why this priority**: Blank transcripts only work if generate-via-STT is obvious; replace remains discoverable when cues exist but feel wrong.

**Independent Test**: Save Craft with blank transcript → empty state offers generate; save Craft with synthesis cues → localized hint or controls mention replace/regenerate via speech recognition without implying automatic re-synthesis.

**Acceptance Scenarios**:

1. **Given** a Craft item saved with a blank transcript, **When** the learner opens the transcript panel, **Then** the empty/generate affordance is visible without requiring settings navigation.
2. **Given** a Craft item saved with a synthesis-built transcript, **When** the learner completes Craft or opens transcript controls, **Then** they can discover replace-via-STT (brief hint and/or existing generate control) without a new settings page.
3. **Given** the learner has dismissed a non-essential hint once, **When** they Craft again, **Then** the hint does not spam beyond the once-until-dismissed (or once-per-session) policy in Assumptions.

---

### Edge Cases

- Practice text that is one long unpunctuated sentence: when solid word timings exist, prefer readable phrase-sized chunks; avoid punctuation-only lines.
- Abbreviations and decimals (e.g. `Mr.`, `U.S.`, `3.14`): must not systematically create false sentence breaks that orphan the next word onto its own line more often than the previous behavior for the same input (document known residual limits in Assumptions).
- CJK text with full-width punctuation (`。！？`): sentence attachment and line-start rules apply the same as Latin punctuation.
- Very short text below Craft’s minimum length: existing Craft validation still blocks synthesis; no change required beyond not regressing.
- Re-synthesize with a different voice after editing text: rebuild transcript from the new synthesis result using the improved rules when solid; otherwise leave blank again.
- Editing an existing Craft history item and saving: update path uses the same solid-vs-blank policy as create (may clear a prior estimated transcript if the new save has no solid timings).
- BYOK OpenAI TTS (typically no word timings): save audio with blank transcript; learner generates via STT in the player.
- Paths that previously wrote a single full-duration estimated cue: that behavior is removed; blank + STT replaces it.
- Offline STT generate: existing ASR offline/error messaging applies; Craft audio remains playable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When Craft builds a primary transcript from solid synthesis word timings, the system MUST attach standalone punctuation tokens to the adjacent word/segment so that no saved transcript line begins with punctuation-only text.
- **FR-002**: When Craft builds a primary transcript from solid synthesis word timings and the practice text contains sentence-ending punctuation, the system MUST prefer breaking lines at those sentence ends over breaking solely by a fixed word count inside a sentence.
- **FR-003**: When Craft builds a primary transcript from solid synthesis word timings, the system MUST keep the learner’s practice text as the source of wording (joined for display), not substitute a speech-to-text hypothesis at save time.
- **FR-004**: A synthesis transcript is solid only when word timings are non-empty and the improved segmenter emits ≥1 valid line. When that gate fails, the system MUST save the Craft audio with a blank primary transcript (no timed lines) and MUST NOT write fabricated proportional duration estimates as cues.
- **FR-005**: Craft save (create and update-edit) MUST use the improved transcript builder when solid timings exist, and the blank-transcript policy otherwise, for both Express and Advanced synthesize paths.
- **FR-006**: Learners MUST be able to run the existing local-media speech-to-text transcript generation against saved Craft items (blank or synthesis-built) without re-running Craft TTS.
- **FR-007**: After a failed speech-to-text attempt, the system MUST preserve the prior state: keep the previous synthesis transcript if one existed; keep blank if none existed.
- **FR-008**: For Craft items with a blank transcript, the player transcript empty/generate affordance MUST be available. For items with synthesis-built cues, the product MUST keep replace-via-STT discoverable (existing controls and/or a brief localized hint).
- **FR-009**: Forced alignment MUST NOT be required for this feature; no user-facing promise of forced-alignment quality is introduced.
- **FR-010**: Improving cue quality MUST NOT change Craft audio storage identity (`provider` / source flags) or remove Craft badge behavior.
- **FR-011**: Craft save MUST succeed for audio even when the transcript is left blank (blank transcript is not a save failure).

### Key Entities

- **Craft practice text**: The learning-language text the learner confirmed before synthesis (Express rewrite output or Advanced synthesize input). Source of transcript wording when a synthesis-built transcript is saved.
- **Synthesis timing tokens**: Ordered spoken units with start/duration from the TTS path when available; may include standalone punctuation tokens.
- **Solid timed transcript**: A primary transcript saved only when synthesis returns a non-empty word-timing list and the improved segmenter emits at least one valid non-empty line (after punctuation attachment). Otherwise the transcript is blank.
- **Blank transcript**: Craft media with playable audio and no primary timed lines; learner fills via player STT.
- **Speech-to-text generate / replace**: User-initiated generation of a timed transcript from the Craft audio file via the app’s existing ASR transcript flow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a fixed set of ≥10 well-punctuated multi-sentence Craft samples with solid word timings available, **100%** of saved transcript lines have non-empty text that does not start with punctuation-only characters from the set `.?!。！？`.
- **SC-002**: On that same sample set, **≥90%** of sentence-ending marks in the practice text coincide with a transcript line end (allowing phrase sub-chunks inside long sentences).
- **SC-003**: On paths without solid word timings, **100%** of Craft saves in a fixed sample set store **zero** primary timed transcript lines (blank), while audio remains playable.
- **SC-004**: In moderated usability checks with ≥5 learners familiar with Craft, **≥4** can start STT generate from a blank Craft transcript (or replace from a synthesis transcript) within **30 seconds** without assistance.
- **SC-005**: Craft save latency for typical short paragraphs (under ~500 characters) does not regress by more than **10%** wall time versus the prior builder on the same device class (manual before/after note acceptable).
- **SC-006**: Zero Craft save failures introduced solely by the new transcript builder or blank-transcript policy across automated tests covering punctuation attachment, sentence preference, and blank-when-not-solid behavior.

## Assumptions

- Enjoy’s default Craft TTS remains the current Azure-backed Enjoy path; this feature improves transcript construction and blank/STT UX, not vendor switching.
- Existing ASR transcript generation for local audio (short-clip and long-form rules) already applies to Craft audio files; this feature does not invent a separate ASR product.
- STT generate/replace may change transcript wording relative to the crafted text; that trade-off is acceptable when the learner explicitly chooses STT.
- Echo / shadow features that require cues simply wait until a transcript exists (empty state), matching other local media without subtitles.
- Hint frequency for non-empty synthesis cues defaults to once until dismissed (or once per app session); blank items rely primarily on the empty-state CTA.
- Abbreviations and numeric decimals may still create occasional false breaks when a solid transcript is built; eliminating all linguistic edge cases is not required for v1.
- Forced alignment remains a future option if synthesis cues + STT still fall short for some languages.
- Documentation updates (`docs/features/craft.md` and related) ship with the behavior change per project governance.
- “Solid” means non-empty synthesis word timings and ≥1 valid segmented line after punctuation fixes; a single timed line for unpunctuated text is allowed when timings exist.

## Dependencies

- Existing Craft synthesize → save pipeline (Express and Advanced).
- Existing player transcript empty state and subtitle controls that launch ASR generation for local media.
- Existing localization pipeline for any new hint strings.
