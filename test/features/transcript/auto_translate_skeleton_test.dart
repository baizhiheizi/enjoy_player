import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAutoTranslateSkeleton', () {
    test('copies timings with empty text', () {
      const primary = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
      ];
      final skeleton = buildAutoTranslateSkeleton(primary);
      expect(skeleton.length, 2);
      expect(skeleton[0].text, '');
      expect(skeleton[0].startMs, 0);
      expect(skeleton[0].durationMs, 1000);
      expect(skeleton[1].startMs, 1000);
    });
  });

  group('isAutoTranslateTimelineStale', () {
    test('stale when reference primary id mismatches', () {
      const primary = [
        TranscriptLine(text: 'a', startMs: 0, durationMs: 1000),
      ];
      const ai = [TranscriptLine(text: '', startMs: 0, durationMs: 1000)];
      expect(
        isAutoTranslateTimelineStale(
          referencePrimaryId: 'old',
          primaryId: 'new',
          primaryLines: primary,
          aiLines: ai,
        ),
        isTrue,
      );
    });

    test('stale when length differs', () {
      const primary = [
        TranscriptLine(text: 'a', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'b', startMs: 1000, durationMs: 500),
      ];
      const ai = [TranscriptLine(text: 'x', startMs: 0, durationMs: 1000)];
      expect(
        isAutoTranslateTimelineStale(
          referencePrimaryId: 'p1',
          primaryId: 'p1',
          primaryLines: primary,
          aiLines: ai,
        ),
        isTrue,
      );
    });
  });

  group('autoTranslateSourceKey', () {
    test('is stable for same normalized text and language pair', () {
      final a = autoTranslateSourceKey(
        primaryText: 'Hello  world',
        sourceLanguage: 'en-US',
        targetLanguage: 'zh-CN',
      );
      final b = autoTranslateSourceKey(
        primaryText: '<b>Hello</b> world',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      );
      expect(a, b);
      expect(a.length, 32);
    });

    test('differs when wording or target language changes', () {
      final base = autoTranslateSourceKey(
        primaryText: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh-CN',
      );
      final wording = autoTranslateSourceKey(
        primaryText: 'Hello!',
        sourceLanguage: 'en',
        targetLanguage: 'zh-CN',
      );
      final lang = autoTranslateSourceKey(
        primaryText: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'ja-JP',
      );
      expect(base, isNot(wording));
      expect(base, isNot(lang));
    });
  });

  group('resolveAutoTranslateSecondaryText', () {
    test('returns index slot when sourceKey matches', () {
      const primary = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
      ];
      final key0 = autoTranslateSourceKey(
        primaryText: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh-CN',
      );
      final ai = [
        TranscriptLine(
          text: '你好',
          startMs: 0,
          durationMs: 1000,
          sourceKey: key0,
        ),
        // Wrong timing neighbor — must not be used for index 0.
        const TranscriptLine(
          text: '世界',
          startMs: 500,
          durationMs: 500,
          sourceKey: 'other',
        ),
      ];
      expect(
        resolveAutoTranslateSecondaryText(
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          sourceLanguage: 'en',
          targetLanguage: 'zh-CN',
        ),
        '你好',
      );
    });

    test('treats key mismatch as empty (soft stale)', () {
      const primary = [
        TranscriptLine(text: 'Hello edited', startMs: 0, durationMs: 1000),
      ];
      final oldKey = autoTranslateSourceKey(
        primaryText: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh-CN',
      );
      final ai = [
        TranscriptLine(
          text: '你好',
          startMs: 0,
          durationMs: 1000,
          sourceKey: oldKey,
        ),
      ];
      expect(
        resolveAutoTranslateSecondaryText(
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          sourceLanguage: 'en',
          targetLanguage: 'zh-CN',
        ),
        isNull,
      );
    });

    test('treats missing sourceKey as empty when languages are known', () {
      const primary = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
      ];
      const ai = [
        TranscriptLine(text: '你好', startMs: 0, durationMs: 1000),
      ];
      expect(
        resolveAutoTranslateSecondaryText(
          primaryLines: primary,
          aiLines: ai,
          lineIndex: 0,
          sourceLanguage: 'en',
          targetLanguage: 'zh-CN',
        ),
        isNull,
      );
    });
  });

  group('findCachedAutoTranslateText', () {
    test('reuses translation for identical sourceKey', () {
      final key = autoTranslateSourceKey(
        primaryText: 'Same',
        sourceLanguage: 'en',
        targetLanguage: 'zh-CN',
      );
      final ai = [
        TranscriptLine(
          text: '相同',
          startMs: 0,
          durationMs: 1000,
          sourceKey: key,
        ),
        const TranscriptLine(text: '', startMs: 1000, durationMs: 500),
      ];
      expect(findCachedAutoTranslateText(aiLines: ai, key: key), '相同');
    });
  });
}
