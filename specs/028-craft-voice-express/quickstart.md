# Quickstart Validation: Craft Voice-Express Redesign

**Date**: 2026-07-23 | **Feature**: 028-craft-voice-express

---

## Prerequisites

- Flutter SDK (version per `.github/flutter-version`)
- A signed-in Enjoy AI account OR a BYOK configuration for ASR + LLM + TTS
- Microphone permission granted (already required for shadow reading)
- Run on a device or emulator with microphone access

## Setup

```bash
# Install dependencies (record package already in pubspec)
flutter pub get

# Regenerate codegen if any Riverpod annotations changed
dart run build_runner build

# Run the app
flutter run
```

## Validation Scenarios

### Scenario 1: Express Voice Capture → Rewrite → Audio (P1)

**Goal**: Verify the full Express flow end-to-end.

1. Open the app → navigate to Import → "Craft from text" → `/craft`
2. Confirm: screen opens in **Express** mode (segmented control shows Express selected)
3. Confirm: large mic button centered, language pair shown above (native → learning)
4. Tap the mic button → speak a sentence in native language (~5-10 seconds)
5. Tap the stop button
6. **Verify**: raw transcript appears (muted/italic), flow advances to rewrite stage
7. **Verify**: editable target-language text appears below, style chip shows "Auto"
8. Tap "Generate audio"
9. **Verify**: preview player appears with play/pause and progress bar
10. Tap "Say something else"
11. **Verify**: toast "已保存到资料库" appears, screen resets to capture stage
12. Navigate to Library → **verify** the saved Craft item appears with the Craft badge

### Scenario 2: Express Text Fallback (P1)

**Goal**: Verify text input path skips ASR.

1. Open `/craft` in Express mode
2. Tap "type instead" (或输入文字)
3. **Verify**: text input replaces mic area
4. Type a native-language thought (≥10 characters)
5. **Verify**: flow advances to rewrite stage with the typed text as raw transcript
6. Complete the flow through to audio generation

### Scenario 3: Auto Style vs Other Styles (P1)

**Goal**: Verify "Auto" style produces idiomatic output and style switching works.

1. Complete a capture (voice or text)
2. In rewrite stage, confirm default style chip shows "Auto"
3. Read the target-language result — it should be conversational, not literal
4. Expand the style chip → select "literal"
5. Tap "Regenerate"
6. **Verify**: the result changes to a more literal translation
7. Switch back to "Auto" → tap "Regenerate"
8. **Verify**: the result returns to the idiomatic version

### Scenario 4: Advanced Mode (P2)

**Goal**: Verify the redesigned two-tool layout works.

1. Open `/craft` → switch to **Advanced** mode via segmented control
2. **Verify**: Translate + Synthesize panels appear (side-by-side on desktop, stacked on phone)
3. In Translate panel: select languages, type source text, tap Translate
4. **Verify**: editable result appears
5. Tap "Send to synthesis"
6. **Verify**: text appears in the Synthesize panel
7. Select a voice → tap Synthesize
8. **Verify**: preview player appears
9. Tap "Save to library"
10. **Verify**: item saved and player opens

### Scenario 5: Mode Switching Preserves Work (P2)

**Goal**: Verify switching between Express and Advanced mid-session preserves state.

1. In Express mode: capture voice → reach rewrite stage
2. Switch to Advanced mode
3. **Verify**: the captured transcript and rewrite appear in the Translate panel
4. Switch back to Express mode
5. **Verify**: the rewrite stage is still showing with previous results

### Scenario 6: Responsive Layout (P2)

**Goal**: Verify layouts adapt at phone, tablet, desktop breakpoints.

1. On desktop (≥900px width): open `/craft` in both modes
   - **Express**: single centered column (max-width ~480px)
   - **Advanced**: side-by-side panels
2. Resize to tablet (600-899px):
   - **Express**: centered column (max-width ~420px)
   - **Advanced**: side-by-side panels
3. Resize to phone (<600px):
   - **Express**: full-width column (14px gutters)
   - **Advanced**: stacked vertically

### Scenario 7: Calm Failure Recovery (P2)

**Goal**: Verify failure states surface actionable messages.

1. Turn off network → open `/craft` in Express mode
2. Record audio → tap stop
3. **Verify**: calm ASR failure message with Retry action
4. Restore network → tap Retry → flow proceeds

### Scenario 8: Run Automated Tests

```bash
# Unit + widget tests
flutter test test/features/craft/

# Full CI gates
bash .github/scripts/validate_ci_gates.sh
```

**Expected**: All tests pass with zero errors. New tests cover:
- Express capture → transcribe → rewrite flow
- Express generate audio → save → reset loop
- Mode switching state preservation
- "Auto" style prompt construction
- Empty transcript failure
- sourceFlag = 'craft-express' on Express saves
