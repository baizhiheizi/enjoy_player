import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_header.dart';

Widget _host({required Widget child}) {
  return MaterialApp(
    theme: buildAppTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}

EnjoyThemeTokens _tokens() => EnjoyThemeTokens.build(
  ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
);

void main() {
  testWidgets('renders the drag handle above the title', (tester) async {
    await tester.pumpWidget(_host(child: const SheetHeader(title: 'Speed')));

    expect(find.text('Speed'), findsOneWidget);
    expect(find.byType(PaddedSheetDragHandle), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(PaddedSheetDragHandle)).dy,
      lessThan(tester.getTopLeft(find.text('Speed')).dy),
    );
  });

  testWidgets('medium style uses a w600 titleMedium', (tester) async {
    await tester.pumpWidget(_host(child: const SheetHeader(title: 'Speed')));

    final text = tester.widget<Text>(find.text('Speed'));
    final theme = buildAppTheme(Brightness.dark);
    expect(text.style?.fontSize, theme.textTheme.titleMedium?.fontSize);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('large style uses titleLarge', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const SheetHeader(
          title: 'Subscribe',
          style: SheetHeaderStyle.large,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Subscribe'));
    final theme = buildAppTheme(Brightness.dark);
    expect(text.style?.fontSize, theme.textTheme.titleLarge?.fontSize);
  });

  testWidgets('the subtitle renders under the title in a muted style', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: const SheetHeader(title: 'Contact', subtitle: 'Reach us here'),
      ),
    );

    expect(find.text('Reach us here'), findsOneWidget);
    final subtitle = tester.widget<Text>(find.text('Reach us here'));
    final theme = buildAppTheme(Brightness.dark);
    expect(subtitle.style?.fontSize, theme.textTheme.bodySmall?.fontSize);
    expect(subtitle.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.text('Reach us here')).dy,
      greaterThan(tester.getTopLeft(find.text('Contact')).dy),
    );
  });

  testWidgets('medium style insets the title by space20 / space4', (
    tester,
  ) async {
    await tester.pumpWidget(_host(child: const SheetHeader(title: 'Speed')));

    final t = _tokens();
    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.text('Speed'), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      EdgeInsets.fromLTRB(t.space20, t.space4, t.space20, t.space12),
    );
  });

  testWidgets('large style insets the title by space24', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const SheetHeader(
          title: 'Subscribe',
          style: SheetHeaderStyle.large,
        ),
      ),
    );

    final t = _tokens();
    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.text('Subscribe'), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space8),
    );
  });

  testWidgets('a subtitle pulls the title closer to it', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const SheetHeader(title: 'Contact', subtitle: 'Reach us here'),
      ),
    );

    final t = _tokens();
    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.text('Contact'), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      EdgeInsets.fromLTRB(t.space20, t.space4, t.space20, t.space4),
    );
  });
}
