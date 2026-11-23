import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/llm_byok_form.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LlmByokForm shows base URL field for all protocol specs', (
    tester,
  ) async {
    final baseUrl = TextEditingController();
    final apiKey = TextEditingController();
    final model = TextEditingController();

    Future<void> pumpForm(LlmApiSpec spec) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LlmByokForm(
              apiSpec: spec,
              baseUrlController: baseUrl,
              apiKeyController: apiKey,
              modelController: model,
              hasExistingKey: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final spec in LlmApiSpec.values) {
      await pumpForm(spec);
      expect(find.byKey(const Key('llm_byok_base_url')), findsOneWidget);
    }
  });
}
