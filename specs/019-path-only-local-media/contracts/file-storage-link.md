# Contract: File storage link-or-copy

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Internal Dart contracts for `FileStorage` / lasting-access helpers. No new HTTP APIs.

---

## C1. `canLinkExternally` / `isAppManagedMediaPath`

**Module**: `lib/data/files/lasting_local_access.dart` (new)

```dart
/// True when [absolutePath] is a durable filesystem path suitable for
/// storing as localUri without copying into app media/.
Future<bool> canLinkExternally(String absolutePath);

/// True when [absolutePath] or file URI resolves under {documents}/media/.
Future<bool> isAppManagedMediaPath(String pathOrFileUri);
```

**Invariants**:

- `canLinkExternally` MUST be false for empty paths, non-existent files, and paths under temp/cache (see research D2).
- `isAppManagedMediaPath` MUST be true only for files under the app documents `media/` directory used by `FileStorage`.

---

## C2. `FileStorage.importOrLinkPickedFile`

**Module**: `lib/data/files/file_storage.dart`

```dart
/// Prefer lasting external link; otherwise copy into app media/.
/// When [expectedHashHex] is set, fail with FileFailure if chunked hash mismatches
/// (before or without committing a new durable copy unnecessarily).
Future<FileImportResult> importOrLinkPickedFile(
  XFile file, {
  String? expectedHashHex,
});
```

**Invariants**:

- MUST compute chunked content hash from the source (isolate) before committing storage.
- If `expectedHashHex` is non-null and mismatches → throw `FileFailure`; MUST NOT leave a new orphan temp file.
- If `canLinkExternally(sourcePath)` → `localPath` = source absolute path; MUST NOT write a full duplicate under `media/`.
- Else → copy/rename into `media/{hash}{ext}` (existing semantics, including hash-keyed dedupe of copies).
- `FileImportResult` MUST include `localPath`, `contentHashHex`, `fileSize`, `title`, and SHOULD expose `mtimeMs` (or callers `stat` once) for Drift `localMtimeMs`.
- `importPickedFile` / `importPickedFileExpectingHash` MAY become thin wrappers around this method for call-site compatibility.
- `importBytes` MUST remain copy/write into `media/` (Craft / synthesized audio).

---

## C3. `FileStorage.deleteAppManagedMedia`

```dart
/// Best-effort delete when [fileUri] points at app-managed media/. No-op for external links.
Future<void> deleteAppManagedMedia(String? fileUri);
```

**Invariants**:

- MUST NOT delete files outside `{documents}/media/`.
- Missing file / null URI → no-op (no throw).

---

## C4. `MediaLibraryRepository` call sites

| Method | Contract change |
|--------|-----------------|
| `importMedia` | Use link-or-copy; set `localMtimeMs`; on existing id refresh URI/size/mtime; sync `create` vs `update` appropriately |
| `relocateLocalFile` | Use link-or-copy with `expectedHashHex`; update URI/size/mtime; delete previous app-managed file if path changed and old was app-managed |
| `deleteMedia` | After row delete (+ sync), call `deleteAppManagedMedia(oldLocalUri)` |
| `importCraftedFromText` | Unchanged (`importBytes`) |
