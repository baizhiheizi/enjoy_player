import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/l10n_delegates.dart';

void main() {
  testWidgets(
    'VoicePicker does not assert when selectedVoice is for another language',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VoicePicker(
              language: 'en-US',
              selectedVoice: 'zh-CN-XiaoxiaoNeural',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    },
  );
}
