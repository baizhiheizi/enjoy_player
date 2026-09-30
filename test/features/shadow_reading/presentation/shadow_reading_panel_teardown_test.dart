import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart' show RecordConfig;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_store.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/shadow_reading_panel.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_record_fab.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _HangingMicRecorder implements MicRecorder {
  final Completer<bool> _permission = Completer<bool>();

  @override
  Future<bool> hasPermission() => _permission.future;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {}

  @override
  Future<String?> stop() async => null;

  @override
  Future<void> dispose() async {}
}

class _HangingStoreFactory extends ShadowTakeStoreFactory {
  _HangingStoreFactory({required super.db, required super.enqueueSync});

  @override
  ShadowTakeStore call({
    MicRecorder Function()? recorderFactory,
    Directory? takeDirectory,
  }) => super.call(
    recorderFactory: _HangingMicRecorder.new,
    takeDirectory: Directory.systemTemp.createTempSync('enjoy-takes'),
  );
}

class _NoopInputDeviceCtrl extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: [],
        selectedId: null,
        persistedId: null,
      );

  @override
  Future<void> refresh() async {}
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

const _panel = ShadowReadingPanel(
  mediaId: 'media-1',
  targetType: 'Video',
  language: 'en',
  startSec: 0,
  endSec: 2,
  referenceText: 'reference text',
  echoActive: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recordingInputDeviceCtrlProvider.overrideWith(_NoopInputDeviceCtrl.new),
        shadowTakeStoreFactoryProvider.overrideWithValue(
          _HangingStoreFactory(
            db: db,
            enqueueSync: (SyncEntityType _, String _, SyncAction _) async {},
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  testWidgets('unmounting mid-pending resets the hotkey bus, no ref access', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _host(_panel)),
    );
    await tester.pump();
    expect(
      container.read(shadowReadingHotkeyBusProvider).isRecordingActive,
      isFalse,
    );

    await tester.tap(find.byType(ShadowRecordFab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      container.read(shadowReadingHotkeyBusProvider).isRecordingActive,
      isTrue,
      reason: 'capture start is pending on the hanging permission future',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _host(const SizedBox.shrink()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      container.read(shadowReadingHotkeyBusProvider).isRecordingActive,
      isFalse,
      reason: 'dispose resets the bus through the captured notifier handle',
    );
  });
}
