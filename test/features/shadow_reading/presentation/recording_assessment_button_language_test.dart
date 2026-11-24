import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
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

class _NoHotkeysCtrl extends HotkeysCtrl {
  @override
  Future<Map<String, String>> build() async => const {};
}

RecordingRow _unplayableTake(String language) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: 'r1',
    targetType: 'Audio',
    targetId: 'm1',
    referenceStart: 0,
    referenceDuration: 5000,
    referenceText: 'Hi',
    language: language,
    duration: 1000,
    md5: null,
    audioUrl: null,
    pronunciationScore: null,
    assessmentJson: null,
    localPath: null,
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

Future<AppLocalizations> _pumpButton(
  WidgetTester tester,
  String language,
) async {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1144AA));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesCtrlProvider.overrideWith(_EnLearningPrefsCtrl.new),
        hotkeysCtrlProvider.overrideWith(_NoHotkeysCtrl.new),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: RecordingAssessmentButton(
              row: _unplayableTake(language),
              echoActive: true,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}

EnjoyPressable _pressable(WidgetTester tester) => tester.widget<EnjoyPressable>(
  find.descendant(
    of: find.byType(RecordingAssessmentButton),
    matching: find.byType(EnjoyPressable),
  ),
);

void main() {
  testWidgets(
    'an unsupported language explains itself even when the take is unplayable',
    (tester) async {
      final l10n = await _pumpButton(tester, 'tlh');

      expect(
        find.byTooltip(l10n.assessmentUnavailableLanguage),
        findsOneWidget,
      );
      expect(_pressable(tester).onTap, isNull);
    },
  );

  testWidgets(
    'an unplayable take in a supported language keeps the assessment tooltip',
    (tester) async {
      final l10n = await _pumpButton(tester, 'en');

      expect(find.byTooltip(l10n.assessmentUnavailableLanguage), findsNothing);
      expect(find.byTooltip(l10n.assessmentRun), findsOneWidget);
      expect(_pressable(tester).onTap, isNull);
    },
  );
}
