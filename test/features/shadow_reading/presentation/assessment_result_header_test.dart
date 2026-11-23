import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_dialog.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_header.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../helpers/assessment_result_harness.dart';

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

  testWidgets('the dialog and the sheet mount the same header', (tester) async {
    await tester.pumpWidget(
      wrapAssessmentHarness(
        AssessmentResultDialog(
          assessment: parseAssessmentResult(kAssessmentResultJson),
          localeTag: 'en-US',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultHeader), findsOneWidget);
    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentDescription), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);

    await tester.pumpWidget(
      wrapAssessmentHarness(
        AssessmentResultSheet(
          assessment: parseAssessmentResult(kAssessmentResultJson),
          localeTag: 'en-US',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultHeader), findsOneWidget);
    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentDescription), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
  });

  testWidgets('the close affordance is 48x48 on both surfaces', (tester) async {
    for (final child in <Widget>[
      AssessmentResultDialog(
        assessment: parseAssessmentResult(kAssessmentResultJson),
        localeTag: 'en-US',
      ),
      AssessmentResultSheet(
        assessment: parseAssessmentResult(kAssessmentResultJson),
        localeTag: 'en-US',
      ),
    ]) {
      await tester.pumpWidget(wrapAssessmentHarness(child));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(
          find.ancestor(
            of: find.byIcon(EnjoyIcons.close),
            matching: find.byType(IconButton),
          ),
        ),
        const Size(48, 48),
      );
    }
  });
}
