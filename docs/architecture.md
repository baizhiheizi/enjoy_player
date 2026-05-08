# Architecture

## Goals

- **Feature-first** folders under `lib/features/*` with shared `lib/core` and `lib/data`.
- **One `media_kit` `Player`** owned by [`PlayerController`](../lib/features/player/application/player_controller.dart) (ADR-0003).
- **Drift** as single local SQLite source of truth (ADR-0002).
- **Riverpod 3** for app state; codegen via `riverpod_annotation` where practical (ADR-0001).

## Layer map

```mermaid
flowchart TB
  UI[presentation widgets]
  APP[application Riverpod notifiers]
  DOM[domain models]
  DATA[data db files subtitle]
  UI --> APP
  APP --> DOM
  APP --> DATA
```

## Runtime flow (MVP)

```mermaid
sequenceDiagram
  participant Lib as LibraryScreen / HomeScreen
  participant Repo as MediaLibraryRepository
  participant DB as AppDatabase
  participant PC as PlayerController
  participant MK as media_kit Player

  Lib->>Repo: importMedia XFile
  Repo->>DB: insert VideoRow / AudioRow
  Lib->>PC: openMedia id
  PC->>MK: open Media uri
  MK-->>PC: position stream
  PC->>DB: upsert EchoSessionRow debounced
```

## Drift tables (summary)

| Table | Purpose |
|-------|---------|
| `videos` | Local video URI, `vid` hash, duration (seconds), sync metadata |
| `audios` | Local audio URI, `aid` hash, duration, optional TTS fields, sync metadata |
| `transcripts` | `targetType` + `targetId` (weapp-style), JSON `timeline`, sync metadata |
| `echo_sessions` | Playback + echo window + primary/secondary transcript ids per target |
| `recordings` | Pronunciation recordings (sync-ready) |
| `dictations` | Dictation attempts (sync-ready) |
| `sync_queue` | Offline sync queue (reserved for post-login sync) |
| `settings` | Key/value JSON blobs (player prefs, hotkeys, **API base URL**, **auth profile cache**, app locale prefs) |

## Optional Enjoy account (auth)

- **HTTP:** `package:http` + small `ApiClient` under `lib/data/api/` (camelCase ↔ snake_case like `@enjoy/api`).
- **Tokens:** `flutter_secure_storage` (access token only).
- **Browser sign-in:** `url_launcher` for `start_auth` / `poll` flow ([ADR-0006](decisions/0006-auth-and-profile-sync.md), [features/auth.md](features/auth.md)).

## Routing

[`GoRouter`](../lib/core/routing/app_router.dart) + [`ShellRoute`](../lib/features/player/presentation/root_shell.dart): routes render beside an extended sidebar at wide breakpoints; [`GlobalTransportBar`](../lib/features/player/presentation/widgets/global_transport_bar.dart) spans the bottom when a playback session exists.

## Manual providers

[`libraryMediaProvider`](../lib/features/library/application/library_media_provider.dart) is a hand-written `StreamProvider` because `riverpod_generator` + Drift row types hit an `InvalidTypeException` in codegen — keep this pattern documented if more stream providers need the same workaround.
