/// Rotating on-disk log file under application support.
library;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'log_redaction.dart';

const int kLogFileMaxBytes = 2 * 1024 * 1024;
const int kLogFileRetentionCount = 3;
const String kLogFileBaseName = 'enjoy-player.log';

/// Active rotating log sink (null until [LogFileSink.ensureInitialized]).
class LogFileSink {
  LogFileSink._(this._directory);

  final Directory _directory;
  File? _activeFile;
  int _activeSize = 0;

  static LogFileSink? _instance;

  static LogFileSink? get instance => _instance;

  static Future<LogFileSink?> ensureInitialized() async {
    if (_instance != null) return _instance;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory(p.join(support.path, 'logs'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      _instance = LogFileSink._(dir);
      await _instance!._openActiveFile();
      return _instance;
    } on Object {
      return null;
    }
  }

  Directory get directory => _directory;

  Iterable<File> listLogFiles() sync* {
    yield File(p.join(_directory.path, kLogFileBaseName));
    for (var i = 1; i < kLogFileRetentionCount; i++) {
      yield File(p.join(_directory.path, '$kLogFileBaseName.$i'));
    }
  }

  Future<void> _openActiveFile() async {
    _activeFile = File(p.join(_directory.path, kLogFileBaseName));
    if (_activeFile!.existsSync()) {
      _activeSize = await _activeFile!.length();
    } else {
      _activeSize = 0;
    }
  }

  Future<void> writeRecord(LogRecord record) async {
    final file = _activeFile;
    if (file == null) return;

    final buffer = StringBuffer()
      ..write('[${record.time.toUtc().toIso8601String()}] ')
      ..write('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      buffer.write('\n  error: ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\n  stack:\n${record.stackTrace}');
    }
    buffer.write('\n');

    final line = redactLogLine(buffer.toString());
    final bytes = line.codeUnits.length; // UTF-16 code units; close enough cap
    if (_activeSize + bytes > kLogFileMaxBytes) {
      await _rotate();
    }
    await file.writeAsString(line, mode: FileMode.append, flush: true);
    _activeSize += bytes;
  }

  Future<void> writeRawLine(String line) async {
    final file = _activeFile;
    if (file == null) return;
    final redacted = redactLogLine('$line\n');
    final bytes = redacted.codeUnits.length;
    if (_activeSize + bytes > kLogFileMaxBytes) {
      await _rotate();
    }
    await file.writeAsString(redacted, mode: FileMode.append, flush: true);
    _activeSize += bytes;
  }

  Future<void> _rotate() async {
    final oldest = File(
      p.join(
        _directory.path,
        '$kLogFileBaseName.${kLogFileRetentionCount - 1}',
      ),
    );
    if (oldest.existsSync()) {
      await oldest.delete();
    }
    for (var i = kLogFileRetentionCount - 2; i >= 1; i--) {
      final src = File(p.join(_directory.path, '$kLogFileBaseName.$i'));
      if (!src.existsSync()) continue;
      await src.rename(p.join(_directory.path, '$kLogFileBaseName.${i + 1}'));
    }
    final current = File(p.join(_directory.path, kLogFileBaseName));
    if (current.existsSync()) {
      await current.rename(p.join(_directory.path, '$kLogFileBaseName.1'));
    }
    _activeSize = 0;
    _activeFile = File(p.join(_directory.path, kLogFileBaseName));
  }
}
