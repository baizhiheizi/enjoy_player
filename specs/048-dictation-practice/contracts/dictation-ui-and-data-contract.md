# Contract: Dictation UI, Lens Transitions & Persistence

**Feature**: [spec.md](../spec.md) | **Date**: 2026-11-11

## 1. Lens & Loop Transition Contract (`PlayerInteractions` / `PlayerLens`)

| Current Lens | Action | Resulting Flags (`echoActive`, `hideText`) | Resulting `PlayerLens` | Loop Region (`startLine..endLine`) |
|---|---|---|---|---|
| `listen` | `selectLens(echo)` or `toggleEcho()` | `(true, false)` | `echo` | Activated on active line (or line 0) |
| `listen` | `selectLens(dictate)` or `toggleBlur()` | `(true, true)` | `dictate` | Activated on active line (or line 0) |
| `echo` | `selectLens(dictate)` or `toggleBlur()` | `(true, true)` | `dictate` | Preserved unchanged |
| `dictate` | `selectLens(echo)` or `toggleEcho()` | `(true, false)` | `echo` | Preserved unchanged |
| `echo` | `selectLens(listen)` or `toggleEcho()` | `(false, false)` | `listen` | Deactivated (`EchoState.inactive`) |
| `dictate` | `selectLens(listen)` or `toggleBlur()` | `(false, false)` | `listen` | Deactivated (`EchoState.inactive`) |

## 2. Transcript Loop & `DictationBand` Contract (`EchoRegionMergedCard`)

When `playerLens == PlayerLens.dictate` and `echo.active == true`:
1. **Context Lines Outside Loop**:
   - Lines above (`< echo.startLineIndex - 1`) and below (`> echo.endLineIndex + 1`) render with `TranscriptBlurText` word-shape bars. Tapping a context line moves the loop to that line (`seekToLine`).
2. **Loop Edge Controls (`EchoLoopEdgeRow`)**:
   - The `+ line` / `−` rows at `echo.startLineIndex - 1` and `echo.endLineIndex + 1` remain active (and `[` `]` `{` `}` shortcuts work), with the edge line's preview text masked via `TranscriptBlurText`.
3. **Inside the Loop (`DictationBand`)**:
   - **Unchecked (`checkResult == null`)**:
     - Renders one rounded block (`height: 12`, `borderRadius: 6`, `width: dictationBlockWidth(word.text)`) per normalized word in the loop.
     - Karaoke colors while original plays:
       - Current word (`isPlaying && pos >= word.startSec && pos < word.endSec`): `tok.original`
       - Heard word (`pos >= word.endSec`): `tok.original.withValues(alpha: 0.35)`
       - Upcoming word: `tok.shape`
     - Secondary translation and IPA overlays are hidden.
   - **Checked (`checkResult != null`)**:
     - Renders inline `Text.rich` diff at loop typography scale:
       - Unchanged words: `tok.originalInk`
       - Missed words (`removed == true`): each word wrapped as `[word]` on `tok.dangerSoft` pill with `tok.danger` semibold text
       - Extra words (`added == true`): struck through (`TextDecoration.lineThrough`) on `tok.youSoft` pill with `tok.youInk` text
     - Renders secondary translation (when enabled) below the diff.
     - Renders 3-item color legend (`Correct`, `Missed`, `Extra`).

## 3. `DictationPanel` & Shared Takes Contract

Mounted below the loop in `EchoRegionMergedCard` when `playerLens == PlayerLens.dictate`:
1. **Input Mode Switcher**:
   - Segmented / pill toggle between **Voice Retelling (录音复述)** and **Text Input (文字输入)** when `checkResult == null`.
2. **Voice Retelling Mode**:
   - Primary action: **Record / Retell** button (pulses `ShadowReadingHotkeyBus`, same as dock Record button and `R` shortcut).
   - While recording: loop header shows pulsing dot + `RECORDING TAKE N` and `_LoopRecordingProgress` countdown bar; dock shows `Cancel (Esc)` + `Stop (R)`.
   - While transcribing (`isTranscribing == true`): shows spinner + localized `Transcribing...` status.
   - On ASR failure (`failure != null`): shows error message + **Retry transcription** button (re-runs ASR on `lastRecordedTake.localPath` without re-recording) and **Record again** button.
3. **Text Input Mode**:
   - Multi-line `TextField` with placeholder (`Type what you hear...`), live word count (`{{typed}} of about {{total}} words · Enter to check`), and **Check Dictation** button.
   - `Enter` (without `Shift` and outside active IME composition) submits; `Shift+Enter` inserts a newline.
4. **Checked Score Card (`checkResult != null`)**:
   - Displays **Accuracy** (`0..100`), **Correct**, **Missed**, and **Extra** word counts, plus the learner's recognized/typed input text.
   - Actions:
     - **Try again**: clears `checkResult` (resets band to hidden blocks) to start a fresh attempt on the same loop.
     - **Next line**: moves the loop to `echo.endLineIndex + 1`, seeks to its start, and clears `checkResult` (disabled when `echo.endLineIndex + 1 >= lines.length`).
5. **Shared Shadow-Reading Takes Row (`ShadowReadingPanel`)**:
   - Remains mounted below the loop so any recording captured in Dictate mode (or earlier in Echo mode) is shown in `ShadowTakeSummaryRow` (`Play` take `G`, `Score` / `Assessment` `V`, `N takes ›` opening `ShadowTakesListPanel` with per-take replay, assessment, and delete).
6. **Previous Dictations (`DictationList`)**:
   - Streams `DictationRow`s overlapping the current loop region via `DictationDao.watchByEchoRegion` (newest first).
   - Displays attempt selector (when multiple exist), accuracy badge (`>=80%` good, `>=60%` fair, `<60%` poor), word breakdown, and `userInput`.
