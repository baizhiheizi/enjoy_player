import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/json/gated_json_decode.dart';

void main() {
  test('decodes payloads at or below the threshold', () async {
    final decoded = await decodeJsonGated(jsonEncode({'a': 1}));
    expect(decoded, {'a': 1});
  });

  test(
    'decodes payloads above the threshold through the isolate path',
    () async {
      final body = jsonEncode({
        'padding': List<String>.filled(kGatedJsonDecodeBytes + 1, 'x'),
      });
      expect(body.length, greaterThan(kGatedJsonDecodeBytes));
      final decoded = await decodeJsonGated(body);
      expect((decoded as Map<String, dynamic>)['padding'], isNotEmpty);
    },
  );

  test('propagates FormatException from the isolate path', () async {
    final body = '${' ' * (kGatedJsonDecodeBytes + 1)}not json';
    await expectLater(decodeJsonGated(body), throwsFormatException);
  });

  test('applies a custom decoder on both sides of the threshold', () async {
    Object? withEnvelope(String body) => {'decoded': jsonDecode(body)};

    final small = await decodeJsonGated('1', decode: withEnvelope);
    expect(small, {'decoded': 1});

    final big = await decodeJsonGated(
      jsonEncode(List.filled(kGatedJsonDecodeBytes + 1, 1)),
      decode: withEnvelope,
    );
    expect((big as Map<String, dynamic>)['decoded'], isA<List>());
  });
}
