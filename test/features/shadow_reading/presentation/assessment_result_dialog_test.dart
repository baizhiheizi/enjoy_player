import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../helpers/assessment_result_harness.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/selected_word_panel.dart';

AssessmentResultDialog _dialog(String json) => AssessmentResultDialog(
  assessment: parseAssessmentResult(json),
  localeTag: 'en-US',
);

late final AppLocalizations l10n;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mediaKitError = initAssessmentMediaKit();
  if (mediaKitError != null) {
    test(
      '(skipped) media_kit native library not available',
      () {},
      skip: '$mediaKitError',
    );
    return;
  }

  setUpAll(() async {
    l10n = await loadAssessmentL10n();
  });

  testWidgets('AssessmentResultDialog renders title and overall score', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapAssessmentHarness(_dialog(kAssessmentResultJson)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultDialog), findsOneWidget);
    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentAccuracy), findsOneWidget);
    expect(find.text(l10n.assessmentCompleteness), findsOneWidget);
    expect(find.text(l10n.assessmentFluency), findsOneWidget);
    expect(find.text(l10n.assessmentProsody), findsOneWidget);
    expect(find.text('hi'), findsWidgets);
    expect(find.text('there'), findsWidgets);
    expect(find.text('friend'), findsWidgets);
  });

  testWidgets(
    'AssessmentResultDialog tap on a word tile toggles selection state',
    (tester) async {
      await tester.pumpWidget(
        wrapAssessmentHarness(_dialog(kAssessmentResultJson)),
      );
      await tester.pumpAndSettle();

      final initialHiCount = find.text('hi').evaluate().length;
      expect(initialHiCount, greaterThanOrEqualTo(1));

      await tester.tap(find.text('hi').first);
      await tester.pumpAndSettle();

      final selectedHiCount = find.text('hi').evaluate().length;
      expect(
        selectedHiCount,
        greaterThan(initialHiCount),
        reason: 'tapping a word chip should reveal the selected-word panel',
      );

      expect(find.byType(SelectedWordPanel), findsOneWidget);

      await tester.tap(find.text('hi').first);
      await tester.pumpAndSettle();

      final deselectedHiCount = find.text('hi').evaluate().length;
      expect(
        deselectedHiCount,
        initialHiCount,
        reason: 'second tap should hide the selected-word panel',
      );
      expect(find.byType(SelectedWordPanel), findsNothing);
    },
  );

  testWidgets(
    'AssessmentResultDialog shows the no-result fallback when nBest is empty',
    (tester) async {
      await tester.pumpWidget(
        wrapAssessmentHarness(_dialog(kAssessmentResultEmptyJson)),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.assessmentNoResultSummary), findsOneWidget);
    },
  );

  testWidgets(
    'showAssessmentResultDialog with empty nBest shows dismissible fallback',
    (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        wrapAssessmentHarness(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showAssessmentResultDialog(
                context: ctx,
                assessment: parseAssessmentResult(kAssessmentResultEmptyJson),
              ),
              child: const Text('open'),
            ),
          ),
          navigatorKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.assessmentTitle), findsOneWidget);
      expect(find.text(l10n.assessmentNoResultSummary), findsOneWidget);

      await tester.tap(
        find.text(
          MaterialLocalizations.of(navKey.currentContext!).okButtonLabel,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.assessmentNoResultSummary), findsNothing);
    },
  );

  testWidgets(
    'AssessmentResultDialog close button dismisses via Navigator.pop',
    (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        wrapAssessmentHarness(
          _dialog(kAssessmentResultJson),
          navigatorKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(EnjoyIcons.close).first);
      await tester.pumpAndSettle();

      expect(find.byType(AssessmentResultDialog), findsNothing);
    },
  );

  testWidgets('AssessmentResultDialog handles a result with empty word list', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapAssessmentHarness(_dialog(kAssessmentResultNoWordsJson)),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentAccuracy), findsOneWidget);
  });
}
