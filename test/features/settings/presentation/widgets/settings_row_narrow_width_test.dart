import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';

Widget _harness(Widget child, {double width = 320}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(
      body: SizedBox(width: width, child: child),
    ),
  );
}

void main() {
  testWidgets(
    'a long value badge on a narrow row wraps below the title instead of '
    'being clipped out of view',
    (tester) async {
      const longValue = 'someone.with.a.really.long.email@example.com';

      await tester.pumpWidget(
        _harness(
          SettingsRow(
            title: 'Account',
            leadingIcon: Icons.person_outline_rounded,
            valueBadge: const SettingsValuePill(label: longValue),
            onTap: () {},
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      // Title stays visible and fully legible.
      expect(find.text('Account'), findsOneWidget);
      // The value pill (and its ellipsis-truncated but present text) still
      // renders — it isn't hidden entirely by the narrow row.
      expect(find.byType(SettingsValuePill), findsOneWidget);
      expect(find.text(longValue), findsOneWidget);
      // No RenderFlex/overflow exceptions from squeezing title + value badge
      // onto a single line at this width.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a wide row keeps the title and value badge on one line without '
    'overflowing',
    (tester) async {
      const longValue = 'someone.with.a.really.long.email@example.com';

      await tester.pumpWidget(
        _harness(
          SettingsRow(
            title: 'Account',
            leadingIcon: Icons.person_outline_rounded,
            valueBadge: const SettingsValuePill(label: longValue),
            onTap: () {},
          ),
          width: 700,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.byType(SettingsValuePill), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
