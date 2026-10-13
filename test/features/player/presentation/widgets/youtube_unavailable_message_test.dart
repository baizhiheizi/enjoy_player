import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_unavailable_message.dart';
import 'package:enjoy_player/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('codecsMissing names the GStreamer packages to install', () {
    final message = youtubeUnavailableMessage(
      l10n,
      YouTubeUnavailableReason.codecsMissing,
    );

    expect(message, l10n.youtubeUnavailableCodecsMissing);
    expect(message, contains('gst-plugins-good'));
    expect(message, contains('gst-libav'));
  });

  test('every reason maps to a distinct message', () {
    final messages = {
      for (final reason in YouTubeUnavailableReason.values)
        youtubeUnavailableMessage(l10n, reason),
      youtubeUnavailableMessage(l10n, null),
    };

    expect(messages, hasLength(YouTubeUnavailableReason.values.length + 1));
  });
}
