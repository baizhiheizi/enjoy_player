import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/ipa_mapping.dart';

/// Familiar-form expectations captured from the pre-optimization
/// implementation.
const Map<List<String>, String> _kGoldenVectors = <List<String>, String>{
  ['ɪʊrɛː']: 'ɪʊre:',
  ['nʋɜː', 'aɪɟz']: 'nvɝːaɪgz',
  ['ɟːaʊ', 'ʉɯ', 'ɳ']: 'gaʊuːn',
  ['ŋɑːɹ', ':ðɰ', 'jʀ', 'tʉɯu']: 'ŋɑːrðwjrtuːuː',
  ['ħɮ', 'æ', 'ɜrʊɹoʊr']: 'hæɜrʊroʊr',
  ['ʐn̩']: 'zn',
  ['ɞ']: 'əː',
  [':oː', 'iːaʊ', 'ɱʈ', 'b']: 'oːiːaʊmtb',
  ['ɔɪ', 'ɡⱱ', '◌˞x', 'ʉɯ']: 'ɔɪgkuː',
  ['g', 'eɪɟɽ', 'zˌ']: 'geɪgrz',
  ['œjɛː']: 'æje:',
  ['ɛɹ?oʊ', 'œsχ']: 'er?oʊæsh',
  ['ɤɽv', 'ʀ', 'ŋʙʌ']: 'ɑːrvrŋrʌ',
  ['oʊrɽ', 'ɛ']: 'oʊrre',
  ['ŋɢx', 'aɪɚɵ', 'tʊʈ', 'ʃɝɑ']: 'ŋgkaɪətʊtʃɝɑ',
  ['ʒɲħ', 'ɶiəɵ', '◌˞oʊaʊ', 'ɣ']: 'ʒjhɑiəəoʊaʊg',
  ['ɢɡʔ', 'ðʈʃ', 'ç']: 'ggtðtʃ',
  ['ɦ']: 'h',
  ['ʈʈ', 'ʒ', 'uːe', 'œˌk']: 'ttʒuːeæk',
  ['ɭrʊ']: 'lrʊ',
  ['ɛ', 'ɛreiə']: 'eereiə',
  ['ɻ']: 'r',
  ['ɭi', 'ˌɪʈʃ', 'ɹ̩β', 'ɱn̩']: 'ˌliɪtʃrvmn',
  ['ɱkɲ', 'ɸfoʊr']: 'mkjffoʊr',
  ['u', 'ræ', 'ɜr']: 'uːræɜr',
  ['ɳɻɲ', 'rt', 'ɰʃ']: 'nrjrtwʃ',
  ['ɮχ', 'ʁŋd']: 'hrŋd',
  ['ɔːeɪx', 'n̩ɶ']: 'ɔːeɪknɑ',
  ['ⱱ', 'ɝɨ']: 'ɝi',
  ['tstʃaɪ', 'ɜrɟɸ', 'θ', 'ɔr']: 'tztʃaɪɜrgfθɔr',
  ['ʙʔuː']: 'rtuː',
  ['ɜrɐa', 'ɢ']: 'ɜrəɑg',
  ['rɝɑr']: 'rɝɑr',
  ['ʌəl', 'ɳ']: 'ʌəln',
  ['ɸ', 'uːdʈ', 'ɰç', 'jɸ']: 'fuːdtwjf',
  ['ɚ']: 'ɚ',
  ['ɪɹ', 'ɞ', 'irəʊ', 'u']: 'ɪrəːiroʊuː',
  ['ʔvyɨ', 'ɐ']: 'tviːə',
  ['p']: 'p',
  ['ɘʎɵ', 'ʔʐ', 'ˌwɢ', 'ɰɑː']: 'əjətzwgwɑː',
  ['ⱱʈʃ', 'ɹ', 'ɶrθ']: 'tʃrɑrθ',
  ['oʊe']: 'oʊe',
  ['ltʃ']: 'ltʃ',
  ['ɱ']: 'm',
  ['ʂk', 'eoːɹq', 'χ', 'uː']: 'skeɔːrkhuː',
  ['ɑː', 'tʃb', 'ʏʈ', 'ɬŋʙ']: 'ɑːtʃbɪtŋr',
  ['ɹ̩ʀr']: 'rrr',
  ['ᵻɡn', 'ɜrɣʙ']: 'i:gnɜrgr',
  ['ɤɜ', 'æ', 'ʙχ']: 'ɑːɝærh',
  ['ɤ', 'uˈ', 'tʃ', 'ɾŋ']: 'ɑːuːtʃtŋ',
  ['ʌɝ', ':dʒf', 'ɞɴ']: 'ʌɝdʒfəːŋ',
  ['øə', 'ɜɶ']: 'eəɝɑ',
  ['ɔːɹɢ']: 'ɔːrg',
  ['ŋ']: 'ŋ',
  ['ɑːɹ', 'j', 'ɤ', 'ɜiəʈʃ']: 'ɑːrjɑːɝiətʃ',
  ['ɛɹæ', 'ə', 'ɘ']: 'eræəə',
  ['ɨoʊr', 'ʔ', 'g']: 'ioʊrtg',
  ['ɛːⱱ', 'oʊrʋɟ', 'oːɹ']: 'e:oʊrvgɔːr',
  ['ɒ']: 'ɑː',
  ['aʊ', 'əl', 'ɣʋaʊ', 'ʏɹ̩']: 'aʊəlgvaʊɪr',
  ['cɑːɹ', ':', '◌˞aɪəɴ', 'ɛɹɑː']: 'kɑːraɪəŋerɑː',
  ['ɛːɾ']: 'e:t',
  ['b']: 'b',
  ['tsˌ', 'ɦ', 'ʙ', 'ɰʒf']: 'tzhrwʒf',
  ['ɟ', 'ɔːɨ', 'aɪɚə', 'xb']: 'gɔːiaɪəkb',
  ['fts', 'ɜrɮɟ', 'ɭ?ʌ', 'çʐ']: 'ftzɜrgl?ʌz',
  ['ɽ', 'lkʊɹ', 'ˈc']: 'rlkʊrk',
  ['ɜ']: 'ɝ',
  ['fɚ', 'aoəʊ', 'e', 'ʊɹɜːɔ']: 'fɚɑooʊeʊrɝːɔ',
  ['əl', 'ˌɜːi']: 'əlˌɝːi',
  ['oŋɹ']: 'oŋr',
  ['χʉɯɭ', 'oʊuː']: 'huːloʊuː',
  ['f', 'eɪβ']: 'feɪv',
  ['oː', 'tʃaɪəəl', 'u', 'l']: 'oːtʃaɪəəluːl',
  ['yɨɑː', 'irɔːɹm', 'ɴiə']: 'iːɑːirɔːrmŋiə',
  ['ɡɹ', 'udʒoːɹ']: 'gruːdʒɔːr',
  ['ɶpʈʃ', 'ɕɦɵ']: 'ɑptʃɕhə',
  ['ɖʊɹ', 'oʏɱ', 'ŋu']: 'dʊroɪmŋuː',
  ['uːʉɯ', 'p']: 'uːuːp',
  ['jʂ', 'œɔrʈʃ', 'ɐ', 'ɹð◌˞']: 'jsæɔrtʃərð',
  ['ɽʎ', 'ɑːɛw']: 'rjɑːew',
  ['ɦuː', 'ɛ']: 'huːe',
  ['uː', 'w', 'e', 'ɔɛɹᵻ']: 'uːweɔeri:',
  ['iəkeɪ', 'i', '?ɪɹ']: 'iəkeɪi?ɪr',
  ['ɲ']: 'j',
  ['k', 'v◌˞ç', 'əʊɛrə', 'ɪdʒ']: 'kvoʊerəɪdʒ',
  ['ⱱkiː', 'ɛr']: 'kiːer',
  ['çx']: 'k',
  ['s']: 's',
  ['ɛø', 'ɟ', 'ɹɡɭ', 'oːɹj']: 'eegrglɔːrj',
  ['ʁi']: 'ri',
  ['ɢ']: 'g',
  ['ɻ', 'ø', 'ʐ', 'ɜrʒ']: 'rezɜrʒ',
  ['ɖ', 'ɐɰyɨ']: 'dəwiː',
  ['əʊɤ']: 'oʊɑː',
  ['ɑrx']: 'ɑrk',
  ['ʐəl']: 'zəl',
  ['ɑːɹɛɜ']: 'ɑːreɝ',
  ['ɵts', 'ɒɕ']: 'ətzɑːɕ',
  ['zɨ']: 'zi',
  ['mɰ']: 'mw',
  ['uː']: 'uː',
  ['oɸŋ', 'ɶoʊr', 'ɱuːɞ', 'ɬʐ']: 'ofŋɑoʊrmuːəːz',
  ['p', 'oːɹ', 'ɾɕɸ']: 'pɔːrtɕf',
  ['sʊɹ', 'ʊ', 'kə', 'ʊɹθ']: 'sʊrʊkəʊrθ',
  ['ɹpʃ', 'ʁɚɹ̩', 'aʊħ', 'u']: 'rpʃrɚraʊhuː',
  ['u', 'ʏɲz']: 'uːɪjz',
  ['χɞ']: 'həː',
  ['ɴɦ']: 'ŋh',
  ['əʊɑːɹ']: 'oʊɑːr',
  ['qŋɢ']: 'kŋg',
  ['ɝ', 'j']: 'ɝj',
  ['ɛr', 'ˈ', 'ʊɹii']: 'erʊrii',
  ['ts', 'ⱱts', 'xɖ', 'c']: 'tztzkdk',
  ['ɑrpb', 'ʂaʊɛ', 'ɨ']: 'ɑrpbsaʊei',
  ['cb', 'əʊ']: 'kboʊ',
  ['ɝ', 'aiə', 'dʒoʊr', 'ʈeɪ']: 'ɝɑiədʒoʊrteɪ',
  ['ʏɶ', 'd', 'æiə', 'yɨ']: 'ɪɑdæiəiː',
  ['ɴn̩ɝ', 'ɦ', 'χɰ']: 'ŋnɝhhw',
  ['i']: 'i',
};

