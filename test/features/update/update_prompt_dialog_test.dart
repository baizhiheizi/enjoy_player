import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:enjoy_player/features/update/presentation/update_prompt_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _releaseOptional = AppRelease(
  currentVersion: '1.0.0',
  severity: UpdateSeverity.optional,
  manifest: ReleaseManifest(
    version: '1.1.0',
    build: 2,
    minSupportedVersion: '1.0.0',
    notes: 'Bug fixes',
    assets: {},
  ),
);

const _releaseMandatory = AppRelease(
  currentVersion: '0.9.0',
  severity: UpdateSeverity.mandatory,
  manifest: ReleaseManifest(
    version: '1.1.0',
    build: 2,
    minSupportedVersion: '1.0.0',
    notes: 'Security fix',
    assets: {},
  ),
);

Widget _harness({
  required AppRelease release,
  required UpdateApplyStreamFactory onApply,
  UpdateCancelCallback? onCancelApply,
  VoidCallback? onLater,
  VoidCallback? onDismiss,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  showUpdatePromptDialog(
                    context: context,
                    release: release,
                    onApply: onApply,
                    onCancelApply: onCancelApply,
                    onLater: onLater ?? () {},
                    onDismiss: onDismiss,
                  ),
                );
              },
              child: const Text('open'),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openPrompt(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

StreamController<UpdateInstallProgress> _broadcast() {
  return StreamController<UpdateInstallProgress>.broadcast();
}

void main() {
  testWidgets('shows preparing feedback immediately after Update now', (
    tester,
  ) async {
    final controller = _broadcast();
    addTearDown(() async {
      if (!controller.isClosed) await controller.close();
    });

    await tester.pumpWidget(
      _harness(release: _releaseOptional, onApply: () => controller.stream),
    );
    await _openPrompt(tester);

    expect(find.text('Update available'), findsOneWidget);
    await tester.tap(find.text('Update now'));
    await tester.pump();

    expect(find.text('Preparing download…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    controller.add(const UpdateInstallProgress.downloading(0.25));
    await tester.pump();
    expect(find.text('Downloading update… 25%'), findsOneWidget);
  });

  testWidgets('shows determinate progress and closes after handoff', (
    tester,
  ) async {
    final controller = _broadcast();
    addTearDown(() async {
      if (!controller.isClosed) await controller.close();
    });

    await tester.pumpWidget(
      _harness(release: _releaseOptional, onApply: () => controller.stream),
    );
    await _openPrompt(tester);
    await tester.tap(find.text('Update now'));
    await tester.pump();

    controller.add(const UpdateInstallProgress.downloading(0.8));
    await tester.pump();
    expect(find.text('Downloading update… 80%'), findsOneWidget);

    controller.add(const UpdateInstallProgress.openingInstaller());
    await tester.pump();
    expect(find.text('Opening installer…'), findsOneWidget);

    controller.add(const UpdateInstallProgress.completed());
    await tester.pump();
    // Dialog route exit animation (avoid pumpAndSettle — progress indicators animate forever).
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('shows inline error and retry', (tester) async {
    var attempts = 0;
    final controllers = <StreamController<UpdateInstallProgress>>[];
    addTearDown(() async {
      for (final c in controllers) {
        if (!c.isClosed) await c.close();
      }
    });

    await tester.pumpWidget(
      _harness(
        release: _releaseOptional,
        onApply: () {
          attempts++;
          final controller = _broadcast();
          controllers.add(controller);
          return controller.stream;
        },
      ),
    );

    await _openPrompt(tester);
    await tester.tap(find.text('Update now'));
    await tester.pump();

    controllers.last.add(
      const UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.download,
      ),
    );
    await tester.pump();

    expect(
      find.text('Download failed. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Preparing download…'), findsOneWidget);
  });

  testWidgets('optional cancel closes the dialog', (tester) async {
    final controller = _broadcast();
    var canceled = false;
    addTearDown(() async {
      if (!controller.isClosed) await controller.close();
    });

    await tester.pumpWidget(
      _harness(
        release: _releaseOptional,
        onApply: () => controller.stream,
        onCancelApply: () async {
          canceled = true;
        },
      ),
    );
    await _openPrompt(tester);
    await tester.tap(find.text('Update now'));
    await tester.pump();

    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(canceled, isTrue);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('mandatory cancel returns to blocking prompt', (tester) async {
    final controller = _broadcast();
    addTearDown(() async {
      if (!controller.isClosed) await controller.close();
    });

    await tester.pumpWidget(
      _harness(
        release: _releaseMandatory,
        onApply: () => controller.stream,
        onCancelApply: () async {},
      ),
    );
    await _openPrompt(tester);

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);

    await tester.tap(find.text('Update now'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('mandatory dialog is not dismissible via barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        release: _releaseMandatory,
        onApply: () => const Stream<UpdateInstallProgress>.empty(),
      ),
    );
    await _openPrompt(tester);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Update required'), findsOneWidget);
  });
}
