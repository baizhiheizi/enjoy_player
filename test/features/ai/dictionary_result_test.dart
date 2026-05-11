import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';

void main() {
  test('DictionaryResult.fromJson parses senses', () {
    final json = <String, dynamic>{
      'word': 'run',
      'sourceLanguage': 'en',
      'targetLanguage': 'zh',
      'lemma': 'run',
      'ipa': '/rʌn/',
      'senses': [
        {
          'definition': 'to move quickly on foot',
          'translation': '跑',
          'partOfSpeech': 'verb',
          'examples': [
            {'source': 'I run.', 'target': '我跑。'},
          ],
        },
      ],
    };
    final r = DictionaryResult.fromJson(json);
    expect(r.word, 'run');
    expect(r.senses.length, 1);
    expect(r.senses.first.translation, '跑');
    expect(r.senses.first.examples!.length, 1);
    expect(r.senses.first.examples!.first.target, '我跑。');
  });
}
