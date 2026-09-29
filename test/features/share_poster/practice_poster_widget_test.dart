import 'dart:io';

import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = PracticePosterLabels(
  tagline: 'Shadow reading',
  takesLabel: 'Takes',
  sentencesLabel: 'Sentences',
  spokenLabel: 'Spoken',
  qrHint: 'Scan to download',
);

const _data = PracticePosterData(
  title: 'Sample lesson',
  coverSeed: 'seed-abc',
  isVideo: true,
  takes: 5,
  sentencesPracticed: 2,
  spokenDurationMs: 125000,
);

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('PracticePosterWidget renders stats and quote', (tester) async {
    const data = PracticePosterData(
      title: 'Sample lesson',
      coverSeed: 'seed-abc',
      isVideo: true,
      quote: PracticePosterQuote(
        line: PracticePosterQuoteLine(
          text:
              'so I could get away from the buzzing and focus on the speech patterns',
          trailingEllipsis: true,
        ),
      ),
      takes: 5,
      sentencesPracticed: 2,
      spokenDurationMs: 125000,
    );

    await tester.binding.setSurfaceSize(const Size(400, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(const PracticePosterWidget(data: data, labels: _labels)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample lesson'), findsOneWidget);
    expect(find.textContaining('so I could get away'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2m 5s'), findsOneWidget);
  });

  testWidgets(
    'cover renders an existing local thumbnail file after the async resolve',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('poster_cover_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final thumb = File('${dir.path}/thumb.jpg')..writeAsBytesSync([1, 2, 3]);

      var ready = false;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            height: 180,
            child: PracticePosterCover(
              data: _data.copyWithLocalThumbnailPath(thumb.path),
              onCoverReady: () => ready = true,
            ),
          ),
        ),
      );
      await tester
          .runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          )
          .then((_) => tester.pump());
      await tester.pump();

      final image = tester.widget<Image>(
        find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
      );
      expect((image.image as FileImage).file.path, thumb.path);
      expect(ready, isTrue);
    },
  );

  testWidgets(
    'cover falls back to generative art for a missing local thumbnail '
    'without a synchronous stat in build',
    (tester) async {
      var ready = false;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            height: 180,
            child: PracticePosterCover(
              data: _data.copyWithLocalThumbnailPath(
                '${Directory.systemTemp.path}/no-such-poster-thumb.jpg',
              ),
              onCoverReady: () => ready = true,
            ),
          ),
        ),
      );
      await tester
          .runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          )
          .then((_) => tester.pump());
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
        findsNothing,
      );
      expect(ready, isTrue);
    },
  );
}

extension on PracticePosterData {
  PracticePosterData copyWithLocalThumbnailPath(String path) {
    return PracticePosterData(
      title: title,
      coverSeed: coverSeed,
      isVideo: isVideo,
      echoCoverBytes: echoCoverBytes,
      localThumbnailPath: path,
      networkThumbnailUrl: networkThumbnailUrl,
      quote: quote,
      takes: takes,
      sentencesPracticed: sentencesPracticed,
      spokenDurationMs: spokenDurationMs,
    );
  }
}
