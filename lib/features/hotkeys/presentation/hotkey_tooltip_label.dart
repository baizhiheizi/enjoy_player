/// Builds tooltip strings with the active keyboard shortcut (customizable via [HotkeysCtrl]).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/hotkeys_ctrl.dart';
import 'hotkey_format.dart';

/// [baseLabel] plus formatted shortcut, e.g. `Previous line (A)`.
String hotkeyTooltipLabel(WidgetRef ref, String actionId, String baseLabel) {
  ref.watch(hotkeysCtrlProvider);
  final keys = ref.read(hotkeysCtrlProvider.notifier).effectiveKeys(actionId);
  if (keys.isEmpty) return baseLabel;
  return '$baseLabel (${formatHotkeyForDisplay(keys)})';
}

/// For controls that map to two shortcuts (e.g. speed slower / faster).
String hotkeyTooltipPair(
  WidgetRef ref,
  String actionIdA,
  String actionIdB,
  String baseLabel,
) {
  ref.watch(hotkeysCtrlProvider);
  final ctrl = ref.read(hotkeysCtrlProvider.notifier);
  final a = formatHotkeyForDisplay(ctrl.effectiveKeys(actionIdA));
  final b = formatHotkeyForDisplay(ctrl.effectiveKeys(actionIdB));
  return '$baseLabel ($a / $b)';
}
