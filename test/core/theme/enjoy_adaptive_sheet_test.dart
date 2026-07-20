import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(double width) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Builder(
          builder: (context) {
            final compact = enjoyUseCompactSheet(context);
            return Scaffold(body: Text(compact ? 'compact' : 'wide'));
          },
        ),
      ),
    );
  }

  testWidgets('uses compact sheet under breakpoint', (tester) async {
    await tester.pumpWidget(wrap(390));
    expect(find.text('compact'), findsOneWidget);
  });

  testWidgets('uses wide centered sheet at/above breakpoint', (tester) async {
    await tester.pumpWidget(wrap(900));
    expect(find.text('wide'), findsOneWidget);
  });
}
