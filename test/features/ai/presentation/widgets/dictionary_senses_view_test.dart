import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/presentation/widgets/dictionary_senses_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _result = DictionaryResult(
  word: 'run',
  sourceLanguage: 'en',
  targetLanguage: 'zh',
  lemma: 'to run',
  ipa: 'rʌn',
  senses: [
    DictionarySense(
      definition: 'move faster than walking',
      translation: '跑步',
      partOfSpeech: 'verb',
      examples: [DictionaryExample(source: 'I run daily.', target: '我每天跑步。')],
      notes: 'Common verb.',
    ),
    DictionarySense(definition: 'a period of time', translation: '运行'),
  ],
);

void main() {
  testWidgets('formats IPA with one slash pair and prefixes the lemma label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const DictionarySensesView(result: _result, lemmaLabel: 'Lemma')),
    );

    expect(find.text('/rʌn/'), findsOneWidget);
    expect(find.text('Lemma · to run'), findsOneWidget);
    expect(find.text('move faster than walking'), findsOneWidget);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('I run daily.'), findsOneWidget);
    expect(find.text('我每天跑步。'), findsOneWidget);
    expect(find.text('Common verb.'), findsOneWidget);
    expect(find.text('a period of time'), findsOneWidget);
    expect(find.byType(DictionarySenseTile), findsNWidgets(2));
  });

  testWidgets('renders the bare lemma when no label is given', (tester) async {
    await tester.pumpWidget(_wrap(const DictionarySensesView(result: _result)));

    expect(find.text('to run'), findsOneWidget);
    expect(find.textContaining('Lemma ·'), findsNothing);
  });

  testWidgets('hides the lemma when it equals the headword', (tester) async {
    const result = DictionaryResult(
      word: 'run',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
      lemma: 'run',
      ipa: '/rʌn/',
      senses: [DictionarySense(definition: 'move fast')],
    );
    await tester.pumpWidget(_wrap(const DictionarySensesView(result: result)));

    expect(find.text('run'), findsNothing);
    expect(find.text('/rʌn/'), findsOneWidget);
  });

  testWidgets('pins the canonical sense typography', (tester) async {
    await tester.pumpWidget(_wrap(const DictionarySensesView(result: _result)));

    final definition = tester.widget<SelectableText>(
      find.ancestor(
        of: find.text('move faster than walking'),
        matching: find.byType(SelectableText),
      ),
    );
    expect(definition.style?.height, 1.45);

    final source = tester.widget<SelectableText>(
      find.ancestor(
        of: find.text('I run daily.'),
        matching: find.byType(SelectableText),
      ),
    );
    expect(source.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('renders no sense tiles for an empty senses list', (
    tester,
  ) async {
    const result = DictionaryResult(
      word: 'run',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
      ipa: 'rʌn',
      senses: [],
    );
    await tester.pumpWidget(_wrap(const DictionarySensesView(result: result)));

    expect(find.byType(DictionarySenseTile), findsNothing);
    expect(find.text('/rʌn/'), findsOneWidget);
  });
}
