# AGENTS.md — Enjoy Player (Flutter)

Guidance for humans and AI coding agents working in this repository.

## Read first

1. [README.md](README.md) — setup & commands
2. [.specify/memory/constitution.md](.specify/memory/constitution.md) — quality, testing, UX, performance, and governance gates
3. [docs/architecture.md](docs/architecture.md) — modules & data flow
4. [docs/conventions.md](docs/conventions.md) — Dart / Flutter rules
5. [docs/decisions/README.md](docs/decisions/README.md) — ADR index

## Hard rules

- **Supported platforms**: Android, iOS, macOS, Windows (Linux may follow). **Do not add Flutter web** targets, `web/` scaffolding, or `kIsWeb` branches — native desktop/mobile only.
- **Single `media_kit` player**: Only [`MediaKitPlayerEngine`](lib/features/player/application/player_engine.dart) / [`PlayerController`](lib/features/player/application/player_controller.dart) may own a `media_kit` `Player`. Never instantiate `Player()` elsewhere (ADR-0003, ADR-0015). YouTube uses `flutter_inappwebview`, not `media_kit`.
- **No `print()`**: Use [`logNamed`](lib/core/logging/log.dart) (a one-line wrapper around `package:logging`'s `Logger`) — never `print()`. See [conventions.md § Logging](docs/conventions.md#logging) for the canonical pattern.
- **Persistence**: All SQLite access goes through Drift [`AppDatabase`](lib/data/db/app_database.dart) DAOs — no raw SQL in UI/feature widgets (ADR-0002).
- **Quality gates**: Behavior changes need automated tests or documented manual verification, shared UI patterns, performance evidence for user-visible hot paths, and matching docs updates.
- **Documentation hygiene**: Architectural decisions → new ADR in [`docs/decisions/`](docs/decisions/). Feature behavior changes → update [`docs/features/<feature>.md`](docs/features/). Shared UI interaction patterns → [ADR-0018](docs/decisions/0018-shared-interactive-primitives.md).

## MVP scope

Local audio/video files, **YouTube imports** (watch page WebView; transcripts via Enjoy API after sync), transcripts via `.srt`/`.vtt` for local files, echo (shadow-reading) mode. **Metadata sync** (local-first queue + optional Cloud index + per-target recording pulls) when signed in ([ADR-0010](docs/decisions/0010-cloud-sync-mvp.md), [ADR-0013](docs/decisions/0013-local-first-sync.md)). Arbitrary URL streaming beyond `mediaUrl` / YouTube and **media file uploads** remain out of scope unless superseded ([ADR-0005](docs/decisions/0005-mvp-scope-local-only.md), [ADR-0015](docs/decisions/0015-youtube-playback.md)).

## Lookup language catalog

The transcript lookup sheet (`lib/features/lookup/`) uses a **separate** `kSupportedLookupLanguageTags` catalog in [`lib/core/application/app_language_catalog.dart`](lib/core/application/app_language_catalog.dart) for source / target options (first wave: en-US / en-GB / zh-CN / ja-JP / ko-KR / es-ES / es-MX / fr-FR / fr-CA / de-DE / it-IT / pt-BR / pt-PT / ru-RU). It is decoupled from `kSupportedNativeLanguageTags` (profile "native", 2 tags) and `kSupportedFocusLanguageTags` (profile "learning", 8 tags); widening the lookup picker must not regress profile / settings UI. See [ADR-0021](docs/decisions/0021-multi-language-lookup-catalog.md) and [docs/features/dictionary-lookup.md § Languages](docs/features/dictionary-lookup.md#languages).

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

Release packaging (Android signing, AAB/APK, Windows installer, FFmpeg, **iOS TestFlight**, **macOS notarization**): [docs/packaging.md](docs/packaging.md) and [ADR-0020](docs/decisions/0020-android-windows-release-identity.md).
