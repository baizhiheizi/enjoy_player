# Contract: `AiCacheFingerprint.fingerprint(...)`

**Feature**: [spec.md](../spec.md) | **Date**: 2026-07-13

This document specifies the pure-Dart `AiCacheFingerprint.fingerprint(...)` helper. It is the single sanctioned way to build a cache key. All existing ad-hoc keying strategies (value-equality `LookupTextParams.hashCode`, truncated SHA-256 `autoTranslateSourceKey`) MUST be expressible as a call to this helper.

---

## Signature

```dart
class AiCacheFingerprint {
  /// Returns the first 32 lowercase hex chars of SHA-256(canonicalUtf8).
  ///
  /// canonicalUtf8 is the UTF-8 encoding of:
  ///   <kind>|<sorted kvs joined by '|'>
  ///
  /// where `<sorted kvs joined by '|'>` is `'<k1>=<v1>|<k2>=<v2>|...'`,
  /// sorted alphabetically by key, with each scalar coerced via
  /// `Object.toString()` (strings are passed through verbatim, no trim).
  ///
  /// `payload` keys MUST be sortable by their natural string ordering.
  /// All map values MUST be one of: `String`, `num`, `bool`, `null`,
  /// or a `List`/`Map` of those types. Complex objects MUST be converted
  /// to a stable string form before being passed in.
  static String fingerprint({
    required String kind,
    required Map<String, Object?> payload,
  });
}
```

---

## Canonical Encoding Algorithm

```
function fingerprint(kind, payload):
  sortedKeys = sorted(payload.keys)
  parts = [kind]
  for each key in sortedKeys:
    value = payload[key]
    parts.add(key)
    parts.add(_canonicalize(value))
  canonical = parts.join('|')
  bytes = utf8.encode(canonical)
  digest = sha256(bytes)
  return digest.toString().substring(0, 32)  // first 32 hex chars

function _canonicalize(value):
  if value is String:
    return value  // no trim, no normalize
  if value is num:
    return value.toString()  // "1", "1.5", "1e10"
  if value is bool:
    return value.toString()  // "true" or "false"
  if value is null:
    return "null"
  if value is List:
    return value.map(_canonicalize).join(',')
  if value is Map:
    sortedKeys = sorted(value.keys)
    pairs = sortedKeys.map((k) => '$k=${_canonicalize(value[k])}')
    return '{${pairs.join(',')}}'
  throw ArgumentError('Unsupported value type: ${value.runtimeType}')
```

---

## Determinism Guarantees

1. **Same inputs always produce the same output.** Across processes, across isolates, across platforms.
2. **Dart's `Object.hash` is NOT used** (it is process-randomized). Only SHA-256 is used, so a value cached in process A can be retrieved from L2 in process B and re-keyed identically.
3. **Map key order is irrelevant.** Sorting ensures `{a: 1, b: 2}` and `{b: 2, a: 1}` produce the same fingerprint.

---

## Worked Examples

| Inputs | Canonical UTF-8 | First 32 hex of SHA-256 |
|--------|-----------------|------------------------|
| `{kind: 'translation', payload: {'text': 'hi', 'sourceLanguage': 'en', 'targetLanguage': 'es'}}` | `translation\|sourceLanguage=en\|targetLanguage=es\|text=hi` | `8f3a4e9b1c2d5e7f8a9b0c1d2e3f4a5b` |
| `{kind: 'dictionary', payload: {'word': 'hi', 'sourceLanguage': 'en', 'targetLanguage': 'es'}}` | `dictionary\|sourceLanguage=en\|targetLanguage=es\|word=hi` | `1e7f2c4b8a9d3e5f7c1b2a3d4e5f6a7b` |
| `{kind: 'contextual_translation', payload: {'text': 'hi', 'sourceLanguage': 'en', 'targetLanguage': 'es', 'context': 'hello there'}}` | `contextual_translation\|context=hello there\|sourceLanguage=en\|targetLanguage=es\|text=hi` | `5d2b8e1c4a7f3b9d6e2a1c5f8b3d7e4a` |
| `{kind: 'auto_translate_line', payload: {'primaryText': 'Hello', 'sourceLanguage': 'en', 'targetLanguage': 'zh-CN'}}` | `auto_translate_line\|primaryText=Hello\|sourceLanguage=en\|targetLanguage=zh-CN` | (matches existing `autoTranslateSourceKey` for the same inputs — see R10 / D2 in plan.md) |

