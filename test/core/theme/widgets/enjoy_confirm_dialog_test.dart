import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Object _unresolved = Object();

Future<Object?> openConfirmAndAct(
  WidgetTester tester, {
  required Future<void> Function(WidgetTester tester) act,
  Future<void> Function(WidgetTester tester)? inspect,
  bool destructive = false,
  bool deemphasizeConfirm = false,
  String? cancelLabel = 'Keep it',
  String confirmLabel = 'Delete it',
}) async {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  Object? resolved = _unresolved;
  unawaited(
    showEnjoyConfirmDialog(
      context: hostContext,
      title: 'Title',
      message: 'Message',
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      deemphasizeConfirm: deemphasizeConfirm,
    ).then((value) => resolved = value),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  await inspect?.call(tester);
  await act(tester);
  await tester.pumpAndSettle();
  return resolved;
}

void main() {
  testWidgets('confirm resolves true, cancel resolves false', (tester) async {
    expect(
      await openConfirmAndAct(tester, act: (t) => t.tap(find.text('Keep it'))),
      isFalse,
    );
    expect(
      await openConfirmAndAct(
        tester,
        act: (t) => t.tap(find.text('Delete it')),
      ),
      isTrue,
    );
  });

  testWidgets('barrier dismissal resolves false', (tester) async {
    expect(
      await openConfirmAndAct(
        tester,
        act: (t) => t.tapAt(const Offset(10, 10)),
      ),
      isFalse,
    );
  });

  testWidgets('destructive renders a destructive fill for the confirm action', (
    tester,
  ) async {
    final result = await openConfirmAndAct(
      tester,
      destructive: true,
      inspect: (t) async {
        final button = t.widget<EnjoyButton>(
          find.ancestor(
            of: find.text('Delete it'),
            matching: find.byType(EnjoyButton),
          ),
        );
        expect(button.variant, EnjoyButtonVariant.destructive);
      },
      act: (t) => t.tap(find.text('Delete it')),
    );
    expect(result, isTrue);
  });

  testWidgets('deemphasizeConfirm keeps the true-means-confirmed contract', (
    tester,
  ) async {
    expect(
      await openConfirmAndAct(
        tester,
        deemphasizeConfirm: true,
        cancelLabel: 'Keep subscription',
        confirmLabel: 'Cancel subscription',
        act: (t) => t.tap(find.text('Keep subscription')),
      ),
      isFalse,
    );
    expect(
      await openConfirmAndAct(
        tester,
        deemphasizeConfirm: true,
        cancelLabel: 'Keep subscription',
        confirmLabel: 'Cancel subscription',
        act: (t) => t.tap(find.text('Cancel subscription')),
      ),
      isTrue,
    );
  });

  testWidgets(
    'deemphasizeConfirm renders the low-emphasis confirm and primary safe action',
    (tester) async {
      final result = await openConfirmAndAct(
        tester,
        deemphasizeConfirm: true,
        cancelLabel: 'Keep subscription',
        confirmLabel: 'Cancel subscription',
        inspect: (t) async {
          expect(find.text('Cancel subscription'), findsOneWidget);
          expect(find.text('Keep subscription'), findsOneWidget);
          final guardrailConfirm = t.widget<TextButton>(
            find.ancestor(
              of: find.text('Cancel subscription'),
              matching: find.byType(TextButton),
            ),
          );
          expect(guardrailConfirm.onPressed, isNotNull);
          final safeAction = t.widget<EnjoyButton>(
            find.ancestor(
              of: find.text('Keep subscription'),
              matching: find.byType(EnjoyButton),
            ),
          );
          expect(safeAction.variant, EnjoyButtonVariant.primary);
        },
        act: (t) => t.tap(find.text('Keep subscription')),
      );
      expect(result, isFalse);
    },
  );
}
