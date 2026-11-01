import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_filter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<EnjoyThemeTokens> _pump(WidgetTester tester, Widget child) async {
  final theme = buildAppTheme(Brightness.light);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  return theme.extension<EnjoyThemeTokens>()!;
}

Container _pillPlate(WidgetTester tester) => tester.widget<Container>(
  find.byWidgetPredicate(
    (w) => w is Container && w.decoration is ShapeDecoration,
  ),
);

void main() {
  group('EnjoyFilterPill', () {
    testWidgets('renders the label on a paper plate with a line border', (
      tester,
    ) async {
      final t = await _pump(
        tester,
        const EnjoyFilterPill(label: 'Start date', onTap: _noop),
      );

      final box = _pillPlate(tester);
      final decoration = box.decoration! as ShapeDecoration;
      expect(decoration.color, t.paper);
      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(shape.side, BorderSide(color: t.line));
      expect(shape.borderRadius, BorderRadius.circular(11));
      expect(tester.widget<Text>(find.byType(Text)).data, 'Start date');
    });

    testWidgets('is 38px tall with 12px horizontal padding by default', (
      tester,
    ) async {
      await _pump(
        tester,
        const EnjoyFilterPill(label: 'Start date', onTap: _noop),
      );

      expect(
        tester.getSize(find.byType(EnjoyFilterPill)).height,
        closeTo(38, 0.01),
      );
      expect(
        _pillPlate(tester).padding,
        const EdgeInsets.symmetric(horizontal: 12),
      );
    });

    testWidgets('honours a custom height', (tester) async {
      await _pump(
        tester,
        const EnjoyFilterPill(label: 'Start date', onTap: _noop, height: 36),
      );

      expect(
        tester.getSize(find.byType(EnjoyFilterPill)).height,
        closeTo(36, 0.01),
      );
    });

    testWidgets('shows the picked value in mono after the label', (
      tester,
    ) async {
      final t = await _pump(
        tester,
        const EnjoyFilterPill(
          label: 'Start date',
          value: '2026-09-24',
          onTap: _noop,
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.map((e) => e.data), ['Start date', '2026-09-24']);
      expect(texts.last.style?.fontFamily, isNotNull);
      expect(texts.last.style?.color, t.ink);
    });

    testWidgets('omits the value slot when no value is picked', (tester) async {
      await _pump(
        tester,
        const EnjoyFilterPill(label: 'Start date', onTap: _noop),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('labels in ink3 at the shared 13.5px label size', (
      tester,
    ) async {
      final t = await _pump(
        tester,
        const EnjoyFilterPill(label: 'Start date', onTap: _noop),
      );

      final style = tester.widget<Text>(find.byType(Text)).style;
      expect(style?.color, t.ink3);
      expect(style?.fontSize, 13.5);
    });
  });

  group('EnjoyFilterMenu', () {
    testWidgets('renders the label and the current entry', (tester) async {
      await _pump(
        tester,
        const EnjoyFilterMenu<String?>(
          label: 'Service',
          value: 'tts',
          entries: [(null, 'All'), ('tts', 'TTS')],
          onChanged: _ignore,
        ),
      );

      expect(find.text('Service  TTS'), findsOneWidget);
    });

    testWidgets('falls back to the first entry when the value is unknown', (
      tester,
    ) async {
      await _pump(
        tester,
        const EnjoyFilterMenu<String?>(
          label: 'Service',
          value: 'nope',
          entries: [(null, 'All'), ('tts', 'TTS')],
          onChanged: _ignore,
        ),
      );

      expect(find.text('Service  All'), findsOneWidget);
    });

    testWidgets('uses the caller formatter when one is given', (tester) async {
      await _pump(
        tester,
        EnjoyFilterMenu<String?>(
          label: 'Status',
          value: null,
          entries: const [(null, 'All')],
          formatLabel: (label, current) => '$label: $current',
          onChanged: _ignore,
        ),
      );

      expect(find.text('Status: All'), findsOneWidget);
    });

    testWidgets('renders the paper plate with the chevron', (tester) async {
      final t = await _pump(
        tester,
        const EnjoyFilterMenu<String?>(
          label: 'Service',
          value: null,
          entries: [(null, 'All')],
          onChanged: _ignore,
        ),
      );

      final box = _pillPlate(tester);
      final decoration = box.decoration! as ShapeDecoration;
      expect(decoration.color, t.paper);
      expect(
        (decoration.shape as RoundedSuperellipseBorder).side,
        BorderSide(color: t.line),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 14);
      expect(icon.color, t.ink3);
    });

    testWidgets('labels in ink2 at the shared 13.5px label size', (
      tester,
    ) async {
      final t = await _pump(
        tester,
        const EnjoyFilterMenu<String?>(
          label: 'Service',
          value: null,
          entries: [(null, 'All')],
          onChanged: _ignore,
        ),
      );

      final style = tester.widget<Text>(find.byType(Text)).style;
      expect(style?.color, t.ink2);
      expect(style?.fontSize, 13.5);
    });

    testWidgets('opens a menu with one entry per choice', (tester) async {
      await _pump(
        tester,
        const EnjoyFilterMenu<String?>(
          label: 'Service',
          value: null,
          entries: [(null, 'All'), ('tts', 'TTS')],
          onChanged: _ignore,
        ),
      );

      await tester.tap(find.text('Service  All'));
      await tester.pumpAndSettle();

      expect(find.text('TTS'), findsOneWidget);
    });

    testWidgets('reports the picked entry to the caller', (tester) async {
      String? picked;
      await _pump(
        tester,
        EnjoyFilterMenu<String?>(
          label: 'Service',
          value: null,
          entries: const [(null, 'All'), ('tts', 'TTS')],
          onChanged: (v) => picked = v,
        ),
      );

      await tester.tap(find.text('Service  All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TTS'));
      await tester.pumpAndSettle();

      expect(picked, 'tts');
    });
  });
}

void _noop() {}

void _ignore(Object? _) {}