/// A 35-word corpus of eSpeak phone chunks with their familiar forms.
const Map<List<String>, String> _kCorpus = <List<String>, String>{
  ['h', 'ə', 'ˈl', 'oʊ']: 'həloʊ',
  ['w', 'ɝld']: 'wɝld',
  ['h', 'ɛ', 'ˈloʊ']: 'heloʊ',
  ['pɹɪri']: 'prɪri',
  ['slɛpt']: 'slept',
  ['naɪt']: 'naɪt',
  ['h', 'ə', 'ɹ', 'oʊ']: 'həroʊ',
  ['ð', 'ə']: 'ðə',
  ['ˈk', 'ɑ', 'n', 'a', 'p']: 'kɑnɑp',
  ['w', 'ə', 'ˈt', 'a']: 'wətɑ',
  ['ˈm', 'ɔ', 'ɹ', 'ɪ', 'n']: 'mɔrɪn',
  ['b', 'ɪ', 's', 'ˈn', 'aɪ']: 'bɪsnaɪ',
  ['ˈf', 'ɪ', 'n', 'ɪ', 'ʃ']: 'fɪnɪʃ',
  ['ˈl', 'ʌ', 'v']: 'lʌv',
  ['ˈw', 'ɔ', 'ɹ', 'd']: 'wɔrd',
  ['ˈt', 'ɪ', 'm', 'ə']: 'tɪmə',
  ['ˈj', 'u', 's', 't']: 'juːst',
  ['ˈh', 'æ', 'p', 'i']: 'hæpi',
  ['ˈb', 'ɛ', 'n', 'd']: 'bend',
  ['ˈst', 'r', 'aɪ', 't']: 'straɪt',
  ['ɹ', 'əʊ', 'd']: 'roʊd',
  ['ˈk', 'ɛ', 'n']: 'ken',
  ['ˈɡ', 'ʌ', 'd']: 'gʌd',
  ['ˈv', 'ɛ', 'l', 'i']: 'veli',
  ['ˈt', 'ɹ', 'aɪ', 'n']: 'traɪn',
  ['ˈpl', 'e', 'n', 'i']: 'pleni',
  ['ˈb', 'ʌ', 't']: 'bʌt',
  ['ˈfl', 'aʊ', 'n', 'd']: 'flaʊnd',
  ['ˈgr', 'eɪ', 'n']: 'greɪn',
  ['ˈbr', 'ɛ', 'k']: 'brek',
  ['ˈθ', 'r', 'i']: 'θri',
  ['ˈk', 'ʌ', 'n']: 'kʌn',
  ['ˈst', 'r', 'ə', 'ŋ', 'θ']: 'strəŋθ',
  ['ˈpr', 'ə', 'n', 'ʌ', 'n', 's', 'i', 'eɪ', 'ʃ', 'ə', 'n']: 'prənʌnsieɪʃən',
  ['ˌɛks', 'p', 'l', 'ɔ', 'ˈr', 'eɪ', 'ʃ', 'ə', 'n']: 'ˌeksplɔreɪʃən',
};

