/// Persisted custom hotkey bindings (Drift settings KV; mirrors web `customBindings`).
library;

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database_provider.dart';
import '../domain/hotkey_chord.dart';
import '../domain/hotkey_definitions.dart';

part 'hotkeys_ctrl.g.dart';

Map<String, String> _decodeBindings(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final out = <String, String>{};
    for (final e in decoded.entries) {
      final k = e.key;
      final v = e.value;
      if (k is! String || v is! String) continue;
      if (!hotkeyDefinitionMap.containsKey(k)) continue;
      if (!isValidHotkeyBindingString(v)) continue;
      out[k] = v;
    }
    return out;
  } catch (_) {
    return {};
  }
}

bool isValidHotkeyBindingString(String s) {
  try {
    parseHotkeyString(s);
    return true;
  } on FormatException {
    return false;
  }
}

@Riverpod(keepAlive: true)
class HotkeysCtrl extends _$HotkeysCtrl {
  @override
  Future<Map<String, String>> build() async {
    final db = ref.watch(appDatabaseProvider);
    final raw = await db.settingsDao.getValue(kHotkeysCustomBindingsKey);
    return _decodeBindings(raw);
  }

  /// Custom binding or default from definitions.
  String effectiveKeys(String actionId) {
    final def = hotkeyDefinitionMap[actionId];
    if (def == null) return '';
    final async = state;
    return switch (async) {
      AsyncData(:final value) => value[actionId] ?? def.defaultKeys,
      _ => def.defaultKeys,
    };
  }

  bool hasCustomBinding(String actionId) {
    final async = state;
    return switch (async) {
      AsyncData(:final value) =>
        value[actionId] != null && value[actionId]!.isNotEmpty,
      _ => false,
    };
  }

  Future<void> _persist(Map<String, String> next) async {
    await ref.read(appDatabaseProvider).settingsDao.setValue(
          kHotkeysCustomBindingsKey,
          jsonEncode(next),
        );
  }

  /// Returns false if invalid, non-customizable, or conflicting with another action.
  Future<bool> setBinding(String actionId, String binding) async {
    final def = hotkeyDefinitionMap[actionId];
    if (def == null || !def.customizable) return false;
    if (!isValidHotkeyBindingString(binding)) return false;

    final current = await future;
    for (final other in hotkeyDefinitions) {
      if (other.id == actionId) continue;
      final otherBinding = current[other.id] ?? other.defaultKeys;
      if (hotkeyBindingsConflict(binding, otherBinding)) {
        return false;
      }
    }

    final next = Map<String, String>.from(current);
    next[actionId] = binding;
    await _persist(next);
    state = AsyncData(next);
    return true;
  }

  Future<void> resetBinding(String actionId) async {
    final def = hotkeyDefinitionMap[actionId];
    if (def == null || !def.customizable) return;
    final current = await future;
    if (!current.containsKey(actionId)) return;
    final next = Map<String, String>.from(current)..remove(actionId);
    await _persist(next);
    state = AsyncData(next);
  }

  Future<void> resetAllBindings() async {
    await _persist({});
    state = const AsyncData({});
  }
}
