/// Recovery actions for the corrupt / unopenable local database path.
/// Used by [RecoverySurface] in `app.dart` when
/// `appPreferencesCtrlProvider` fails to resolve.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/data/db/app_database.dart';

final _log = logNamed('RecoveryActions');

/// Best-effort copy of [error] to the system clipboard.
Future<bool> copyErrorToClipboard(Object error, StackTrace? stack) async {
  try {
    final buf = StringBuffer()
      ..writeln('Enjoy Player — local data recovery')
      ..writeln('Captured: ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln()
      ..writeln('Error:')
      ..writeln(error)
      ..writeln();
    if (stack != null) {
      buf
        ..writeln('Stack trace:')
        ..writeln(stack);
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    return true;
  } catch (e, st) {
    _log.warning('copyErrorToClipboard failed', e, st);
    return false;
  }
}

/// Opens the rotating log directory in the platform file explorer.
///
/// Returns `true` if the OS reported a successful launch. The caller
/// should show a user-visible failure notice when this returns `false`.
/// Mobile platforms (Android, iOS) have no generic file-explorer API
/// and always return `false`; the recovery surface still offers
/// "Copy error" as the mobile fallback.
Future<bool> openLogsFolder() async {
  try {
    final dir = LogFileSink.instance?.directory;
    if (dir == null || !dir.existsSync()) {
      return _openSupportDirFallback();
    }
    return _revealInFileManager(dir.path);
  } catch (e, st) {
    _log.warning('openLogsFolder failed', e, st);
    return false;
  }
}

Future<bool> _openSupportDirFallback() async {
  try {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'logs'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return _revealInFileManager(dir.path);
  } catch (e, st) {
    _log.warning('openLogsFolder fallback failed', e, st);
    return false;
  }
}

bool _revealInFileManager(String path) {
  if (Platform.isWindows) {
    return _runAndCheck('explorer', <String>[path]);
  }
  if (Platform.isMacOS) {
    return _runAndCheck('open', <String>[path]);
  }
  if (Platform.isLinux) {
    return _runAndCheck('xdg-open', <String>[path]);
  }
  return false;
}

bool _runAndCheck(String exe, List<String> args) {
  try {
    final r = Process.runSync(exe, args);
    return r.exitCode == 0;
  } catch (e, st) {
    _log.fine('reveal $exe failed', e, st);
    return false;
  }
}

/// Backs up the on-disk Drift database file (best-effort) before a
/// destructive wipe. Returns the absolute path of the backup, or `null`
/// if the backup failed.
Future<String?> backupLocalDatabaseFile() async {
  try {
    final support = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(support.path, 'databases'));
    if (!dbDir.existsSync()) {
      return null;
    }
    final stamp = DateTime.now().toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final backupDir = Directory(p.join(support.path, 'migrations'));
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }
    final source = File(
      p.join(dbDir.path, '${AppDatabase.guestDatabaseName}.sqlite'),
    );
    if (!source.existsSync()) {
      return null;
    }
    final dest = File(
      p.join(backupDir.path, 'enjoy_player_$stamp.sqlite'),
    );
    await source.copy(dest.path);
    _log.info('backupLocalDatabaseFile: wrote ${dest.path}');
    return dest.path;
  } catch (e, st) {
    _log.warning('backupLocalDatabaseFile failed', e, st);
    return null;
  }
}

/// Closes every per-user Drift database and deletes the on-disk SQLite
/// file. After this, the next read of any `appDatabaseProvider*` will
/// recreate the schema from scratch.
///
/// The auth controller is not reset; signed-in users keep their session
/// in secure storage and will rebuild their per-user database on the
/// next read.
Future<void> wipeLocalDatabaseFiles() async {
  try {
    final support = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(support.path, 'databases'));
    if (!dbDir.existsSync()) {
      return;
    }
    final candidates = <String>{
      '${AppDatabase.guestDatabaseName}.sqlite',
      '${AppDatabase.guestDatabaseName}.sqlite-wal',
      '${AppDatabase.guestDatabaseName}.sqlite-shm',
    };
    for (final entity in dbDir.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final base = p.basename(entity.path);
      if (base.endsWith('.sqlite') ||
          base.endsWith('.sqlite-wal') ||
          base.endsWith('.sqlite-shm')) {
        candidates.add(base);
      }
    }
    for (final name in candidates) {
      final f = File(p.join(dbDir.path, name));
      if (f.existsSync()) {
        await f.delete();
        _log.info('wipeLocalDatabaseFiles: deleted $name');
      }
    }
  } catch (e, st) {
    _log.warning('wipeLocalDatabaseFiles failed', e, st);
    rethrow;
  }
}

/// Resets the local library: backs up, then wipes. Used by the
/// destructive-migration flow wired in `app.dart`.
Future<RecoveryResetOutcome> resetLocalLibraryWithBackup() async {
  final backupPath = await backupLocalDatabaseFile();
  if (backupPath == null) {
    return RecoveryResetOutcome.backupFailed;
  }
  try {
    await wipeLocalDatabaseFiles();
    return RecoveryResetOutcome.success;
  } catch (e, st) {
    _log.warning('wipe failed after backup', e, st);
    return RecoveryResetOutcome.wipeFailed;
  }
}

enum RecoveryResetOutcome { success, backupFailed, wipeFailed }

/// Tells the caller whether [error] looks like an "unopenable local
/// database" failure (corrupt file, schema-version gap, …) so the
/// caller can route the user to the recovery surface.
bool isUnrecoverableDatabaseError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('sqlite_exception') ||
      msg.contains('database is corrupt') ||
      msg.contains('file is not a database') ||
      msg.contains('unable to open') ||
      msg.contains('no such table') ||
      msg.contains('unsupported schema');
}
