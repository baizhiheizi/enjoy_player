import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'VoicePicker does not assert when selectedVoice is for another language',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VoicePicker(
              language: 'en-US',
              // Chinese voice id while language is English — previously
              // crashed DropdownButton with a value-not-in-items assertion.
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
