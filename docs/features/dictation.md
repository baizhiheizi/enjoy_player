# Feature: Dictation (Dictate lens practice)

## Summary

Dictation is the **listen-and-prove** practice loop that lives in the echo-region card while the **Dictate** lens is on. The user hears the looped cue with its reference words masked, then proves they understood it in one of two answer modes — a **voice retell** (transcribed by ASR) or **text** (type what you hear) — and the answer is diffed word-by-word against the reference text. The practice surface is [`DictationPanel`](../../lib/features/dictation/presentation/dictation_panel.dart) / [`DictationList`](../../lib/features/dictation/presentation/dictation_list.dart), hosted by the transcript's echo-region merged card ([`transcript_echo_region_merged_card.dart`](../../lib/features/transcript/presentation/transcript_echo_region_merged_card.dart)); the masked loop words and the post-check diff render through [`DictationBand`](../../lib/features/dictation/presentation/dictation_band.dart).

The Dictate lens itself (shape bars, hover / hold reveal, the `H` hotkey) is documented in [transcript.md § Dictate lens](transcript.md#dictate-lens-listening-focus-mode); the loop region it rides on is documented in [echo-mode.md](echo-mode.md).

## Surface and lens wiring

- The dictation card lives inside the **echo-region merged card** under the Dictate lens: the band replaces the loop's reference text, and the panel plus the history list mount between the loop and the shadow-reading panel. It therefore requires a **loop region** — entering Dictate arms (or reuses) a single-line Echo loop on the active cue ([`PlayerInteractions.toggleBlur`](../../lib/features/player/application/player_interactions.dart)), and leaving Dictate via `E` lands in Echo with that line looped (`toggleEcho`). The lens is derived — hideText alone → Dictate, echoActive alone → Echo ([`resolvePlayerLens`](../../lib/features/player/domain/player_lens.dart)) — so Echo ⇄ Dictate switches keep the loop and the practice state alive.
- The session (answer mode, text draft, active diff, selected attempt) is one provider per echo region — [`DictationSessionCtrl`](../../lib/features/dictation/application/dictation_providers.dart) keyed by `targetType` + `targetId` + reference window + reference text + language — so moving to another line or loop starts a fresh attempt session, while persisted attempts remain in the history list.
- Voice mode records through the **shadow-reading infrastructure**: `R` (or the dock Record control) pulses the same recording bus, the take persists as a first-class `RecordingRow` via `ShadowTakeStore`, and the takes strip / scoring keys stay live — see [shadow-reading.md](shadow-reading.md). Takes transfer seamlessly across Echo ⇄ Dictate. Keyboard hotkeys exist on desktop only, so the voice-mode copy is split: the desktop hint and **Record retelling** CTA append the `R` shortcut (`playerDictationVoiceHintHotkey` / `playerDictationRecordRetellingHotkey`), while touch platforms show the plain labels (`playerDictationVoiceHint` / `playerDictationRecordRetelling`).

## Answer modes

- **Voice retell** (`DictationInputMode.voice`): record the retell; on stop the take transcribes through [`AsrService`](../../lib/features/ai/application/ai_services.dart) with the loop's language tag as the hint. While transcribing the panel shows the checking state ("Transcribing speech…"); the recognized text then diffs against the reference. An empty transcription fails the attempt with "No speech detected" and a **Retry transcription** action re-runs ASR on the same take. Transcription is generation-guarded, so a retry supersedes an in-flight run instead of racing it.
- **Text** (`DictationInputMode.text`): a type-what-you-hear field with a live "**{typed} of about {total} words**" progress line; **Check answer** diffs the draft against the reference.

## Checking and scoring

- [`computeDictationDiff`](../../lib/features/dictation/domain/dictation_diff.dart) aligns reference and answer tokens (lower-cased, apostrophes and punctuation stripped) through an edit-distance alignment and labels every token **Correct / Missed / Extra**.
- Accuracy is `correct / (reference words + extra)` as a rounded percentage — extra invented words cost accuracy even when every reference word was reproduced.
- On check, the band reveals the reference words with the inline per-token diff plus the legend and stats ("{count} correct / missed / extra", "{accuracy}% accuracy"); **Try again** resets to a fresh attempt, and **Next line** advances playback to the next cue (`PlayerInteractions.nextLine`).

## Persistence

- Every checked attempt writes one row to the sync-ready `dictations` table via [`DictationDao`](../../lib/data/db/daos/dictation_dao.dart) — the reference window (`referenceStartMs` + `referenceDurationMs`), the reference text, the language, the user input, the diff stats and accuracy, `syncStatus: 'local'` (the table predates #1308; the schema itself is unchanged by it).
- The history list ("Previous dictations ({count})") watches the rows for the **exact echo region** (`watchByEchoRegion`); tapping a historical attempt re-shows its stored diff. The per-target watcher (`watchByTarget`) serves target-wide consumers.

## Requirements

- The Dictate lens (and therefore dictation) is disabled without transcript lines, like Echo.
- Voice retell additionally requires a working ASR service; text mode has no service dependency.
