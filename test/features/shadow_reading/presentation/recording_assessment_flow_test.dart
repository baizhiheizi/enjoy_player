import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/l10n_delegates.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnLearningPrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async =>
      AppPreferencesState.initial.copyWith(learningLanguage: 'en-US');
}

RecordingRow _row(String assessmentJson) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: 'r1',
    targetType: 'Audio',
    targetId: 'm1',
    referenceStart: 0,
    referenceDuration: 5000,
    referenceText: 'Hi',
    language: 'en',
    duration: 1000,
    md5: null,
    audioUrl: null,
    pronunciationScore: null,
    assessmentJson: assessmentJson,
    localPath: '/tmp/fake.wav',
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

Future<AppLocalizations> _openStored(
  WidgetTester tester,
  String assessmentJson,
) async {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1144AA));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesCtrlProvider.overrideWith(_EnLearningPrefsCtrl.new),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => triggerRecordingAssessment(
                context: context,
                ref: ref,
                l10n: AppLocalizations.of(context)!,
                row: _row(assessmentJson),
              ),
              child: const Text('open stored'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(tester.element(find.text('open stored')))!;
  await tester.tap(find.text('open stored'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return l10n;
}

void main() {
  testWidgets('a malformed stored assessment reports the unreadable notice', (
    tester,
  ) async {
    final l10n = await _openStored(tester, '{"NBest":[tru');

    expect(find.text(l10n.assessmentInvalidStored), findsOneWidget);
  });

  testWidgets('a non-object stored payload reports the unreadable notice', (
    tester,
  ) async {
    final l10n = await _openStored(tester, '[1, 2]');

    expect(find.text(l10n.assessmentInvalidStored), findsOneWidget);
  });
}
