# Quickstart: Craft Studio (Redesigned)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

## Scenario 1 — Open Craft screen from import chooser

Tap Import → Craft from text. Confirm a **full screen** opens (not a bottom sheet). Back button returns to Home/Library.

## Scenario 2 — Translate with style preset + edit + "Use translated text"

1. In the Translate tool, paste ~200 chars of native-language text.
2. Confirm source language = native language; target = learning language.
3. Select style "Natural". Tap Translate.
4. Result appears in < 15 s in an **editable** field.
5. Edit a word in the result.
6. Tap **Use translated text**. Synthesize tool's text input is pre-filled; focus shifts.

## Scenario 3 — Synthesize with voice selection + preview

1. In the Synthesize tool, confirm text is pre-filled (from translate).
2. Open voice picker → see Azure voices filtered by language (e.g., Jenny, Guy for en).
3. Select a voice. Tap Synthesize.
4. Preview player appears in < 20 s. Tap play → audio plays.
5. Change voice → re-synthesize → new preview replaces old.

## Scenario 4 — Save with timestamped transcript

1. After previewing, tap **Save to library**.
2. Player opens with the new audio item.
3. Transcript shows **multiple sentence lines with timestamps** (not a single block).
4. Start echo mode → it works against the timestamped transcript.

## Scenario 5 — Direct synthesis (no translation)

1. Skip the Translate tool. Paste text directly in the Synthesize tool.
2. Synthesize → preview → save.
3. Player opens with learning-language transcript only (no secondary).

## Scenario 6 — Dedupe

1. Save the same text + voice + language twice.
2. Second save shows "Already in your library" with Open action.

## Scenario 7 — Failure recovery

Force translation failure, TTS failure, save failure. Confirm each surfaces a calm message with Retry / Open AI settings. No orphan rows.

## Scenario 8 — Static checks

```bash
dart format lib test
flutter analyze
flutter test
```

All pass with zero new errors.
