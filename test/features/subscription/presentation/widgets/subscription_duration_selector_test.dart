import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/subscription_duration_selector.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _harness({
  required int months,
  required ValueChanged<int> onMonthsChanged,
  required bool enabled,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    locale: const Locale('en', 'US'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SubscriptionDurationSelector(
          months: months,
          enabled: enabled,
          onMonthsChanged: onMonthsChanged,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionDurationSelector — preset mapping', () {
    testWidgets('renders the four preset chips', (tester) async {
      await tester.pumpWidget(
        _harness(months: 1, onMonthsChanged: (_) {}, enabled: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionDurationSelector), findsOneWidget);
      expect(find.text('1 month'), findsOneWidget);
      expect(find.text('1 season'), findsOneWidget);
      expect(find.text('1 year'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('renders the duration label and chip rows', (tester) async {
      await tester.pumpWidget(
        _harness(months: 3, onMonthsChanged: (_) {}, enabled: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('1 season'), findsOneWidget);
    });
  });

  group('SubscriptionDurationSelector — interactions', () {
    testWidgets(
      'tapping a non-custom preset emits onMonthsChanged with that preset value',
      (tester) async {
        var received = 0;
        await tester.pumpWidget(
          _harness(
            months: 1,
            onMonthsChanged: (m) => received = m,
            enabled: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('1 year'));
        await tester.pumpAndSettle();
        expect(received, 12);
      },
    );

    testWidgets('tapping custom preset reveals the TextField', (tester) async {
      await tester.pumpWidget(
        _harness(months: 1, onMonthsChanged: (_) {}, enabled: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('changing the custom field emits clamped months', (
      tester,
    ) async {
      var received = 0;
      await tester.pumpWidget(
        _harness(
          months: 5,
          onMonthsChanged: (m) => received = m,
          enabled: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      received = 0;

      await tester.enterText(find.byType(TextField), '99');
      await tester.pumpAndSettle();
      expect(received, kSubscriptionMaxCustomMonths);

      received = 0;
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();
      expect(received, kSubscriptionMinCustomMonths);

      received = 0;
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(received, 5);
    });

    testWidgets(
      'didUpdateWidget re-syncs preset to a non-custom value when widget.months changes',
      (tester) async {
        var received = 1;
        await tester.pumpWidget(
          _harness(
            months: 1,
            onMonthsChanged: (m) => received = m,
            enabled: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _harness(
            months: 3,
            onMonthsChanged: (m) => received = m,
            enabled: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(received, 1);
      },
    );
  });

  group('SubscriptionDurationSelector — disabled state', () {
    testWidgets('does not fire onMonthsChanged when disabled', (tester) async {
      var received = 0;
      await tester.pumpWidget(
        _harness(
          months: 1,
          onMonthsChanged: (m) => received = m,
          enabled: false,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 year'));
      await tester.pumpAndSettle();
      expect(received, 0);
    });
  });
}
