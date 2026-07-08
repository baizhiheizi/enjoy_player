import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/transcript_blur_section.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget harness() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TranscriptBlurSectionBody()),
      ),
    );
  }

  testWidgets('renders section title, hint and the current seconds value', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Tap-reveal hold duration'), findsOneWidget);
    expect(
      find.text('How long a tapped cue stays unblurred on touch devices'),
      findsOneWidget,
    );
    expect(find.text('3s'), findsOneWidget); // default
  });

  testWidgets('slider drag persists the new hold duration', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Find the slider and drag it to a higher value (right).
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(120, 0));
    await tester.pumpAndSettle();

    final stored = await db.settingsDao.getValue(
      SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
    );
    expect(stored, isNotNull);
    final parsed = int.tryParse(stored!);
    expect(parsed, isNotNull);
    expect(parsed, greaterThan(3));
    expect(
      parsed,
      lessThanOrEqualTo(TranscriptBlurPreferences.tapRevealSecondsMax),
    );
  });
}
