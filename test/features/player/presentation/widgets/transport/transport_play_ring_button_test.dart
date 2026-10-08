import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_play_ring_button.dart';

import '../../../../../helpers/chrome_icon_finders.dart';

Widget _host(Widget child, [Brightness brightness = Brightness.dark]) =>
    MaterialApp(
      theme: buildAppTheme(brightness),
      home: Scaffold(body: Center(child: child)),
    );

AnimatedContainer _litFillContainer(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(TransportPlayRingButton),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is AnimatedContainer &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).shape is CircleBorder,
            ),
          )
          .first,
    );

void main() {
  testWidgets('paints the flat brand gradient behind the play glyph', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        _host(
          const TransportPlayRingButton(
            playing: false,
            buffering: false,
            tooltip: 'Play',
            onPressed: null,
          ),
          brightness,
        ),
      );
      await tester.pumpAndSettle();

      expect(findChromeIcon(EnjoyChromeGlyph.play), findsOneWidget);

      final decoration =
          _litFillContainer(tester).decoration as ShapeDecoration;
      expect(decoration.shape, isA<CircleBorder>());
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, [AppColors.brandStart, AppColors.brandEnd]);
      expect(
        decoration.shadows,
        EnjoyThemeTokens.build(
          ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
        ).shadowBrandButton,
      );
    }
  });

  testWidgets('taps ride EnjoyPressable and fire onPressed once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TransportPlayRingButton(
          playing: true,
          buffering: false,
          tooltip: 'Pause',
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(findChromeIcon(EnjoyChromeGlyph.pause), findsOneWidget);
    final pressable = tester.widget<EnjoyPressable>(
      find.byType(EnjoyPressable),
    );
    expect(pressable.onTap, isNotNull);
    expect(pressable.pressedScale, 0.94);
    expect(pressable.haptic, isFalse);

    await tester.tap(find.byType(TransportPlayRingButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('null onPressed leaves the control inert', (tester) async {
    await tester.pumpWidget(
      _host(
        const TransportPlayRingButton(
          playing: false,
          buffering: false,
          tooltip: 'Play',
          onPressed: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<EnjoyPressable>(find.byType(EnjoyPressable)).onTap,
      isNull,
    );
    await tester.tap(find.byType(TransportPlayRingButton));
    await tester.pumpAndSettle();
  });

  testWidgets('buffering replaces the glyph with a spinner', (tester) async {
    await tester.pumpWidget(
      _host(
        const TransportPlayRingButton(
          playing: false,
          buffering: true,
          tooltip: 'Loading',
          onPressed: null,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(EnjoyChromeIcon), findsNothing);
  });
}
