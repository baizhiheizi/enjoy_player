/// Pick a preferred audio input device, skipping likely-virtual ones.
///
/// On Windows in particular, the system input device may default to a virtual
/// loopback / "shared audio" capture (e.g. ASUS GlideX, VoiceMeeter, Stereo
/// Mix, VB-Audio CABLE). Those devices open successfully but emit a stream of
/// mostly-zero samples with rare full-scale spikes — i.e. silent recordings
/// with a peak that looks healthy. We default to the first device whose label
/// does not match a known virtual/loopback pattern so shadow-reading captures
/// the real microphone unless the user picked otherwise.
library;
 
/// Substrings (lowercased) that identify devices we'd rather not capture from
/// when a real mic is also available.
const List<String> kKnownVirtualInputDeviceMarkers = <String>[
  'glidex',
  'stereo mix',
  '立体声混音',
  'voicemeeter',
  'vb-audio',
  'vb audio',
  'cable input',
  'cable output',
  'virtual cable',
  'virtual audio',
  '虚拟',
  'loopback',
  'what u hear',
  'shared audio',
  'screen audio',
  'screensharing',
  'screen sharing',
  'obs virtual',
  'nvidia broadcast',
];

/// Lightweight, dependency-free shape of a `record` `InputDevice` so this
/// module stays test-friendly without pulling Flutter / `record` into tests.
final class InputDeviceLite {
  const InputDeviceLite({required this.id, required this.label});
  final String id;
  final String label;
}

/// `true` when [label] looks like a virtual / loopback / share-audio device.
bool isLikelyVirtualInputDevice(String label) {
  final lower = label.toLowerCase();
  for (final marker in kKnownVirtualInputDeviceMarkers) {
    if (lower.contains(marker)) return true;
  }
  return false;
}

/// Returns the device id that should be passed to `RecordConfig.device`.
///
/// Selection order:
/// 1. [preferredId] when it still matches a present device.
/// 2. The first device whose label does not look virtual.
/// 3. The first device.
/// 4. `null` when no devices were enumerated (caller should fall back to the
///    OS default).
String? pickPreferredInputDeviceId(
  List<InputDeviceLite> devices, {
  String? preferredId,
}) {
  if (devices.isEmpty) return null;
  if (preferredId != null && preferredId.isNotEmpty) {
    for (final d in devices) {
      if (d.id == preferredId) return d.id;
    }
  }
  for (final d in devices) {
    if (!isLikelyVirtualInputDevice(d.label)) return d.id;
  }
  return devices.first.id;
}
