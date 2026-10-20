# Craft from Text

AI-generated audio materials for shadow reading. Ported from the Enjoy web app's
smart-translation and voice-synthesis features, redesigned as a single import
entry with two modes:

- **Translate then speak** — translate text in any language into the learner's
  profile learning language, then synthesize audio.
- **Speak directly** — synthesize audio directly from learning-language text.

See [spec.md](../../../specs/010-craft-from-text/spec.md) and
[plan.md](../../../specs/010-craft-from-text/plan.md) for the full design.

## Key files

| Layer | File |
|-------|------|
| Domain | `domain/craft_mode.dart`, `domain/craft_failure.dart`, `domain/craft_request.dart` |
| Application | `application/craft_controller.dart` (+ `craft_controller_core.dart`, `craft_translate_stage.dart`, `craft_synthesize_stage.dart`, `craft_capture_stage.dart`, `craft_library_stage.dart`) |
| Presentation | `presentation/craft_sheet.dart` |
| Integration | `lib/features/craft/data/craft_library_repository.dart` (`importCraftedFromText`) |
| AI wiring | `lib/features/ai/data/enjoy/enjoy_tts_capability.dart` |

## ADR

See [docs/decisions/0043-craft-from-text-import.md](../../../docs/decisions/0043-craft-from-text-import.md).
