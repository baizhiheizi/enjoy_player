import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_credits_notice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
}

Finder _idleRetryButton() =>
    find.widgetWithIcon(TextButton, EnjoyIcons.refresh);

Finder _busyRetryButton() => find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(LoadingIcon),
);

String _localizedRetryLabel(WidgetTester tester) {
  final context = tester.element(find.byType(LookupCreditsNotice));
  return AppLocalizations.of(context)!.lookupErrorRetry;
}

void _noop() {}

void main() {
  testWidgets('renders message and a Retry button', (tester) async {
    await _pump(
      tester,
      const LookupCreditsNotice(message: 'out of credits', onRetry: _noop),
    );

    expect(find.text('out of credits'), findsOneWidget);
    expect(find.text(_localizedRetryLabel(tester)), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.wallet), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    expect(_idleRetryButton(), findsOneWidget);
    expect(find.byType(LoadingIcon), findsNothing);
  });

  testWidgets('tapping Retry invokes onRetry exactly once and latches busy', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      LookupCreditsNotice(message: 'out of credits', onRetry: () => taps++),
    );

    await tester.tap(_idleRetryButton());
    await tester.pump();
    expect(taps, 1);
    expect(_busyRetryButton(), findsOneWidget);
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('stays disabled while isRetrying is true', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      LookupCreditsNotice(
        message: 'out of credits',
        onRetry: () => taps++,
        isRetrying: true,
      ),
    );

    expect(_busyRetryButton(), findsOneWidget);
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(find.byType(LoadingIcon), findsOneWidget);
  });

  testWidgets(
    'didUpdateWidget resets the tap latch once isRetrying flips back',
    (tester) async {
      var taps = 0;
      var retrying = false;
      Widget build() => LookupCreditsNotice(
        message: 'out of credits',
        onRetry: () => taps++,
        isRetrying: retrying,
      );

      await tester.pumpWidget(_wrap(build()));
      await tester.pump();
      await tester.tap(_idleRetryButton());
      await tester.pump();
      expect(find.byType(LoadingIcon), findsOneWidget);

      retrying = true;
      await tester.pumpWidget(_wrap(build()));
      await tester.pump();
      expect(find.byType(LoadingIcon), findsOneWidget);

      retrying = false;
      await tester.pumpWidget(_wrap(build()));
      await tester.pump();
      expect(find.byType(LoadingIcon), findsNothing);
      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(_idleRetryButton());
      await tester.pump();
      expect(taps, 2);
    },
  );
}
