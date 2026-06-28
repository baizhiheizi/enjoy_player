/// JSON backup of Drift tables before destructive schema upgrades.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('db.migration_backup');

/// Tables exported before a destructive migration (includes legacy names).
const migrationBackupTableNames = <String>[
  'videos',
  'audios',
  'transcripts',
  'transcript_fetch_states',
  'echo_sessions',
  'recordings',
  'dictations',
  'sync_queue',
  'settings',
  'youtube_channel_subscriptions',
  'youtube_feed_entries',
  'playback_sessions',
  'media',
];

/// Serializes every known table to JSON under
/// `app_support/migrations/<from>_to_<to>_<timestamp>.json`.
///
/// Returns the absolute backup path, or `null` when the write failed.
Future<String?> backupToJson(
  GeneratedDatabase db, {
  required int from,
  required int to,
}) async {
  try {
    final support = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(support.path, 'migrations'));
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }

    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final fileName = '${from}_to_${to}_$stamp.json';
    final dest = File(p.join(backupDir.path, fileName));

    final payload = <String, dynamic>{
      'schemaFrom': from,
      'schemaTo': to,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    for (final tableName in migrationBackupTableNames) {
      payload['tables'][tableName] = await _exportTable(db, tableName);
    }

    await dest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_jsonify(payload)),
    );
    _log.warning(
      'backupToJson: wrote ${dest.path} before destructive migration '
      '($from → $to)',
    );
    return dest.path;
  } catch (e, st) {
    _log.warning('backupToJson failed ($from → $to)', e, st);
    return null;
  }
}

Future<Map<String, dynamic>> _exportTable(
  GeneratedDatabase db,
  String tableName,
) async {
  try {
    final rows = await db.customSelect('SELECT * FROM $tableName').get();
    return {
      'rowCount': rows.length,
      'rows': rows.map((row) => row.data).toList(growable: false),
    };
  } catch (e, st) {
    _log.fine('backupToJson: skip missing table $tableName', e, st);
    return {'rowCount': 0, 'rows': <Map<String, dynamic>>[], 'missing': true};
  }
}

Object? _jsonify(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) {
    return value.map(
      (key, nested) => MapEntry(key.toString(), _jsonify(nested)),
    );
  }
  if (value is List) {
    return value.map(_jsonify).toList(growable: false);
  }
  return value;
}
