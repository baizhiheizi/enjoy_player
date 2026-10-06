import 'dart:convert';
import 'dart:io';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/domain/practice_resume.dart';
import 'package:enjoy_player/features/library/presentation/continue_practice_card.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _png1x1Base64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Media _mediaWithThumbnail(String thumbnailPath) {
  final ts = DateTime.utc(2026, 10, 1);
  return Media(
    id: 'm1',
    kind: MediaKind.video,
    title: 'A quite long practice title for the hero card layout',
    sourceUri: 'file:///m1',
    durationMs: 1900000,
    language: 'en-US',
    contentHash: 'm1',
    fileSize: 1,
    createdAt: ts,
    updatedAt: ts,
    provider: 'local',
    thumbnailPath: thumbnailPath,
  );
}

Future<void> _pumpHero(WidgetTester tester, File thumbnail) async {
  final media = _mediaWithThumbnail(thumbnail.path);
  final resume = PracticeResume(
    media: media,
    positionMs: 42000,
    echoActive: false,
    lastActiveAt: DateTime.utc(2026, 10, 1),
    sessionId: 's1',
  );
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transcriptLinesForMediaProvider(
          media.id,
        ).overrideWith((ref) => Stream.value(const <TranscriptLine>[])),
        localThumbnailFileProvider(
          localThumbnailPathForMedia(media),
        ).overrideWith((ref) async => thumbnail),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: SizedBox(
            width: 700,
            child: IntrinsicHeight(child: ContinuePracticeCard(resume: resume)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('hero_thumb');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  testWidgets('thumbnail images never carry infinite layout sizes', (
    tester,
  ) async {
    final thumbnail = File('${tmp.path}/thumb.png');
    thumbnail.writeAsBytesSync(base64Decode(_png1x1Base64), flush: true);
    await _pumpHero(tester, thumbnail);

    final images = tester.widgetList<Image>(
      find.byType(Image, skipOffstage: false),
    );
    expect(images, isNotEmpty);
    for (final image in images) {
      expect(image.width, isNot(double.infinity));
      expect(image.height, isNot(double.infinity));
    }
  });

  testWidgets('hero under IntrinsicHeight mounts exception-free', (
    tester,
  ) async {
    final thumbnail = File('${tmp.path}/thumb.png');
    thumbnail.writeAsBytesSync(base64Decode(_png1x1Base64), flush: true);
    await _pumpHero(tester, thumbnail);

    expect(tester.takeException(), isNull);
    final box = tester.renderObject<RenderBox>(
      find.byType(ContinuePracticeCard),
    );
    expect(box.size.height.isFinite, isTrue);
    expect(box.size.height, greaterThanOrEqualTo(230));
    expect(find.byType(MediaCardThumbnail), findsOneWidget);
  });
}
