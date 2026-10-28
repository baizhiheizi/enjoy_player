import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'espeak_events.dart';
import 'espeak_token_mapping.dart';
import 'spoken_reference.dart';

/// Event-clock duration for the phonemesOnly (YouTube IPA) path, which has
/// no PCM to measure. Ends at the last event's *onset*, so the final
/// phoneme collapses to zero width — pre-existing eSpeak limitation, kept
/// because stretching the clock would shift every IPA phone.
@internal
double referenceEventDurationSeconds(
  List<EspeakWordEvent> wordEvents,
  List<EspeakPhoneEvent> phoneEvents,
) {
  var maxMs = 0;
  for (final word in wordEvents) {
    if (word.audioMs > maxMs) maxMs = word.audioMs;
  }
  for (final phone in phoneEvents) {
    if (phone.audioMs > maxMs) maxMs = phone.audioMs;
  }
  if (maxMs <= 0) return 0.05;
  return maxMs / 1000.0;
}

/// Reference words for [text], one per [tokenizeWordSpans] span.
///
/// Spans are the authoritative orthography: eSpeak word events only
/// contribute timing (mapped back onto spans by [mapWordEventsToTokenSpans]),
/// so swallowed words, numeral expansions, and hyphenated compounds can
/// never change the displayed word sequence (issue #621).
///
/// Tokens tile the audio from the first event to [duration]; leading
/// silence stays unclaimed. A token owning events keeps the audio up to
/// the next owned event; tokens without an event share the surrounding
/// region proportionally by length so every source word stays visible with
/// a usable window. Phones attach by audio time within the token's span.
@internal
List<ReferenceWord> buildReferenceWords({
  required String text,
  required double duration,
  required List<EspeakWordEvent> wordEvents,
  required List<EspeakPhoneEvent> phoneEvents,
  bool requireWordEvents = true,
}) {
  final spans = tokenizeWordSpans(text);
  if (spans.isEmpty) return const [];
  final words = [...wordEvents]..sort((a, b) => a.audioMs.compareTo(b.audioMs));
  final phones = [...phoneEvents]
    ..sort((a, b) => a.audioMs.compareTo(b.audioMs));
  final codePointTable = codePointOffsetTable(text);
  if (words.isEmpty) {
    if (requireWordEvents) {
      throw const SpokenReferenceException(
        message: 'eSpeak-NG produced PCM but no word events',
      );
    }
    return _wordsFromTokenSpans(spans, phones, duration, codePointTable);
  }

  final owners = mapWordEventsToTokenSpans(spans, [
    for (final event in words)
      utf16Offset(codePointTable, event.textPosition - 1),
  ]);

  final firstEvent = List<int?>.filled(spans.length, null);
  for (var k = 0; k < owners.length; k++) {
    firstEvent[owners[k]] ??= k;
  }
  final claimed = <int>[
    for (var t = 0; t < spans.length; t++)
      if (firstEvent[t] != null) t,
  ];
  final eventStartSec = <double>[
    for (final event in words)
      math.max(0.0, math.min(duration, event.audioMs / 1000.0)),
  ];

  final starts = List<double>.filled(spans.length, 0);
  final ends = List<double>.filled(spans.length, 0);
  _distributeRegion(
    spans,
    starts,
    ends,
    0,
    claimed.first,
    0,
    eventStartSec[firstEvent[claimed.first]!],
  );
  for (var g = 0; g < claimed.length; g++) {
    final token = claimed[g];
    final regionEnd = g + 1 < claimed.length
        ? eventStartSec[firstEvent[claimed[g + 1]]!]
        : duration;
    _distributeRegion(
      spans,
      starts,
      ends,
      token,
      g + 1 < claimed.length ? claimed[g + 1] : spans.length,
      eventStartSec[firstEvent[token]!],
      regionEnd,
    );
  }

  final phonesByToken = _phonesByToken(phones, starts, ends);
  return [
    for (var t = 0; t < spans.length; t++)
      ReferenceWord(
        text: spans[t].text,
        startTime: starts[t],
        endTime: ends[t],
        phones: _phonesForSpan(phonesByToken[t], starts[t], ends[t], t),
      ),
  ];
}

