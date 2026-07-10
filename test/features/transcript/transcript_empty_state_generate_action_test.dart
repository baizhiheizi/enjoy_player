import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/transcript/presentation/transcript_empty_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows Generate transcript CTA when enabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TranscriptEmptyState(
          onImport: () async {},
          onGenerate: () async {},
          showImportButton: true,
          showGenerateButton: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Generate transcript'), findsOneWidget);
    expect(find.text('Add subtitle'), findsOneWidget);
  });

  testWidgets('hides Generate CTA when showGenerateButton is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TranscriptEmptyState(
          onImport: () async {},
          showImportButton: true,
          showGenerateButton: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Generate transcript'), findsNothing);
    expect(find.text('Add subtitle'), findsOneWidget);
  });

  testWidgets('Generate CTA shows busy spinner while onGenerate runs', (
    tester,
  ) async {
    final completer = _ManualCompleter<void>();
    await tester.pumpWidget(
      _wrap(
        TranscriptEmptyState(
          onImport: () async {},
          onGenerate: () => completer.future,
          showImportButton: true,
          showGenerateButton: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate transcript'));
    await tester.pump(); // first rebuild → busy
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _ManualCompleter<T> {
  T? _value;
  bool _done = false;
  Future<T> get future {
    if (_done) return Future.value(_value as T);
    return Future(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return _value as T;
    });
  }

  void complete([T? value]) {
    _done = true;
    _value = value;
  }
}
