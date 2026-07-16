# Contract: Media open trust + relocate

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

---

## C1. Cheap trust check

**Module**: `lib/data/db/media_target_resolver.dart` (or small helper in `lib/data/files/`)

```dart
/// Returns true when [localUri] exists and matches stored trust metadata.
Future<bool> localUriTrusted({
  required String? localUri,
  required int? storedSize,
  required int? storedMtimeMs,
});
```

**Invariants**:

- Missing / unreadable URI → false.
- If `storedSize != null` and live length ≠ `storedSize` → false.
- If `storedMtimeMs != null` and live modified ms ≠ `storedMtimeMs` → false.
- If both stored trust fields are null → existence-only (legacy).
- MUST NOT compute full content hash.

---

## C2. `resolvePlayableSource` / `resolvePlaybackOpen`

**Invariants**:

- YouTube / remote URL resolution unchanged and takes precedence where applicable.
- Local branch: only return `LocalFilePlayableSource` when `localUriTrusted(...)` is true.
- When local trust fails / missing and `md5` present → `resolvePlaybackOpen` throws `MediaNeedsRelocateException` (existing type).
- When local trust fails and no `md5` → null / non-relocate failure path as today.

---

## C3. Locate UI (unchanged product surface)

**Module**: `lib/features/player/presentation/locate_media_screen.dart` + `PlayerController.relocateAndOpen`

**Invariants**:

- User picks file → `relocateLocalFile` → hash must match → open.
- Hash mismatch → error notice; previous `localUri` unchanged.
- Success → playback without requiring a second full copy when link is possible.
