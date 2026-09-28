import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';

void main() {
  testWidgets('renders the Aurora glyph for a chrome glyph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: const Scaffold(
          body: Center(child: EnjoyChromeIcon(EnjoyChromeGlyph.home)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(EnjoyChromeGlyph.home.icon), findsOneWidget);
  });

  testWidgets('filled renders the filled variant', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: const Scaffold(
          body: Center(
            child: EnjoyChromeIcon(EnjoyChromeGlyph.home, filled: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(EnjoyChromeGlyph.home.filledIcon), findsOneWidget);
    expect(EnjoyChromeGlyph.home.filledIcon, isNot(EnjoyChromeGlyph.home.icon));
  });
}
