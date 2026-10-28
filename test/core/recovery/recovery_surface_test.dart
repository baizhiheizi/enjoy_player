import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_error_panel.dart';
import 'package:enjoy_player/core/recovery/recovery_surface.dart';
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
    home: child,
  );
}

void main() {
  testWidgets('RecoverySurface renders the three actions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RecoverySurface(error: 'SqliteException: file is not a database'),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecoverySurface)),
    )!;

    expect(find.byType(RecoveryErrorLayout), findsOneWidget);
    expect(find.byType(RecoveryErrorPanel), findsOneWidget);
    expect(find.text(l10n.recoveryTitle), findsOneWidget);
    expect(find.text(l10n.recoveryCopyError), findsOneWidget);
    expect(find.text(l10n.recoveryOpenLogs), findsOneWidget);
    expect(find.text(l10n.recoveryResetLibrary), findsAtLeastNWidgets(1));
    expect(
      find.textContaining('file is not a database'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Tapping Reset shows the confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const RecoverySurface(error: 'SqliteException: oops')),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecoverySurface)),
    )!;

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.recoveryResetLibrary),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.recoveryResetLibraryConfirmTitle), findsOneWidget);
    expect(find.text(l10n.recoveryResetLibraryConfirmAction), findsOneWidget);
    expect(find.text(l10n.authCancel), findsOneWidget);
  });

  testWidgets(
    'Confirming reset calls the injected onReset instead of the default '
    'file-only reset',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var resetCalls = 0;
      await tester.pumpWidget(
        _wrap(
          RecoverySurface(
            error: 'SqliteException: oops',
            onReset: () async {
              resetCalls++;
              return RecoveryResetOutcome.success;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecoverySurface)),
      )!;

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.recoveryResetLibrary),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.recoveryResetLibraryConfirmAction));
      await tester.pumpAndSettle();

      expect(resetCalls, 1);
      expect(
        find.textContaining(l10n.recoveryResetLibrarySuccess),
        findsOneWidget,
      );
    },
  );
}
