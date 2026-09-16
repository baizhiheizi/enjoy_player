/// Typed settings schema — the machinery behind the [SettingsKeys] registry.
///
/// Every settings row is declared once (see `settings_keys.dart`) as a
/// [SettingKey] — or belongs to a [SettingKeyFamily] for dynamic per-target
/// keys — carrying:
///
/// * its storage **scope** ([SettingsScope.device] vs [SettingsScope.user]):
///   which of the two SQLite files owns the row. The app has one
///   device-global database (`enjoy_player.sqlite`, readable before sign-in)
///   and one per signed-in user (`enjoy_player_<userId>.sqlite`); before this
///   schema existed the placement lived only in convention, so reading the
///   right key from the wrong database silently returned `null`. With the
///   declared scope, [SettingsDao] can reject misplaced access (see
///   `SettingsDao.readSetting`) and callers can pick the database from the
///   key itself (see `settingsDatabaseFor`).
/// * a **codec** ([SettingCodec]) that decodes/encodes the stored string.
/// * the **default** observed when the row is missing.
///
/// This file is pure Dart (no Flutter imports) and lives next to the DAO it
/// describes.
library;

import 'dart:convert';

enum SettingsScope {
  /// Device-global DB (`enjoy_player.sqlite` via
  /// `deviceGlobalAppDatabaseProvider`): values that must be readable before
  /// sign-in and survive account switches on a shared device (API base URLs,
  /// diagnostics, analytics opt-out, transcript toggles, update snooze).
  device,

  /// Per-user DB (`enjoy_player_<userId>.sqlite` via `appDatabaseProvider`):
  /// preferences that follow the signed-in account (locale, player prefs,
  /// hotkeys, sync cursors, onboarding progress).
  user,
}

/// Converts between a settings row's string storage and a typed Dart value.
///
/// [decode] is only ever called with a non-empty stored string; a missing row
/// resolves to the key's declared default without consulting the codec.
/// Malformed payloads may throw (JSON codecs) — callers that can be handed a
/// corrupt row keep their own try/catch, exactly as they did when they parsed
/// the raw string inline.
abstract interface class SettingCodec<T> {
  const SettingCodec();

  T decode(String raw);

  String encode(T value);
}

/// `'true'` / `'false'` flags.
///
/// The read polarity follows the flag's declared default: when the default is
/// `true` (an opt-out like analytics capture), anything other than the literal
/// `'false'` counts as on, so a missing or legacy value cannot silently flip
/// the documented default; when the default is `false` (opt-in toggles), only
/// the literal `'true'` counts.
class BoolSettingCodec implements SettingCodec<bool> {
  const BoolSettingCodec({required this.whenMissing});

  /// The value observed when the row is missing — also the polarity anchor.
  final bool whenMissing;

  @override
  bool decode(String raw) => whenMissing ? raw != 'false' : raw == 'true';

  @override
  String encode(bool value) => value ? 'true' : 'false';
}

/// Verbatim strings (URLs, locale tags, persisted device ids).
class StringSettingCodec implements SettingCodec<String> {
  const StringSettingCodec();

  @override
  String decode(String raw) => raw;

  @override
  String encode(String value) => value;
}

/// ISO-8601 UTC timestamps ([DateTime.toIso8601String] round-trip).
///
/// Unparseable payloads decode to `null` (mirroring the previous
/// `DateTime.tryParse(raw)?.toUtc()` inline parsers), so `T` is nullable.
class IsoDateTimeSettingCodec implements SettingCodec<DateTime?> {
  const IsoDateTimeSettingCodec();

  @override
  DateTime? decode(String raw) => DateTime.tryParse(raw)?.toUtc();

  @override
  String encode(DateTime? value) => value!.toUtc().toIso8601String();
}

/// JSON object blobs.
///
/// `decode` throws on malformed JSON / non-object payloads; consumers of
/// corruptible blobs (player/craft/hotkeys/AI preferences) catch that and fall
/// back to defaults, exactly as they did when `jsonDecode` ran inline.
class JsonObjectSettingCodec implements SettingCodec<Map<String, dynamic>> {
  const JsonObjectSettingCodec();

  @override
  Map<String, dynamic> decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  @override
  String encode(Map<String, dynamic> value) => jsonEncode(value);
}

/// One typed settings key: name + scope + codec + default.
///
/// Prefer the [SettingKey.flag] helper for booleans so the codec polarity
/// and the declared default can never drift apart.
final class SettingKey<T> {
  const SettingKey({
    required this.name,
    required this.scope,
    required this.codec,
    this.defaultValue,
  });

  /// Boolean flag with default-dependent polarity (see [BoolSettingCodec]).
  ///
  /// Not const: it threads [whenMissing] into both the codec and the
  /// declared default so they cannot drift apart. Boolean keys therefore
  /// declare as `static final`, everything else as `static const`.
  static SettingKey<bool> flag({
    required String name,
    required SettingsScope scope,
    required bool whenMissing,
  }) => SettingKey<bool>(
    name: name,
    scope: scope,
    codec: BoolSettingCodec(whenMissing: whenMissing),
    defaultValue: whenMissing,
  );

  final String name;
  final SettingsScope scope;
  final SettingCodec<T> codec;

  /// Value observed when the row is missing. May be `null` only when `T` is
  /// nullable ("missing ≡ absent" semantics).
  final T? defaultValue;

  @override
  String toString() => 'SettingKey($name @ $scope)';
}

/// A family of dynamically named keys sharing one prefix, scope, and codec —
/// e.g. `sync.cursor.recording.<targetType>.<targetId>`.
///
/// [matches] + the declared families are the single source behind
/// `SettingsKeys.isKnown`, and [allowPrefixDelete] is the single source behind
/// `SettingsDao.deleteKeysWithPrefix`'s allowlist.
final class SettingKeyFamily<T> {
  const SettingKeyFamily({
    required this.prefix,
    required this.scope,
    required this.codec,
    this.defaultValue,
    this.allowPrefixDelete = false,
  });

  final String prefix;
  final SettingsScope scope;
  final SettingCodec<T> codec;
  final T? defaultValue;

  /// Whether [SettingsDao.deleteKeysWithPrefix] may delete this family's rows.
  final bool allowPrefixDelete;

  /// The typed key for [suffix] (e.g. `'Video.m-1'`).
  SettingKey<T> keyFor(String suffix) => SettingKey<T>(
    name: '$prefix$suffix',
    scope: scope,
    codec: codec,
    defaultValue: defaultValue,
  );

  /// Whether [key] is a member of this family (strictly longer than the
  /// prefix, so the bare prefix itself does not match).
  bool matches(String key) =>
      key.length > prefix.length && key.startsWith(prefix);
}
