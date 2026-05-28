import 'package:enjoy_player/features/discover/data/youtube_video_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubeVideoDuration', () {
    test('parseSecondsFromHtml reads lengthSeconds', () {
      const html = r'{"lengthSeconds":"754","title":"Talk"}';
      expect(YoutubeVideoDuration.parseSecondsFromHtml(html), 754);
    });

    test('parseSecondsFromHtml falls back to approxDurationMs', () {
      const html = r'{"approxDurationMs":"125000"}';
      expect(YoutubeVideoDuration.parseSecondsFromHtml(html), 125);
    });

    test('parseSecondsFromHtml returns null when missing', () {
      expect(YoutubeVideoDuration.parseSecondsFromHtml('{}'), isNull);
    });
  });
}
