import 'package:enjoy_player/features/ai/application/ai_cache_fingerprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiCacheFingerprint', () {
    test('fingerprint is deterministic across calls', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hello',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      final b = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hello',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      expect(a, equals(b));
    });

    test('fingerprint length is exactly 32 hex chars', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hi',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      expect(a.length, 32);
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('fingerprint discriminates kind with same payload', () {
      final translation = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hi',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      final dictionary = AiCacheFingerprint.fingerprint(
        kind: 'dictionary',
        payload: const {
          'text': 'hi',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      expect(translation, isNot(equals(dictionary)));
    });

    test('fingerprint is order-independent on payload keys', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hi',
          'sourceLanguage': 'en',
          'targetLanguage': 'es',
        },
      );
      final b = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'targetLanguage': 'es',
          'sourceLanguage': 'en',
          'text': 'hi',
        },
      );
      expect(a, equals(b));
    });

    test('fingerprint encodes null as the literal string "null"', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {'text': 'hi', 'sourceLanguage': null},
      );
      final b = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {'text': 'hi', 'sourceLanguage': 'null'},
      );
      // Both encode to the canonical form ...sourceLanguage=null... so the
      // hash matches. This documents the encoding, not a bug.
      expect(a, equals(b));
    });

    test('fingerprint distinguishes missing key from null value', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {'text': 'hi'},
      );
      final b = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {'text': 'hi', 'sourceLanguage': null},
      );
      expect(a, isNot(equals(b)));
    });

    test('fingerprint handles numeric, bool, and list values', () {
      final a = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'text': 'hi',
          'count': 1,
          'rate': 0.5,
          'enabled': true,
          'tags': ['a', 'b'],
        },
      );
      final b = AiCacheFingerprint.fingerprint(
        kind: 'translation',
        payload: const {
          'count': 1,
          'rate': 0.5,
          'enabled': true,
          'tags': 'a,b',
          'text': 'hi',
        },
      );
      // list 'a','b' canonicalises to 'a,b' which equals the scalar 'a,b'.
      expect(a, equals(b));
    });

    test('fingerprint throws ArgumentError on empty kind', () {
      expect(
        () => AiCacheFingerprint.fingerprint(
          kind: '',
          payload: const {'text': 'hi'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fingerprint throws ArgumentError on unsupported value type', () {
      expect(
        () => AiCacheFingerprint.fingerprint(
          kind: 'translation',
          payload: const {'object': _Unsupported()},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

class _Unsupported {
  const _Unsupported();
}
