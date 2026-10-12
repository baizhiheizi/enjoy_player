import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../helpers/transcript_settings_overrides.dart';

class _BlurOff extends TranscriptBlurMode {
  @override
  bool build() => false;
}

const _line = TranscriptLine(
  text: 'Hello world',
  startMs: 5000,
  durationMs: 2000,
);

Future<void> _pumpDesktopTile(
  WidgetTester tester, {
  bool isActive = false,
  int? recordingCount,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptBlurModeProvider.overrideWith(_BlurOff.new),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 600,
                child: TranscriptLineTile(
                  line: _line,
                  mediaId: 'test',
                  secondaryText: null,
                  isActive: isActive,
                  inEcho: false,
                  recordingCount: recordingCount,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

double _baselineY(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  RenderObject.debugCheckingIntrinsics = true;
  try {
    return box.localToGlobal(Offset.zero).dy +
        box.getDistanceToBaseline(TextBaseline.alphabetic)!;
  } finally {
    RenderObject.debugCheckingIntrinsics = false;
  }
}

void main() {
  for (final isActive in [false, true]) {
    testWidgets('gutter time shares the first line baseline '
        '(active: $isActive)', (tester) async {
      await _pumpDesktopTile(tester, isActive: isActive);

      expect(
        _baselineY(tester, find.text('0:05')),
        moreOrLessEquals(
          _baselineY(tester, find.text('Hello world')),
          epsilon: 0.01,
        ),
      );
    });
  }

  testWidgets('practiced dot does not grow a single-line row', (tester) async {
    await _pumpDesktopTile(tester);
    final plain = tester.getSize(find.byType(TranscriptLineTile)).height;

    await _pumpDesktopTile(tester, recordingCount: 2);
    final practiced = tester.getSize(find.byType(TranscriptLineTile)).height;

    expect(practiced, plain);
  });
}
