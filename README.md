# Enjoy Player

Cross-platform **language-learning player** (Android, iOS, Windows, macOS) built with Flutter. MVP focuses on **local** audio/video, **transcripts** (SRT/VTT), and **echo mode** (line-bounded shadow reading), aligned with the Enjoy web app player concepts.

## Prerequisites

- Flutter SDK (stable, 3.x)
- Dart SDK ^3.7

## Setup

```bash
flutter pub get
dart run build_runner build   # after changing Drift / Riverpod annotations
```

## Run

```bash
flutter run
```

## Test / analyze

```bash
flutter analyze
flutter test
```

## Docs

| Doc | Purpose |
|-----|---------|
| [AGENTS.md](AGENTS.md) | Rules for contributors & AI agents |
| [docs/architecture.md](docs/architecture.md) | Structure & flows |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records |
| [docs/features/](docs/features/) | Feature specs |
| [brainfile.md](brainfile.md) | Kanban task board |

## Tech highlights

- **Player**: [media_kit](https://pub.dev/packages/media_kit) (+ `media_kit_video`, `media_kit_libs_video`)
- **State**: [Riverpod 3](https://pub.dev/packages/flutter_riverpod) + `riverpod_annotation`
- **DB**: [Drift](https://pub.dev/packages/drift) + `drift_flutter`

## License

Private / unpublished (`publish_to: 'none'`).
