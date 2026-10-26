import 'dart:math';

import 'package:enjoy_player/features/transcript/data/transcript_timeline_codec.dart';
import 'package:flutter_test/flutter_test.dart';

const _loneHighSurrogate = 0xD800;
const _loneLowSurrogate = 0xDC00;
const _highSurrogateTop = 0xDBFF;
const _lowSurrogateBottom = 0xDFFF;

List<String> _curatedStrings() => <String>[
  '',
  'a',
  'abc',
  'hello world',
  ' ',
  '\n',
  '\t',
  '\u0000',
  '\u007F',
  '\u0080',
  '߿',
  'ࠀ',
  '�',
  '￿',
  '\u{1D400}',
  '\u{10FFFF}',
  '😀',
  '👋',
  'héllo',
  '你好世界',
  'Здравствуй',
  '🎉 party 🎊 time',
  'mixed ascii and 日本語 and 😀 and 🎉',
  'é combining',
  'emoji with ZWJ 👨‍👩‍👧‍👦 family',
  'flag 🇯🇵 regional',
  'skin tone 👍🏽 modifier',
  String.fromCharCode(_loneHighSurrogate),
  String.fromCharCode(_loneLowSurrogate),
  '${String.fromCharCode(_loneHighSurrogate)}a',
  'a${String.fromCharCode(_loneLowSurrogate)}',
  String.fromCharCode(_loneHighSurrogate) +
      String.fromCharCode(_loneLowSurrogate),
  String.fromCharCode(_loneHighSurrogate) +
      String.fromCharCode(_loneHighSurrogate),
  String.fromCharCode(_loneLowSurrogate) +
      String.fromCharCode(_loneLowSurrogate),
  'prefix ${String.fromCharCode(_loneHighSurrogate)}'
      '${String.fromCharCode(_loneLowSurrogate)} suffix',
  '😀' * 64,
  'a' * 1024,
];

List<int> _fuzzCodeUnitPool() => <int>[
  0x41,
  0x20,
  0x0A,
  0x22,
  0x5C,
  0x7F,
  0xE9,
  0x4E2D,
  0xFFFD,
  _loneHighSurrogate,
  _loneHighSurrogate + 1,
  _highSurrogateTop,
  _loneLowSurrogate,
  _loneLowSurrogate + 1,
  _lowSurrogateBottom,
  0xD83D,
  0xDE00,
];

void main() {
  group('timelineJsonCharacterCount', () {
    test('counts curated strings exactly', () {
      expect(timelineJsonCharacterCount(''), 0);
      expect(timelineJsonCharacterCount('abc'), 3);
      expect(timelineJsonCharacterCount('é'), 1);
      expect(timelineJsonCharacterCount('😀'), 1);
      expect(timelineJsonCharacterCount('a😀b'), 3);
      expect(timelineJsonCharacterCount('👍🏽'), 2);
      expect(timelineJsonCharacterCount('👨‍👩‍👧‍👦'), 7);
      expect(
        timelineJsonCharacterCount(String.fromCharCode(_loneHighSurrogate)),
        1,
      );
      expect(
        timelineJsonCharacterCount(
          String.fromCharCode(_loneHighSurrogate) +
              String.fromCharCode(_loneLowSurrogate),
        ),
        1,
      );
    });

    test('matches the rune count for curated strings', () {
      for (final value in _curatedStrings()) {
        expect(
          timelineJsonCharacterCount(value),
          value.runes.length,
          reason: 'mismatch for ${value.length} code units',
        );
      }
    });

    test('matches the rune count for fuzzed strings', () {
      final random = Random(20261025);
      final pool = _fuzzCodeUnitPool();
      for (var iteration = 0; iteration < 20000; iteration++) {
        final length = random.nextInt(24);
        final units = List<int>.generate(
          length,
          (_) => pool[random.nextInt(pool.length)],
        );
        final value = String.fromCharCodes(units);
        expect(
          timelineJsonCharacterCount(value),
          value.runes.length,
          reason: 'mismatch for ${units.join(',')}',
        );
      }
    });

    test('matches the rune count for a transcript-shaped payload', () {
      final buffer = StringBuffer('[');
      for (var index = 0; index < 500; index++) {
        if (index > 0) buffer.write(',');
        buffer.write(
          '{"text":"line $index 🎵 日本語","startMs":${index * 1000},'
          '"durationMs":900,"timeline":null}',
        );
      }
      buffer.write(']');
      final payload = buffer.toString();
      expect(timelineJsonCharacterCount(payload), payload.runes.length);
    });
  });
}
