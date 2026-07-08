import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_toolbar.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required TranscriptBlurPreferences initial,
    required bool hasLines,
  }) {
    return ProviderScope(
      overrides: [
        transcriptBlurPreferencesCtrlProvider.overrideWith(
          () => _FakeBlurPrefsCtrl(initial),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TranscriptBlurToolbar(mediaId: 'm1', hasLines: hasLines),
        ),
      ),
    );
  }

  testWidgets('renders the toggle and reflects off state', (tester) async {
    await tester.pumpWidget(
      harness(initial: TranscriptBlurPreferences.defaults, hasLines: true),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(
      find.byTooltip('Blur practice (focus on listening)'),
      findsOneWidget,
    );
  });

  testWidgets('reflects on state with the visibility_off icon', (tester) async {
    await tester.pumpWidget(
      harness(
        initial: const TranscriptBlurPreferences(
          enabled: true,
          tapRevealSeconds: 3,
        ),
        hasLines: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('disabled when no transcript lines, empty-state tooltip shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(initial: TranscriptBlurPreferences.defaults, hasLines: false),
    );
    await tester.pumpAndSettle();
    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.onPressed, isNull);
    expect(
      find.byTooltip('No transcript lines to practice with'),
      findsOneWidget,
    );
  });

  testWidgets('tap calls setEnabled with the flipped value', (tester) async {
    final fake = _RecordingFakeBlurPrefsCtrl(
      TranscriptBlurPreferences.defaults,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptBlurPreferencesCtrlProvider.overrideWith(() => fake),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TranscriptBlurToolbar(mediaId: 'm1', hasLines: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(fake.lastSetEnabled, isTrue);
  });
}

class _FakeBlurPrefsCtrl extends TranscriptBlurPreferencesCtrl {
  _FakeBlurPrefsCtrl(this._initial);
  final TranscriptBlurPreferences _initial;

  @override
  Future<TranscriptBlurPreferences> build() async => _initial;

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<void> setTapRevealSeconds(int seconds) async {}
}

class _RecordingFakeBlurPrefsCtrl extends _FakeBlurPrefsCtrl {
  _RecordingFakeBlurPrefsCtrl(super.initial);

  bool? lastSetEnabled;

  @override
  Future<void> setEnabled(bool value) async {
    lastSetEnabled = value;
  }
}
