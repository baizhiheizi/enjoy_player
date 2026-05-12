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

## UI interaction

- Prefer **`EnjoyTappableSurface` / `EnjoyTappableIcon`** (or **`EnjoyButton`**) for new tappable UI instead of ad-hoc `InkWell` + `GestureDetector` combinations — see [ADR-0018](decisions/0018-shared-interactive-primitives.md).
- Route light user feedback through **`Haptics`** (`selection`, `impactMedium`, `success`, `warning`) rather than calling `HapticFeedback` directly; it honors reduced motion / platform.
- Icon-only controls should still expose **`Tooltip`** (and keyboard hints via `kbd_chip` / hotkey helpers where applicable).

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

## Database

- No SQL strings outside Drift-generated / DAO code.
- Use `NativeDatabase.memory()` in tests (see `test/data/db/app_database_test.dart`).

## Testing

- Unit tests for pure logic (`echo_window`, subtitle parsers, repositories).
- Widget / golden tests: future work (see [testing.md](testing.md)).
