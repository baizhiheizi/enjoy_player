# Quickstart & Verification Guide: Dictation Practice

**Feature**: [spec.md](spec.md) | **Contract**: [dictation-ui-and-data-contract.md](contracts/dictation-ui-and-data-contract.md) | **Data Model**: [data-model.md](data-model.md)

## Prerequisites

- Flutter SDK (matches `.fvmrc` / CI runtime)
- Working checkout of `enjoy_player`

## Automated Verification Commands

1. **Codegen & Format Gate**:
   ```bash
   bash .github/scripts/check_codegen_drift.sh --fix
   bash .github/scripts/check_dart_format.sh --fix
   ```
2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
3. **Targeted Unit & Widget Tests**:
   ```bash
   # Word diff, normalization, accuracy, and band word windows:
   flutter test test/features/dictation/
   # Lens transitions (Listen <-> Echo <-> Dictate) and loop preservation:
   flutter test test/features/player/domain/player_lens_test.dart
   flutter test test/features/player/player_interactions_class_test.dart
   # Transcript loop card, edge rows, and practiced line indicators:
   flutter test test/features/transcript/
   ```
4. **Full CI Gate**:
   ```bash
   bash .github/scripts/validate_ci_gates.sh --test --changed-only
   ```

## End-to-End Scenarios to Verify

1. **Loop-Bound Dictate Lens & Multi-Line Controls**:
   - Open an audio or video item with a transcript and switch to **Dictate** (`H` or top-bar mode switch).
   - Verify the active line enters a practice loop with its words masked as proportional blocks (`DictationBand`), while context lines and `+ line` edge rows mask their text.
   - Expand/shrink the loop using `+ line` / `−` (or `[` `]` `{` `}`) and verify the masked word blocks and loop duration update to span the multi-line segment.
2. **Voice Retelling (Recording + ASR + Shared Shadow-Reading Takes)**:
   - In **Voice Retelling** mode, press Record (`R`, dock button, or panel button), speak the sentence, and stop recording.
   - Verify the recording is saved as a take in the segment's takes row (`ShadowTakeSummaryRow`), can be replayed (`G`) and assessed for pronunciation (`Score` / `V`), and is transcribed via `AsrService` into a word-level diff (`DictationBand`) and score card (`Accuracy`, `Correct`, `Missed`, `Extra`).
   - Switch to **Echo** mode and confirm the loop stays on the same line(s) and the recording captured in Dictate mode is present and playable.
3. **Text Input Mode & History**:
   - Switch the dictation input toggle to **Text Input**, type a response, and press `Enter` (or tap **Check Dictation**).
   - Verify the inline diff and score breakdown appear, **Previous Dictations** lists the saved attempts for the segment, **Try again** resets the check, and **Next line** moves the loop to the following line.
