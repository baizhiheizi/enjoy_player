import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/dictionary_lookup_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _request = LookupRequest(
  selectedText: 'ferry',
  sourceLanguage: 'en',
  targetLanguage: 'zh',
  sourceContext: LookupSourceContext(
    isVideo: false,
    startMs: 20000,
    lineText: "You don't take the ferry to save time.",
  ),
);

Future<void> _pump(WidgetTester tester, LookupRequest request) async {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DictionaryLookupSheet(
            presentation: DictionaryLookupPresentation.dialog,
            request: request,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the line with the audio heading and a bold word', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _pump(tester, _request);

    expect(
      find.text(l10n.lookupInThisAudio('0:20').toUpperCase()),
      findsOneWidget,
    );
    final richTexts = tester.widgetList<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('lookup-source-context')),
        matching: find.byType(RichText),
      ),
    );
    final spans = richTexts
        .map((r) => r.text as TextSpan)
        .expand((root) => root.children ?? const <InlineSpan>[])
        .whereType<TextSpan>()
        .firstWhere((t) => (t.children?.length ?? 0) == 3)
        .children!;
    expect(spans.length, 3);
    expect(spans[1].style!.fontWeight, FontWeight.w700);
    expect((spans[1] as TextSpan).text, 'ferry');
  });

  testWidgets('video requests use the video heading', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _pump(
      tester,
      const LookupRequest(
        selectedText: 'ferry',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        sourceContext: LookupSourceContext(
          isVideo: true,
          startMs: 20000,
          lineText: 'You don’t take the ferry.',
        ),
      ),
    );

    expect(
      find.text(l10n.lookupInThisVideo('0:20').toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('the word is not bolded inside a longer word', (tester) async {
    await _pump(
      tester,
      const LookupRequest(
        selectedText: 'time',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        sourceContext: LookupSourceContext(
          isVideo: false,
          startMs: 20000,
          lineText: 'The timetable is on the wall.',
        ),
      ),
    );

    final richTexts = tester.widgetList<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('lookup-source-context')),
        matching: find.byType(RichText),
      ),
    );
    final spans = richTexts
        .map((r) => r.text as TextSpan)
        .expand((root) => root.children ?? const <InlineSpan>[])
        .whereType<TextSpan>()
        .toList();
    expect(
      spans.where((s) => s.style?.fontWeight == FontWeight.w700),
      isEmpty,
      reason: 'time inside timetable must not highlight',
    );
  });

  testWidgets('a missing word renders the plain line, no bold', (tester) async {
    await _pump(
      tester,
      const LookupRequest(
        selectedText: 'harbour',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        sourceContext: LookupSourceContext(
          isVideo: false,
          startMs: 20000,
          lineText: "You don't take the ferry.",
        ),
      ),
    );

    final richTexts = tester.widgetList<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('lookup-source-context')),
        matching: find.byType(RichText),
      ),
    );
    final bodies = richTexts
        .map((r) => (r.text as TextSpan))
        .expand((root) => root.children ?? const <InlineSpan>[])
        .whereType<TextSpan>()
        .toList();
    expect(bodies, hasLength(1));
    expect(bodies.single.style?.fontWeight, isNull);
  });

  testWidgets('no source context renders no block', (tester) async {
    await _pump(
      tester,
      const LookupRequest(
        selectedText: 'ferry',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
      ),
    );

    expect(find.byKey(const ValueKey('lookup-source-context')), findsNothing);
  });
}
