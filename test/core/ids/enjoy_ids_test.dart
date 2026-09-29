import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

/// Comprehensive coverage for [enjoy_ids.dart].
///
/// Mirrors the convention from [`apps/web/src/db/id-generator.ts`] — every
/// function exported by the source file must produce a deterministic ID for a
/// given input and must vary when any input component varies. These tests
/// pin both halves of that contract so a refactor cannot drift them apart.
void main() {
  group('enjoyUuidNamespaceUrl', () {
    test('is the RFC 4122 URL namespace', () {
      expect(enjoyUuidNamespaceUrl, '6ba7b811-9dad-11d1-80b4-00c04fd430c8');
    });

    test('parses as a valid UUID string', () {
      final parsed = Uuid.parse(enjoyUuidNamespaceUrl, validate: true);
      expect(parsed, isNotNull);
    });
  });

  group('enjoyVideoId', () {
    test('returns a UUID v5 (36 chars, dashed)', () {
      final id = enjoyVideoId(vid: 'abc');
      expect(id.length, 36);
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
            r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('defaults the provider to "user"', () {
      final implicit = enjoyVideoId(vid: 'abc');
      final explicit = enjoyVideoId(provider: 'user', vid: 'abc');
      expect(implicit, explicit);
    });

    test('is stable for a given provider + vid', () {
      final a = enjoyVideoId(vid: 'abc');
      final b = enjoyVideoId(vid: 'abc');
      expect(a, b);
    });

    test('changes when the provider changes', () {
      final user = enjoyVideoId(provider: 'user', vid: 'abc');
      final netflix = enjoyVideoId(provider: 'netflix', vid: 'abc');
      expect(user, isNot(netflix));
    });

    test('changes when the vid changes', () {
      final a = enjoyVideoId(vid: 'abc');
      final b = enjoyVideoId(vid: 'xyz');
      expect(a, isNot(b));
    });
  });

  group('enjoyAudioId', () {
    test('returns a UUID v5 (36 chars, dashed)', () {
      final id = enjoyAudioId(aid: '010203');
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
            r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('defaults the provider to "user"', () {
      final implicit = enjoyAudioId(aid: '010203');
      final explicit = enjoyAudioId(provider: 'user', aid: '010203');
      expect(implicit, explicit);
    });

    test('changes when the provider changes', () {
      final user = enjoyAudioId(provider: 'user', aid: '010203');
      final yt = enjoyAudioId(provider: 'youtube', aid: '010203');
      expect(user, isNot(yt));
    });

    test('does not collide with enjoyVideoId for the same key', () {
      final video = enjoyVideoId(vid: 'abc');
      final audio = enjoyAudioId(aid: 'abc');
      expect(video, isNot(audio));
    });
  });

  group('enjoySha256HexOfString', () {
    test('returns a 64-char lowercase hex digest', () {
      final hex = enjoySha256HexOfString('abc');
      expect(hex.length, 64);
      expect(hex, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('matches sha256.convert for an ASCII input', () {
      const input = 'abc';
      final want = sha256.convert(utf8.encode(input)).toString();
      expect(enjoySha256HexOfString(input), want);
    });

    test('is stable for a given input', () {
      expect(
        enjoySha256HexOfString('hello world'),
        enjoySha256HexOfString('hello world'),
      );
    });

    test('handles the empty string (sha256 of empty bytes)', () {
      expect(
        enjoySha256HexOfString(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('handles unicode correctly via utf8.encode', () {
      final want = sha256.convert(utf8.encode('héllo')).toString();
      expect(enjoySha256HexOfString('héllo'), want);
    });
  });

  group('enjoyLocalAudioAid', () {
    test('is sha256(contentHashHex:userId) hex', () {
      const content = 'abc123';
      const user = 'u1';
      final want = sha256.convert(utf8.encode('$content:$user')).toString();
      expect(enjoyLocalAudioAid(contentHashHex: content, userId: user), want);
    });

    test('is stable for a given contentHash + userId', () {
      const content = 'content-a';
      const user = 'u1';
      expect(
        enjoyLocalAudioAid(contentHashHex: content, userId: user),
        enjoyLocalAudioAid(contentHashHex: content, userId: user),
      );
    });

    test('differs when contentHash differs', () {
      const user = 'u1';
      final a = enjoyLocalAudioAid(contentHashHex: 'one', userId: user);
      final b = enjoyLocalAudioAid(contentHashHex: 'two', userId: user);
      expect(a, isNot(b));
    });

    test('differs when userId differs (scoped per user)', () {
      const content = 'same-bytes';
      final a = enjoyLocalAudioAid(contentHashHex: content, userId: 'alice');
      final b = enjoyLocalAudioAid(contentHashHex: content, userId: 'bob');
      expect(a, isNot(b));
    });

    test('does not collide with the audio api UUID for the same input', () {
      final local = enjoyLocalAudioAid(contentHashHex: 'x', userId: 'u');
      final api = enjoyAudioId(aid: 'x');
      expect(local, isNot(api));
    });
  });

  group('enjoyLocalVideoVid', () {
    test('is content-addressed (ignores userId)', () {
      const content = 'abc123';
      expect(enjoyLocalVideoVid(contentHashHex: content), content);
      expect(
        enjoyLocalVideoVid(contentHashHex: content, userId: 'alice'),
        enjoyLocalVideoVid(contentHashHex: content, userId: 'bob'),
      );
    });
  });

  group('enjoyTranscriptId', () {
    test('returns a UUID v5 (36 chars, dashed)', () {
      final id = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
            r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('is stable for the same target / language / source', () {
      const args = (
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      final a = enjoyTranscriptId(
        targetType: args.targetType,
        targetId: args.targetId,
        language: args.language,
        source: args.source,
      );
      final b = enjoyTranscriptId(
        targetType: args.targetType,
        targetId: args.targetId,
        language: args.language,
        source: args.source,
      );
      expect(a, b);
    });

    test('changes when targetType changes', () {
      final audio = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      final video = enjoyTranscriptId(
        targetType: 'video',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      expect(audio, isNot(video));
    });

    test('changes when targetId changes', () {
      final a = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      final b = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't2',
        language: 'en',
        source: 'captions',
      );
      expect(a, isNot(b));
    });

    test('changes when language changes', () {
      final en = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      final zh = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'zh',
        source: 'captions',
      );
      expect(en, isNot(zh));
    });

    test('changes when source changes', () {
      final captions = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'captions',
      );
      final whisper = enjoyTranscriptId(
        targetType: 'audio',
        targetId: 't1',
        language: 'en',
        source: 'whisper',
      );
      expect(captions, isNot(whisper));
    });
  });

  group('enjoyVocabularyItemId', () {
    test('returns a UUID v5', () {
      final id = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
            r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('is stable for same word / language / targetLanguage', () {
      final a = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      final b = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      expect(a, b);
    });

    test('changes when targetLanguage changes', () {
      final zh = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      final en = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'en',
      );
      expect(zh, isNot(en));
    });

    test('changes when normalizedWord changes', () {
      final a = enjoyVocabularyItemId(
        normalizedWord: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      final b = enjoyVocabularyItemId(
        normalizedWord: 'world',
        language: 'en',
        targetLanguage: 'zh',
      );
      expect(a, isNot(b));
    });
  });

  group('enjoyVocabularyContextId', () {
    test('returns a UUID v5', () {
      final id = enjoyVocabularyContextId(
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'Hello world',
        stableLocatorJson: '{"duration":1,"start":0,"type":"media"}',
      );
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
            r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('is stable for same inputs', () {
      const args = (
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'Hello world',
        stableLocatorJson: '{"duration":1,"start":0,"type":"media"}',
      );
      final a = enjoyVocabularyContextId(
        vocabularyItemId: args.vocabularyItemId,
        sourceType: args.sourceType,
        sourceId: args.sourceId,
        text: args.text,
        stableLocatorJson: args.stableLocatorJson,
      );
      final b = enjoyVocabularyContextId(
        vocabularyItemId: args.vocabularyItemId,
        sourceType: args.sourceType,
        sourceId: args.sourceId,
        text: args.text,
        stableLocatorJson: args.stableLocatorJson,
      );
      expect(a, b);
    });

    test('truncates text to 100 chars for the name string', () {
      final short = enjoyVocabularyContextId(
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'a' * 100,
        stableLocatorJson: '{}',
      );
      final long = enjoyVocabularyContextId(
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'a' * 150,
        stableLocatorJson: '{}',
      );
      expect(short, long);
    });

    test('changes when locator JSON changes', () {
      final a = enjoyVocabularyContextId(
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'x',
        stableLocatorJson: '{"duration":1,"start":0,"type":"media"}',
      );
      final b = enjoyVocabularyContextId(
        vocabularyItemId: 'item-1',
        sourceType: 'Video',
        sourceId: 'v1',
        text: 'x',
        stableLocatorJson: '{"duration":2,"start":0,"type":"media"}',
      );
      expect(a, isNot(b));
    });
  });

  group('cross-function stability', () {
    test('enjoyVideoId + enjoyAudioId + enjoyTranscriptId share namespace', () {
      final v = enjoyVideoId(vid: 'k');
      final a = enjoyAudioId(aid: 'k');
      final t = enjoyTranscriptId(
        targetType: 'x',
        targetId: 'k',
        language: 'en',
        source: 'src',
      );
      expect(v[14], '5');
      expect(a[14], '5');
      expect(t[14], '5');
    });

    test('across a restart-like cycle, IDs are bit-identical', () {
      for (var i = 0; i < 3; i++) {
        expect(enjoyVideoId(vid: 'k'), enjoyVideoId(vid: 'k'));
        expect(enjoyAudioId(aid: 'k'), enjoyAudioId(aid: 'k'));
        expect(
          enjoyTranscriptId(
            targetType: 't',
            targetId: 'k',
            language: 'en',
            source: 's',
          ),
          enjoyTranscriptId(
            targetType: 't',
            targetId: 'k',
            language: 'en',
            source: 's',
          ),
        );
        expect(enjoySha256HexOfString('k'), enjoySha256HexOfString('k'));
      }
    });
  });
}
