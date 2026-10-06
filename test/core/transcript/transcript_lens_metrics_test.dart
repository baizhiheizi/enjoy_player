import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _desktop = TranscriptLensMetrics.forSurface(
  TranscriptLensSurface.desktop,
);
const _video = TranscriptLensMetrics.forSurface(TranscriptLensSurface.video);
const _phone = TranscriptLensMetrics.forSurface(TranscriptLensSurface.phone);

void main() {
  test('Listen line sizes follow the Main and Phone boards', () {
    expect(_desktop.lineFontSize(active: true), 21);
    expect(_desktop.lineFontSize(active: false), 17);
    expect(_video.lineFontSize(active: true), 17);
    expect(_video.lineFontSize(active: false), 15);
    expect(_phone.lineFontSize(active: true), 20);
    expect(_phone.lineFontSize(active: false), 16);
    expect(_desktop.secondaryFontSize(active: true), 14.5);
    expect(_phone.secondaryFontSize(active: false), 12.5);
  });

  test('gutter is 44 on desktop, 36 in the video column, a dot on phones', () {
    expect(_desktop.gutterWidth, 44);
    expect(_video.gutterWidth, 36);
    expect(_phone.gutterWidth, 8);
    expect(_desktop.timeInGutter, isTrue);
    expect(_phone.timeInGutter, isFalse);
  });

  test('loop font clamps with the window on desktop only', () {
    expect(_desktop.loopFontSize(1, mediaWidth: 800), 22);
    expect(_desktop.loopFontSize(1, mediaWidth: 1300), 26);
    expect(_desktop.loopFontSize(1, mediaWidth: 2000), 28);
    expect(_desktop.loopFontSize(2, mediaWidth: 2000), 24);
    expect(_desktop.loopFontSize(3, mediaWidth: 2000), 19);
    expect(_video.loopFontSize(1, mediaWidth: 2000), 20);
    expect(_video.loopFontSize(2, mediaWidth: 2000), 18);
    expect(_phone.loopFontSize(1, mediaWidth: 390), 23);
    expect(_phone.loopFontSize(3, mediaWidth: 390), 20);
  });

  test('takes strip aligns with the loop text column on desktop', () {
    expect(_desktop.takesLeftInset, 66);
    expect(_video.takesLeftInset, 0);
    expect(_phone.takesLeftInset, 0);
  });

  testWidgets('video column scope selects the video surface', (tester) async {
    late TranscriptLensMetrics inside;
    late TranscriptLensMetrics outside;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              outside = TranscriptLensMetrics.of(context);
              return const SizedBox();
            },
          ),
          TranscriptVideoColumnScope(
            child: Builder(
              builder: (context) {
                inside = TranscriptLensMetrics.of(context);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(inside.isVideo, isTrue);
    expect(outside.isVideo, isFalse);
  });
}
