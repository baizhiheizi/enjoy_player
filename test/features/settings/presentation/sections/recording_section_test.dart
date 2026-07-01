import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/recording_section.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _devices = <InputDevice>[
  InputDevice(id: 'mic-1', label: 'USB Microphone'),
  InputDevice(id: 'mic-2', label: 'Built-in Microphone'),
];

/// Avoids the real `AudioRecorder`/native hardware enumeration that
/// [RecordingInputDeviceCtrl.refresh]/`_enumerate` would otherwise trigger
/// (hangs or is flaky outside a full platform engine).
class _FakeRecordingInputDeviceCtrl extends RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async =>
      const RecordingInputDeviceState(
        devices: _devices,
        selectedId: 'mic-1',
        persistedId: null,
      );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> selectDeviceId(String? deviceId) async {
    final normalized = (deviceId == null || deviceId.isEmpty)
        ? null
        : deviceId;
    state = AsyncData(
      RecordingInputDeviceState(
        devices: _devices,
        selectedId: normalized ?? 'mic-1',
        persistedId: normalized,
      ),
    );
  }
}

Widget _harness() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ProviderScope(
    overrides: [
      recordingInputDeviceCtrlProvider.overrideWith(
        _FakeRecordingInputDeviceCtrl.new,
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      locale: const Locale('en', 'US'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RecordingSectionBody()),
    ),
  );
}

void main() {
  testWidgets(
    'selecting a microphone device updates the Recording row subtitle and '
    'closes the picker dialog',
    (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      // Auto-picked mic-1 is shown via the "Auto · <label>" subtitle.
      expect(find.text(l10n.settingsRecordingMicAuto('USB Microphone')),
          findsOneWidget);

      await tester.tap(find.text(l10n.settingsRecordingMicTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsRecordingMicDialogTitle), findsOneWidget);
      expect(find.text('Built-in Microphone'), findsOneWidget);

      await tester.tap(find.text('Built-in Microphone'));
      await tester.pumpAndSettle();

      // The dialog is dismissed and the row reflects the explicit pick.
      expect(find.text(l10n.settingsRecordingMicDialogTitle), findsNothing);
      expect(find.text('Built-in Microphone'), findsOneWidget);
      expect(
        find.text(l10n.settingsRecordingMicAuto('USB Microphone')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an empty device list still renders an explanatory subtitle instead of '
    'a blank row',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingInputDeviceCtrlProvider.overrideWith(
              () => _EmptyRecordingInputDeviceCtrl(),
            ),
          ],
          child: Builder(
            builder: (context) {
              final scheme = ColorScheme.fromSeed(
                seedColor: const Color(0xFF7B61FF),
                brightness: Brightness.dark,
              );
              return MaterialApp(
                theme: ThemeData(
                  colorScheme: scheme,
                  extensions: [EnjoyThemeTokens.build(scheme)],
                ),
                locale: const Locale('en', 'US'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: RecordingSectionBody()),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );
      expect(find.text(l10n.settingsRecordingMicEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _EmptyRecordingInputDeviceCtrl extends RecordingInputDeviceCtrl {
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
