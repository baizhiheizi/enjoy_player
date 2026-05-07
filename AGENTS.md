# AGENTS.md — Enjoy Player (Flutter)

Guidance for humans and AI coding agents working in this repository.

## Read first

1. [README.md](README.md) — setup & commands  
2. [docs/architecture.md](docs/architecture.md) — modules & data flow  
3. [docs/conventions.md](docs/conventions.md) — Dart / Flutter rules  
4. [docs/decisions/README.md](docs/decisions/README.md) — ADR index  

## Hard rules

- **Single playback engine**: Only [`PlayerController`](lib/features/player/application/player_controller.dart) may own a `media_kit` `Player`. Never instantiate `Player()` elsewhere (ADR-0003).
- **No `print()`**: Use [`Log.named`](lib/core/logging/log.dart) or `package:logging`.
- **Persistence**: All SQLite access goes through Drift [`AppDatabase`](lib/data/db/app_database.dart) DAOs — no raw SQL in UI/feature widgets (ADR-0002).
- **Documentation hygiene**: Architectural decisions → new ADR in [`docs/decisions/`](docs/decisions/). Feature behavior changes → update [`docs/features/<feature>.md`](docs/features/). Tasks → [`brainfile.md`](brainfile.md).

## MVP scope

Local audio/video files only, transcripts via `.srt`/`.vtt`, echo (shadow-reading) mode. YouTube / URL streaming / cloud sync are **out of scope** until ADR supersession (see ADR-0005).

## Codegen

After schema or `@riverpod` changes:

```bash
dart run build_runner build
```

## Verification

```bash
flutter analyze
flutter test
```
