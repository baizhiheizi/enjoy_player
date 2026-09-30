import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/lookup_markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _testTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: Typography.material2021(
      platform: TargetPlatform.android,
    ).white.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    extensions: [EnjoyThemeTokens.build(scheme)],
  );
}

void main() {
  testWidgets('lookup markdown blockquote uses dark surface, not light blue', (
    tester,
  ) async {
    final theme = _testTheme();
    final tokens = theme.extension<EnjoyThemeTokens>()!;

    late MarkdownStyleSheet sheet;
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            ctx = context;
            sheet = buildLookupMarkdownStyleSheet(context, tokens);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final blockquote = sheet.blockquoteDecoration! as BoxDecoration;

    expect(blockquote.color, Theme.of(ctx).colorScheme.surfaceContainerHigh);
    expect(blockquote.color, isNot(Colors.blue.shade100));
  });
}
