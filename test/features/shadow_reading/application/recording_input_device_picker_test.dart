import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_picker.dart';
import 'package:flutter_test/flutter_test.dart';

InputDeviceLite _d(String id, String label) =>
    InputDeviceLite(id: id, label: label);

void main() {
  group('isLikelyVirtualInputDevice', () {
    test('matches GlideX, VoiceMeeter, VB-Audio, Stereo Mix, loopback', () {
      expect(
        isLikelyVirtualInputDevice('麦克风阵列 (GlideX Shared Audio)'),
        isTrue,
      );
      expect(isLikelyVirtualInputDevice('VoiceMeeter Output'), isTrue);
      expect(isLikelyVirtualInputDevice('CABLE Output (VB-Audio Cable)'),
          isTrue);
      expect(isLikelyVirtualInputDevice('Stereo Mix (Realtek)'), isTrue);
      expect(isLikelyVirtualInputDevice('麦克风 (立体声混音)'), isTrue);
      expect(isLikelyVirtualInputDevice('Loopback Capture'), isTrue);
      expect(isLikelyVirtualInputDevice('NVIDIA Broadcast Microphone'), isTrue);
    });

    test('does not match real microphones', () {
      expect(
        isLikelyVirtualInputDevice('麦克风阵列 (Realtek(R) Audio)'),
        isFalse,
      );
      expect(isLikelyVirtualInputDevice('Headset Microphone'), isFalse);
      expect(isLikelyVirtualInputDevice('USB Audio Device'), isFalse);
    });
  });

  group('pickPreferredInputDeviceId', () {
    test('returns null when there are no devices', () {
      expect(pickPreferredInputDeviceId(const []), isNull);
    });

    test('honours the user preference when it still exists', () {
      final devices = [
        _d('id-real', 'Realtek Microphone Array'),
        _d('id-glidex', 'GlideX Shared Audio'),
      ];
      expect(
        pickPreferredInputDeviceId(devices, preferredId: 'id-glidex'),
        'id-glidex',
      );
    });

    test('falls back to the first non-virtual device when preferred is gone',
        () {
      final devices = [
        _d('id-glidex', 'GlideX Shared Audio'),
        _d('id-real', 'Realtek Microphone Array'),
        _d('id-vm', 'VoiceMeeter Output'),
      ];
      expect(
        pickPreferredInputDeviceId(devices, preferredId: 'id-missing'),
        'id-real',
      );
    });

    test('skips a leading virtual device when no preference is set', () {
      final devices = [
        _d('id-glidex', '麦克风阵列 (GlideX Shared Audio)'),
        _d('id-real', '麦克风阵列 (Realtek(R) Audio)'),
      ];
      expect(pickPreferredInputDeviceId(devices), 'id-real');
    });

    test('falls back to the first device if every device looks virtual', () {
      final devices = [
        _d('id-glidex', 'GlideX Shared Audio'),
        _d('id-vm', 'VoiceMeeter Output'),
      ];
      expect(pickPreferredInputDeviceId(devices), 'id-glidex');
    });
  });
}
