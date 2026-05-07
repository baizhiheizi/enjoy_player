# Tech stack

| Concern | Choice | Notes |
|---------|--------|-------|
| Language | Dart ^3.7 | Strict analysis |
| UI | Flutter 3.x / Material 3 | `buildAppTheme` in `lib/core/theme/` |
| State | `flutter_riverpod` + `riverpod_annotation` | `@Riverpod` notifiers, `build_runner` |
| Navigation | `go_router` | Shell route for persistent mini player |
| Playback | `media_kit` + `media_kit_video` + `media_kit_libs_video` | Single `Player` instance |
| Persistence | `drift` + `drift_flutter` + `sqlite3_flutter_libs` | Native SQLite |
| Files | `file_picker` + `path_provider` + `cross_file` | Import copies into app documents |
| IDs | `uuid` | v5 namespaced IDs for media from file hash |
| Logging | `logging` | Wrapper `logNamed` |
| i18n | `flutter_localizations` + ARB | MVP English only (`lib/l10n/app_en.arb`) |
| Codegen | `build_runner`, `drift_dev`, `riverpod_generator` | Run after schema/provider edits |
| Lint | `flutter_lints`, `custom_lint`, `riverpod_lint` | See `analysis_options.yaml` |

Deferred (ADR-0005): `flutter_inappwebview`, cloud sync, URL streaming UX polish.
