import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/lookup/application/lookup_target_languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const learn = kDefaultLearningLanguageTag;

  group('resolveLookupSource', () {
    test('falls back to learning tag for und / empty / unknown', () {
      expect(resolveLookupSource(null, learningTag: learn), learn);
      expect(resolveLookupSource('', learningTag: learn), learn);
      expect(resolveLookupSource('   ', learningTag: learn), learn);
      expect(resolveLookupSource('und', learningTag: learn), learn);
      expect(resolveLookupSource('ja', learningTag: learn), learn);
    });

    test('canonicalizes en and zh short tags', () {
      expect(resolveLookupSource('en', learningTag: learn), 'en-US');
      expect(resolveLookupSource('EN-us', learningTag: learn), 'en-US');
      expect(resolveLookupSource('en-US', learningTag: learn), 'en-US');
      expect(resolveLookupSource('zh', learningTag: learn), 'zh-CN');
      expect(resolveLookupSource('zh-CN', learningTag: learn), 'zh-CN');
      expect(resolveLookupSource('zh-Hans', learningTag: learn), 'zh-CN');
    });
  });

  group('resolveLookupTarget', () {
    test('canonicalizes supported native tags when distinct from learning', () {
      expect(resolveLookupTarget('zh-CN', learningTag: learn), 'zh-CN');
      expect(resolveLookupTarget('zh', learningTag: learn), 'zh-CN');
      expect(resolveLookupTarget('en-GB', learningTag: learn), 'zh-CN');
    });

    test('when native equals learning, coerces to other supported', () {
      expect(resolveLookupTarget('en-US', learningTag: learn), 'zh-CN');
      expect(resolveLookupTarget(null, learningTag: learn), 'zh-CN');
    });

    test('allows en-US target when learning is zh-CN', () {
      expect(resolveLookupTarget('en-US', learningTag: 'zh-CN'), 'en-US');
    });

    test('normalizes learning tag in fallback path', () {
      expect(resolveLookupSource('und', learningTag: 'zh-cn'), 'zh-CN');
    });
  });
}
