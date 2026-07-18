<!-- hash: log-2026-07-18 -->

# lib/core/logging/log.dart

One-line wrapper around `package:logging`'s `Logger`:

```dart
Logger logNamed(String name) => Logger(name);
```

Used project-wide as `final log = logNamed('MyFeature');`. Enforces the no-`print()` policy (AGENTS.md, conventions.md).