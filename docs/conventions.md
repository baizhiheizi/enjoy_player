# Conventions

## Layout

- `lib/features/<feature>/{application,data,domain,presentation}/`
- Shared code: `lib/core`, `lib/data`
- Generated files: `*.g.dart` (never hand-edit)

## Naming

- Files: `snake_case.dart`
- Widgets / classes: `UpperCamelCase`
- Providers: generated `*Provider` from `@Riverpod` names

## Imports

Prefer `package:enjoy_player/...` for cross-layer imports in presentation code to avoid fragile relative paths.

## Code quality

- Keep production code in `lib/features/<feature>/{application,data,domain,presentation}/`, `lib/core`, or `lib/data`.
- Domain models stay UI-free. Presentation widgets delegate state orchestration to Riverpod providers/notifiers.
- SQLite access goes through Drift DAOs backed by `AppDatabase`; do not add raw SQL in UI or feature widgets.
- Use `package:logging` through project logging helpers; do not call `print()`.
- Do not construct `media_kit` `Player()` outside `MediaKitPlayerEngine` / `PlayerController`.

## UI interaction

- Prefer **`EnjoyTappableSurface` / `EnjoyTappableIcon`** (or **`EnjoyButton`**) for new tappable UI instead of ad-hoc `InkWell` + `GestureDetector` combinations — see [ADR-0018](decisions/0018-shared-interactive-primitives.md).
- Route light user feedback through **`Haptics`** (`selection`, `impactMedium`, `success`, `warning`) rather than calling `HapticFeedback` directly; it honors reduced motion / platform.
- Icon-only controls should still expose **`Tooltip`** (and keyboard hints via `kbd_chip` / hotkey helpers where applicable).
- User-visible strings live in ARB localization files under `lib/l10n/`.

## Logging

```dart
import 'package:enjoy_player/core/logging/log.dart';

final log = logNamed('MyFeature');
log.info('hello');
```

## Riverpod

- Long-lived globals: `@Riverpod(keepAlive: true)`
- Prefer `Notifier` / generated providers over mutable singletons.
- Avoid circular dependencies: UI sync widgets listen to `Player` streams instead of `PlayerController` calling `PlayerUi` directly.
- **No build-time side effects**: don't read a provider's value and assign it to a `State` field directly inside `build()` — that mutates state as a side effect of building, which Flutter disallows triggering a rebuild from. Instead use `ref.listen` at the top of `build()` and call `setState` from the listener callback. Example (`_EnjoyAppState.build` in [`app.dart`](../lib/app.dart) mirrors `appPreferencesCtrlProvider` into `_lastResolvedPrefs` so the last-known preferences stay visible during an auth-scoped DB switch reload):

```dart
@override
Widget build(BuildContext context) {
  ref.listen<AsyncValue<AppPreferencesState>>(appPreferencesCtrlProvider, (
    prev,
    next,
  ) {
    final nextPrefs = next.valueOrNull;
    if (nextPrefs == null) return;
    if (identical(nextPrefs, _lastResolvedPrefs)) return;
    setState(() => _lastResolvedPrefs = nextPrefs);
  });
  // ...
}
```

## Database

- No SQL strings outside Drift-generated / DAO code.
- Use `NativeDatabase.memory()` in tests (see `test/data/db/app_database_test.dart`).

## REST services

Every `*Api` class under `lib/data/api/services/` follows the same shape — see [api/rest-services.md](api/rest-services.md) for the full reference. Short version:

- Extend [`RestApi`](../lib/data/api/rest_api.dart); forward the client with `super(client)`.
- Do **not** declare your own `typedef JsonMap` — import it from [`api_client.dart`](../lib/data/api/api_client.dart) and use it for both request bodies and response shapes.
- Pick the right `*ApiClient` provider (`authApiClient` / `apiClient` / `aiApiClient`) for the endpoint's base URL and auth posture; do not instantiate `ApiClient` directly.
- Expose services through a `keepAlive` Riverpod provider in `services/<area>/`, never construct them in widgets.

## Testing

- Unit tests for pure logic (`echo_window`, subtitle parsers, repositories), DAOs, and Riverpod notifiers.
- Widget or integration tests for changed navigation, input, localization, platform chrome, and shared UI behavior.
- Every behavior change needs automated coverage or a documented manual verification reason (see [testing.md](testing.md)).

## Performance

- Keep expensive file, image, transcript, database, and audio work out of `build` methods and list/grid item builders.
- Cache, stream, page, debounce, or move heavy work off the main isolate when it can block frames.
- Include a performance goal or verification note for playback, startup, scrolling, transcript rendering, sync, and media import changes.

## Sliver performance (long live lists)

Grids/lists backed by a Drift stream or an RSS refresh re-emit their full item list on every change, even when only one row changed. Without a stable key + lookup, `SliverChildBuilderDelegate` falls back to rebuilding **every visible child** on each emission.

Use a stable `ValueKey<String>` per row plus `findChildIndexCallback` so Flutter can re-use existing `Element`s instead of tearing them down:

```dart
SliverChildBuilderDelegate(
  (context, index) => Tile(key: ValueKey<String>('$kPrefix${items[index].id}'), ...),
  childCount: items.length,
  findChildIndexCallback: (key) => findSliverIndexByPrefixedId(
    items: items,
    key: key,
    prefix: kPrefix,
    idOf: (item) => item.id,
  ),
)
```

[`findSliverIndexByPrefixedId<T>`](../lib/core/utils/sliver_key_index.dart) centralizes the key-shape lookup so the prefix used when constructing the `ValueKey` cannot drift from the prefix used in `findChildIndexCallback`. It returns `null` for any key that doesn't match (wrong type, wrong prefix, or no matching id), which tells the sliver framework to fall back to its default scan for that child.

Applied to the home recents grid (`home-media-` prefix), the discover merged feed grid (`discover-feed-` prefix), and the channel feed grid (`channel-feed-` prefix) — see [features/library.md](features/library.md) and [features/discover.md](features/discover.md). Covered by 10 unit tests in `test/core/utils/sliver_key_index_test.dart`.