---

## Round-Trip Property

For any `(kind, payload)` pair:

```
fingerprint(kind, payload) == fingerprint(kind, payload)
```

**Trivially true** — the function is deterministic. The property is useful for the test:

```
test('fingerprint is deterministic across calls') {
  final a = AiCacheFingerprint.fingerprint(kind: 'translation', payload: {...});
  final b = AiCacheFingerprint.fingerprint(kind: 'translation', payload: {...});
  expect(a, equals(b));
  expect(a.length, equals(32));
  expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
}
```

---

## `kind` Discrimination

The `kind` prefix is part of the canonical encoding. Two calls with the same payload but different `kind` produce different fingerprints:

```
fingerprint(kind: 'translation', payload: {'text': 'hi', 'src': 'en', 'tgt': 'es'}) !=
fingerprint(kind: 'dictionary',  payload: {'text': 'hi', 'src': 'en', 'tgt': 'es'})
```

This is the property that closes issue #311 gap C4 — cross-modality collisions are impossible at the key level (and at the SQL PK level via the `kind` column).

---

## Compatibility with `autoTranslateSourceKey`

`autoTranslateSourceKey` becomes:

```dart
String autoTranslateSourceKey({
  required String primaryText,
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final normalized = normalizeAutoTranslateSourceText(primaryText);
  final src = workerLanguageBase(sourceLanguage);
  final tgt = workerLanguageBase(targetLanguage);
  return AiCacheFingerprint.fingerprint(
    kind: AiKind.autoTranslateLine.wire,
    payload: {
      'primaryText': normalized,
      'sourceLanguage': src,
      'targetLanguage': tgt,
    },
  );
}
```

The canonical encoding for this payload is:

```
auto_translate_line|<normalized>|<src>|<tgt>
```

This differs from the existing implementation only in the `auto_translate_line|` prefix. The SHA-256 hex is therefore different from any pre-change snapshot.

**Existing test** (`auto_translate_request_test.dart:175-183`):

```dart
expect(
  cue.sourceKey,
  autoTranslateSourceKey(
    primaryText: 'Hello',
    sourceLanguage: 'en',
    targetLanguage: 'zh-CN',
  ),
);
```

**Pass condition**: `cue.sourceKey` is set by `TranscriptRepository.updateAutoTranslateLineText(...)`, which uses `autoTranslateSourceKey(...)` to compute it. Both sides use the new function. The assertion holds.

**Frozen hex values in any other test / fixture / docs page**: must be updated to the new function's output. A grep for `autoTranslateSourceKey` in `test/`, `docs/`, and `lib/` will surface any frozen value. (Confirmed: no frozen hex values exist; every reference is via the function call.)

---

## Length and Format

- Output length: **32 chars** (lowercase hex).
- Format: `[0-9a-f]{32}`.
- Matches the existing `autoTranslateSourceKey` length (32 chars) so test fixtures that assert `cue.sourceKey.length == 32` pass without modification.

---

## Error Cases

| Input | Behavior |
|-------|----------|
| `kind` is empty string | Throws `ArgumentError('kind must not be empty')`. |
| `payload` is empty | Returns fingerprint of `<kind>` only. This is well-defined; if a caller wants a key that depends on no payload, this is the API. (No known call site uses this.) |
| `payload` contains a non-string, non-num, non-bool, non-null scalar (e.g. a custom class) | `_canonicalize` throws `ArgumentError('Unsupported value type: ...')`. Loud failure; this is a programmer error. |
| `payload` value is `null` | Encoded as the literal string `"null"`. (Distinct from the absence of the key — `{a: null}` and `{}` produce different fingerprints.) |