/// Assign tokens `[startToken, endToken)` a share of
/// `[regionStart, regionEnd)`.
///
/// A lone token keeps the whole region (the previous
/// word-end = next-event-start convention); a run of event-less tokens
/// shares it proportionally by token length. An inverted region (events
/// reporting non-monotonic audio positions) collapses to zero width
/// instead of producing a token that ends before it starts.
void _distributeRegion(
  List<WordSpan> spans,
  List<double> starts,
  List<double> ends,
  int startToken,
  int endToken,
  double regionStart,
  double regionEnd,
) {
  if (endToken <= startToken) return;
  if (regionEnd < regionStart) regionEnd = regionStart;
  if (endToken - startToken == 1) {
    starts[startToken] = regionStart;
    ends[startToken] = regionEnd;
    return;
  }
  final totalLength = regionEnd - regionStart;
  final weights = [
    for (var t = startToken; t < endToken; t++) spans[t].text.length,
  ];
  final weightSum = weights.fold<int>(0, (a, b) => a + b);
  var cursor = regionStart;
  for (var t = startToken; t < endToken; t++) {
    final share = weightSum <= 0
        ? totalLength / (endToken - startToken)
        : totalLength * weights[t - startToken] / weightSum;
    starts[t] = cursor;
    cursor += share;
    ends[t] = t + 1 == endToken ? regionEnd : cursor;
  }
}

/// Chronological phone marks bucketed by the token whose span contains them.
List<List<EspeakPhoneEvent>> _phonesByToken(
  List<EspeakPhoneEvent> phoneEvents,
  List<double> starts,
  List<double> ends,
) {
  final buckets = List<List<EspeakPhoneEvent>>.generate(
    starts.length,
    (_) => <EspeakPhoneEvent>[],
  );
  if (buckets.isEmpty) return buckets;
  var cursor = 0;
  for (final event in phoneEvents) {
    final time = event.audioMs / 1000.0;
    while (cursor + 1 < buckets.length && time >= ends[cursor]) {
      cursor++;
    }
    buckets[cursor].add(event);
  }
  return buckets;
}

/// Phone spans for one token, preserving the previous shape: the first
/// phone reaches the token end and each mark closes the previous one.
/// Bounds use min/max rather than [double.clamp], which throws when a
/// caller's end precedes its start.
List<ReferencePhone> _phonesForSpan(
  List<EspeakPhoneEvent> events,
  double start,
  double end,
  int wordIndex,
) {
  final phones = <ReferencePhone>[];
  for (final event in events) {
    final t = math.min(end, math.max(start, event.audioMs / 1000.0));
    final pe = phones.isEmpty ? end : math.min(end, t + 0.02);
    if (phones.isNotEmpty) {
      final prev = phones.removeLast();
      phones.add(
        ReferencePhone(
          phone: prev.phone,
          startTime: prev.startTime,
          endTime: math.min(end, math.max(prev.startTime, t)),
          wordIndex: wordIndex,
        ),
      );
    }
    phones.add(
      ReferencePhone(
        phone: event.phone,
        startTime: t,
        endTime: pe,
        wordIndex: wordIndex,
      ),
    );
  }
  return phones;
}

/// IPA-only fallback when eSpeak emitted phones but no WORD events.
/// Maps phone text positions with the same rule as the word-event path so
/// both paths agree for identical text.
List<ReferenceWord> _wordsFromTokenSpans(
  List<WordSpan> spans,
  List<EspeakPhoneEvent> phoneEvents,
  double duration,
  List<int>? codePointTable,
) {
  if (spans.isEmpty) return const [];
  final phonesByWord = List<List<String>>.generate(
    spans.length,
    (_) => <String>[],
  );
  final owners = mapWordEventsToTokenSpans(spans, [
    for (final phone in phoneEvents)
      utf16Offset(codePointTable, phone.textPosition - 1),
  ]);
  for (var i = 0; i < phoneEvents.length; i++) {
    if (phoneEvents[i].phone.isNotEmpty) {
      phonesByWord[owners[i]].add(phoneEvents[i].phone);
    }
  }
  return [
    for (var i = 0; i < spans.length; i++)
      ReferenceWord(
        text: spans[i].text,
        startTime: 0,
        endTime: duration,
        phones: [
          for (var p = 0; p < phonesByWord[i].length; p++)
            ReferencePhone(
              phone: phonesByWord[i][p],
              startTime: 0,
              endTime: duration,
              wordIndex: i,
            ),
        ],
      ),
  ];
}
