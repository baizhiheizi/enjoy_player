import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/sign_in_flow_scaffold.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SignInFlowScaffold(child: Text('form')),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('wide windows show the brand panel beside the form', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 800));

    expect(find.byType(SignInBrandPanel), findsOneWidget);
    expect(find.text('First the original voice. Then yours.'), findsOneWidget);
    expect(find.text('form'), findsOneWidget);
  });

  testWidgets('narrow windows show the form alone', (tester) async {
    await _pump(tester, const Size(400, 800));

    expect(find.byType(SignInBrandPanel), findsNothing);
    expect(find.text('form'), findsOneWidget);
  });
}
