import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_language_picker_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required String source,
  required String target,
  String? learningTag,
  ValueChanged<String>? onSourceChanged,
  ValueChanged<String>? onTargetChanged,
  VoidCallback? onSwap,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: LookupLanguagePickerRow(
        sourceLanguage: source,
        targetLanguage: target,
        learningTag: learningTag,
        onSourceChanged: onSourceChanged ?? (_) {},
        onTargetChanged: onTargetChanged ?? (_) {},
        onSwap: onSwap ?? () {},
      ),
    ),
  );
}

void main() {
  group('LookupLanguagePickerRow', () {
    testWidgets('renders the lookup-catalog source and target labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(source: 'ko-KR', target: 'ja-JP', learningTag: 'en-US'),
      );
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
    });

    testWidgets('tap target pill opens the lookup-catalog option sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      String? captured;
      await tester.pumpWidget(
        _harness(
          source: 'ko-KR',
          target: 'en-US',
          learningTag: 'en-US',
          onTargetChanged: (v) => captured = v,
        ),
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      final representativeLabels = <String>[
        'Deutsch',
        'Italiano',
        'Português (Brasil)',
        'Русский',
      ];
      for (final label in representativeLabels) {
        expect(
          find.text(label),
          findsAtLeast(1),
          reason: 'expected $label in target option sheet',
        );
      }

      await tester.tap(find.text('日本語'));
      await tester.pumpAndSettle();
      expect(captured, 'ja-JP');
    });

    testWidgets('swap control is enabled when source != target', (
      tester,
    ) async {
      var swapped = 0;
      await tester.pumpWidget(
        _harness(
          source: 'ko-KR',
          target: 'ja-JP',
          learningTag: 'en-US',
          onSwap: () => swapped++,
        ),
      );
      final swapIcon = find.byIcon(EnjoyIcons.swap);
      expect(swapIcon, findsOneWidget);
      await tester.tap(swapIcon);
      await tester.pumpAndSettle();
      expect(swapped, 1);
    });

    testWidgets('swap control is disabled when source == target', (
      tester,
    ) async {
      var swapped = 0;
      await tester.pumpWidget(
        _harness(
          source: 'ko-KR',
          target: 'ko-KR',
          learningTag: 'en-US',
          onSwap: () => swapped++,
        ),
      );
      final swapIcon = find.byIcon(EnjoyIcons.swap);
      expect(swapIcon, findsOneWidget);
      await tester.tap(swapIcon);
      await tester.pumpAndSettle();
      expect(swapped, 0, reason: 'disabled swap should not fire');
    });

    testWidgets('source pill auto-resets target when the same is chosen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      String? source;
      await tester.pumpWidget(
        _harness(
          source: 'en-US',
          target: 'ko-KR',
          learningTag: 'en-US',
          onSourceChanged: (v) => source = v,
          onTargetChanged: (v) {},
        ),
      );
      await tester.tap(find.byTooltip('Swap languages'));
      await tester.pumpAndSettle();
      expect(source, isNull);
    });

    testWidgets(
      'source pill does not change target when a non-target is chosen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        var swapped = 0;
        await tester.pumpWidget(
          _harness(
            source: 'en-US',
            target: 'ko-KR',
            learningTag: 'en-US',
            onSwap: () => swapped++,
          ),
        );
        await tester.tap(find.byTooltip('Swap languages'));
        await tester.pumpAndSettle();
        expect(swapped, 1);
      },
    );
  });
}
