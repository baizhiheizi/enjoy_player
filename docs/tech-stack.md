# Tech stack

| Concern | Choice | Notes |
|---------|--------|-------|
| Language | Dart ^3.7 | Strict analysis |
| UI | Flutter 3.x / Material 3 + `google_fonts` | `buildAppTheme` + `EnjoyThemeTokens` in `lib/core/theme/` |
| State | `flutter_riverpod` + `riverpod_annotation` | `@Riverpod` notifiers, `build_runner` |
| Navigation | `go_router` | Shell route for persistent mini player |
| Playback | `media_kit` + `media_kit_video` + `media_kit_libs_video` | Single `Player` instance |
| Persistence | `drift` + `drift_flutter` + `sqlite3_flutter_libs` | Native SQLite |
| Files | `file_picker` + `path_provider` + `cross_file` | Import copies into app documents |
| IDs | `uuid` | v5 namespaced IDs for media from file hash |
| Logging | `logging` | Wrapper `logNamed` |
| Networking | `http` | Enjoy API client under `lib/data/api/` |
| Secure storage | `flutter_secure_storage` | Access token only |
| Browser / deep links | `url_launcher` | OAuth `start_auth` browser step |
| i18n | `flutter_localizations` + ARB | MVP English only (`lib/l10n/app_en.arb`) |
| Codegen | `build_runner`, `drift_dev`, `riverpod_generator` | Run after schema/provider edits |
| Lint | `flutter_lints`, `custom_lint`, `riverpod_lint` | See `analysis_options.yaml` |

Deferred (ADR-0005): `flutter_inappwebview`, URL streaming UX polish. Library/recording **cloud sync** remains deferred; see [ADR-0006](decisions/0006-auth-and-profile-sync.md) for optional auth + profile scope.