const int _kLines = 200;
const int _kWordsPerLine = 12;

List<List<String>> _buildCorpus() {
  final entries = _kCorpus.keys.toList(growable: false);
  final words = <List<String>>[];
  for (var i = 0; i < _kLines * _kWordsPerLine; i++) {
    words.add(entries[i % entries.length]);
  }
  return words;
}

void main() {
  group('familiar IPA golden vectors', () {
    test('every captured phone list keeps its familiar form', () {
      for (final entry in _kGoldenVectors.entries) {
        expect(
          formatPhonesAsFamiliarIpa(entry.key),
          entry.value,
          reason: 'phones: ${entry.key.join(', ')}',
        );
      }
    });
  });

  group('stress-mark and tokenization semantics', () {
    test('keeps the stress mark attached to the following phoneme', () {
      expect(tokenizeIpaPhonemes('həˈloʊ'), ['h', 'ə', 'ˈl', 'oʊ']);
      expect(tokenizeIpaPhonemes('ˈiː'), ['ˈiː']);
      expect(tokenizeIpaPhonemes('ˈtʃ'), ['ˈtʃ']);
    });

    test('drops a trailing stress mark that has no phoneme after it', () {
      expect(tokenizeIpaPhonemes('ˈaˌ'), ['ˈa']);
      expect(tokenizeIpaPhonemes('ˈ'), isEmpty);
      expect(tokenizeIpaPhonemes('ˌ'), isEmpty);
    });

    test('keeps a second stress mark as its own token', () {
      expect(tokenizeIpaPhonemes('ˈˌa'), ['ˈˌ', 'a']);
      expect(tokenizeIpaPhonemes('aˌˈ'), ['a', 'ˌˈ']);
    });

    test('removes only the first stress mark when converting', () {
      expect(convertIpaToNormal('ˈaˌ', marked: true), 'ˈaˌ');
      expect(convertIpaToNormal('ˈaˌ', marked: false), 'aˌ');
      expect(convertIpaToNormal('aˌˈ', marked: true), 'ˌaˈ');
    });

    test('prefers the longest matching phoneme', () {
      expect(tokenizeIpaPhonemes('tʃ'), ['tʃ']);
      expect(tokenizeIpaPhonemes('ʈʃ'), ['ʈʃ']);
      expect(tokenizeIpaPhonemes('n̩'), ['n̩']);
      expect(tokenizeIpaPhonemes('◌˞'), ['◌˞']);
      expect(tokenizeIpaPhonemes('ts'), ['ts']);
    });

    test('keeps an unknown character as its own token', () {
      expect(tokenizeIpaPhonemes('x'), ['x']);
      expect(tokenizeIpaPhonemes('ˈx'), ['ˈx']);
    });

    test('splits an astral character into its surrogate halves', () {
      expect(tokenizeIpaPhonemes('a\u{1F600}b'), [
        'a',
        '\uD83D',
        '\uDE00',
        'b',
      ]);
      expect(convertIpaToNormal('a\u{1F600}b', marked: true), 'a\u{1F600}b');
    });

    test('keeps the familiar form of an astral phone label', () {
      expect(formatPhonesAsFamiliarIpa(['\u{1F600}', 'a']), '\u{1F600}ɑ');
    });

    test('shifts the stress onto a preceding consonant', () {
      expect(convertWordIpaToNormal(['h', 'ə', 'ˈl', 'oʊ']), [
        'h',
        'ə',
        'l',
        'oʊ',
      ]);
      expect(convertWordIpaToNormal(['h', 'ˈə', 'l']), ['ˈh', 'ə', 'l']);
      expect(convertWordIpaToNormal(['ˈh', 'ə', 'l']), ['h', 'ə', 'l']);
    });
  });

  group('familiar IPA at transcript scale', () {
    test('derives the familiar form of every word of a 2400-word corpus', () {
      final words = _buildCorpus();
      expect(words, hasLength(_kLines * _kWordsPerLine));

      for (var line = 0; line < _kLines; line++) {
        final derived = <String>[];
        for (var w = 0; w < _kWordsPerLine; w++) {
          final phones = words[line * _kWordsPerLine + w];
          derived.add(formatPhonesAsFamiliarIpa(phones));
        }
        final expected = <String>[
          for (var w = 0; w < _kWordsPerLine; w++)
            _kCorpus[words[line * _kWordsPerLine + w]]!,
        ];
        expect(derived, equals(expected), reason: 'line $line');
      }
    });

    test('derives a 2400-word corpus under the loose ceiling (local only)', () {
      final words = _buildCorpus();

      for (final phones in words) {
        formatPhonesAsFamiliarIpa(phones);
      }

      final sw = Stopwatch()..start();
      const runs = 20;
      for (var i = 0; i < runs; i++) {
        for (final phones in words) {
          formatPhonesAsFamiliarIpa(phones);
        }
      }
      sw.stop();

      final medianMs = sw.elapsedMicroseconds / runs / 1000;
      // ignore: avoid_print
      print(
        'familiar IPA: ${medianMs.toStringAsFixed(2)} ms/pass (2400 words)',
      );
      expect(medianMs, lessThan(100));
    }, skip: 'Local-only microbenchmark; run with --run-skipped.');
  });
}
