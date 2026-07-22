# Contract: App Orientation Policy by Form Factor

**Feature**: 026-orientation-layout-polish  
**Consumers**: `lib/main.dart` bootstrap; unit tests  
**Pure API** (names indicative): `resolveDeviceFormFactor`, `preferredOrientationsFor`

## Classification

```text
resolveDeviceFormFactor(platform, shortestSideLogical) → DeviceFormFactor?
```

| platform | shortestSideLogical | result |
|----------|---------------------|--------|
| windows / macOS / linux | (ignored) | `desktop` |
| iOS / android | ≥ 600 | `tablet` |
| iOS / android | &gt; 0 and &lt; 600 | `phone` |
| iOS / android | ≤ 0 or non-finite | `null` (defer — do **not** guess phone) |

Constant: tablet threshold = **600** logical pixels (shortest side).

## Preferred orientations

```text
preferredOrientationsFor(formFactor) → List<DeviceOrientation>?
```

| formFactor | return |
|------------|--------|
| `phone` | `[portraitUp, portraitDown]` |
| `tablet` | `[portraitUp, portraitDown, landscapeLeft, landscapeRight]` |
| `desktop` | `null` (caller MUST NOT invoke `SystemChrome.setPreferredOrientations`) |

## Bootstrap application

1. After `WidgetsFlutterBinding.ensureInitialized()`.
2. Read primary view **display** logical shortest side (`view.display.size / dpr`), not window `physicalSize` (can be `Size.zero` at startup and letterboxed after a wrong lock).
3. Resolve form factor with `defaultTargetPlatform`.
4. If result is `null`, defer via `onMetricsChanged` and do **not** call `setPreferredOrientations` (never default mobile to phone).
5. If preferred list is non-null, `await SystemChrome.setPreferredOrientations(list)`.
6. Failures MUST be logged via project logging helpers and MUST NOT prevent `runApp`.

## Out of scope

- Per-route orientation overrides (e.g. force landscape in player on phones).
- User-facing Settings toggle.
- Changing desktop window min size / resize behavior.
