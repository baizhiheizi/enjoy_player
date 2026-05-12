/// Selected microphone for shadow-reading recordings (Drift-backed).
///
/// Surfaced in settings → Recording → Microphone. Wraps
/// `AudioRecorder.listInputDevices()` so the panel can pass the chosen device
/// to [RecordConfig.device] and so the user choice is persisted in
/// [SettingsKeys.prefsRecordingInputDeviceId]. When no preference is set,
/// [pickPreferredInputDeviceId] skips known virtual / loopback devices
/// (GlideX, VoiceMeeter, Stereo Mix, …) which on Windows would otherwise be
/// the system default and capture only zeros.
library;

import 'package:logging/logging.dart';
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_picker.dart';

part 'recording_input_device_controller.g.dart';

final Logger _log = logNamed('shadow_reading.recording_input_device');

class RecordingInputDeviceState {
  const RecordingInputDeviceState({
    required this.devices,
    required this.selectedId,
    required this.persistedId,
  });

  /// Devices currently reported by the OS (from
  /// [AudioRecorder.listInputDevices]).
  final List<InputDevice> devices;

  /// Effective device id to pass to [RecordConfig.device]. May be `null` when
  /// no devices are enumerated — let the OS pick.
  final String? selectedId;

  /// Last id explicitly persisted by the user. `null` means we are auto-picking.
  final String? persistedId;

  InputDevice? get selectedDevice {
    final id = selectedId;
    if (id == null) return null;
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  bool get autoPicked => persistedId == null;
}

@Riverpod(keepAlive: true)
class RecordingInputDeviceCtrl extends _$RecordingInputDeviceCtrl {
  @override
  Future<RecordingInputDeviceState> build() async {
    final persisted = await _readPersistedId();
    final devices = await _enumerate();
    return _stateFor(devices: devices, persisted: persisted);
  }

  /// Re-enumerate devices (e.g. when settings opens or a USB mic is plugged
  /// in).
  Future<void> refresh() async {
    final persisted = state.valueOrNull?.persistedId ?? await _readPersistedId();
    final devices = await _enumerate();
    state = AsyncData(_stateFor(devices: devices, persisted: persisted));
  }

  /// Persist the user's pick. Pass `null` to revert to the auto heuristic.
  Future<void> selectDeviceId(String? deviceId) async {
    final normalized = (deviceId == null || deviceId.isEmpty) ? null : deviceId;
    final db = ref.read(appDatabaseProvider);
    await db.settingsDao.setValue(
      SettingsKeys.prefsRecordingInputDeviceId,
      normalized ?? '',
    );
    final devices = state.valueOrNull?.devices ?? await _enumerate();
    state = AsyncData(_stateFor(devices: devices, persisted: normalized));
    _log.info(
      'select persisted=${normalized ?? "<auto>"} '
      'effective=${state.valueOrNull?.selectedId ?? "<os-default>"}',
    );
  }

  RecordingInputDeviceState _stateFor({
    required List<InputDevice> devices,
    required String? persisted,
  }) {
    final lite = devices
        .map((d) => InputDeviceLite(id: d.id, label: d.label))
        .toList(growable: false);
    final selectedId =
        pickPreferredInputDeviceId(lite, preferredId: persisted);
    return RecordingInputDeviceState(
      devices: devices,
      selectedId: selectedId,
      persistedId: persisted,
    );
  }

  Future<String?> _readPersistedId() async {
    final raw = await ref.read(appDatabaseProvider).settingsDao.getValue(
          SettingsKeys.prefsRecordingInputDeviceId,
        );
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// One-shot enumeration. `AudioRecorder` is short-lived and disposed after
  /// the call so we don't hold a Media Foundation handle for no reason.
  Future<List<InputDevice>> _enumerate() async {
    final probe = AudioRecorder();
    try {
      final list = await probe.listInputDevices();
      return List<InputDevice>.unmodifiable(list);
    } on Object catch (e, st) {
      _log.fine('listInputDevices failed', e, st);
      return const <InputDevice>[];
    } finally {
      try {
        await probe.dispose();
      } catch (_) {}
    }
  }
}
