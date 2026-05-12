# AGENTS.md — Enjoy Player (Flutter)

Guidance for humans and AI coding agents working in this repository.

## Read first

1. [README.md](README.md) — setup & commands
2. [docs/architecture.md](docs/architecture.md) — modules & data flow
3. [docs/conventions.md](docs/conventions.md) — Dart / Flutter rules
4. [docs/decisions/README.md](docs/decisions/README.md) — ADR index

## Hard rules

- **Single `media_kit` player**: Only [`MediaKitPlayerEngine`](lib/features/player/application/player_engine.dart) / [`PlayerController`](lib/features/player/application/player_controller.dart) may own a `media_kit` `Player`. Never instantiate `Player()` elsewhere (ADR-0003, ADR-0015). YouTube uses `flutter_inappwebview`, not `media_kit`.
- **No `print()`**: Use [`Log.named`](lib/core/logging/log.dart) or `package:logging`.
- **Persistence**: All SQLite access goes through Drift [`AppDatabase`](lib/data/db/app_database.dart) DAOs — no raw SQL in UI/feature widgets (ADR-0002).
- **Documentation hygiene**: Architectural decisions → new ADR in [`docs/decisions/`](docs/decisions/). Feature behavior changes → update [`docs/features/<feature>.md`](docs/features/). Shared UI interaction patterns → [ADR-0018](docs/decisions/0018-shared-interactive-primitives.md).

## MVP scope

Local audio/video files, **YouTube imports** (watch page WebView; transcripts via Enjoy API after sync), transcripts via `.srt`/`.vtt` for local files, echo (shadow-reading) mode. **Metadata sync** (local-first queue + optional Cloud index + per-target recording pulls) when signed in ([ADR-0010](docs/decisions/0010-cloud-sync-mvp.md), [ADR-0013](docs/decisions/0013-local-first-sync.md)). Arbitrary URL streaming beyond `mediaUrl` / YouTube and **media file uploads** remain out of scope unless superseded ([ADR-0005](docs/decisions/0005-mvp-scope-local-only.md), [ADR-0015](docs/decisions/0015-youtube-playback.md)).

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
