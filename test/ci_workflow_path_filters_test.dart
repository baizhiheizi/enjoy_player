import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _workflowDirectory = '.github/workflows';

class _WorkflowGate {
  const _WorkflowGate({
    required this.file,
    required this.pattern,
    required this.paths,
  });

  final String file;
  final RegExp pattern;
  final List<String> paths;
}

void main() {
  final gates = _gatedWorkflows();

  test('at least one workflow gates its checks on a PATTERN', () {
    expect(gates, isNotEmpty);
  });

  test('every gated workflow declares a parsable paths filter', () {
    for (final gate in gates) {
      expect(
        gate.paths,
        isNotEmpty,
        reason:
            '${gate.file} declares a PATTERN but no paths: entries could '
            'be parsed, so the guard would stop guarding.',
      );
    }
  });

  test('every paths entry is matched by the workflow PATTERN', () {
    for (final gate in gates) {
      for (final path in gate.paths) {
        expect(
          gate.pattern.hasMatch(path),
          isTrue,
          reason:
              '${gate.file}: "$path" triggers the workflow on push but is '
              'not matched by PATTERN ${gate.pattern.pattern}, so a pull '
              'request touching only that path would skip its checks.',
        );
      }
    }
  });

  test('every literal paths entry points at an existing path', () {
    for (final gate in gates) {
      for (final path in gate.paths) {
        if (path.contains('*')) continue;
        expect(
          File(path).existsSync() || Directory(path).existsSync(),
          isTrue,
          reason:
              '${gate.file}: "$path" is listed in a paths filter but does '
              'not exist in the repository.',
        );
      }
    }
  });
}

List<_WorkflowGate> _gatedWorkflows() {
  final gates = <_WorkflowGate>[];
  for (final entity in Directory(_workflowDirectory).listSync()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.yml')) continue;
    final source = entity.readAsStringSync();
    final pattern = _parsePattern(source);
    if (pattern == null) continue;
    gates.add(
      _WorkflowGate(
        file: entity.path,
        pattern: RegExp(pattern),
        paths: _parsePathsEntries(source),
      ),
    );
  }
  gates.sort((a, b) => a.file.compareTo(b.file));
  return gates;
}

String? _parsePattern(String source) {
  final matcher = RegExp(r"^\s*PATTERN:\s*'(.*)'\s*$");
  for (final line in source.split('\n')) {
    final match = matcher.firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

List<String> _parsePathsEntries(String source) {
  final lines = source.split('\n');
  final entries = <String>[];
  var inOnBlock = false;
  var onIndent = 0;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    if (!inOnBlock) {
      if (trimmed == 'on:') {
        inOnBlock = true;
        onIndent = indent;
      }
      continue;
    }
    if (indent <= onIndent) break;
    if (trimmed != 'paths:') continue;
    for (var entry = index + 1; entry < lines.length; entry++) {
      final entryLine = lines[entry];
      if (entryLine.trim().isEmpty) continue;
      final entryIndent = entryLine.length - entryLine.trimLeft().length;
      if (entryIndent <= indent) break;
      final entryText = entryLine.trim();
      if (!entryText.startsWith('- ')) break;
      entries.add(_unquote(entryText.substring(2).trim()));
    }
  }
  return entries;
}

String _unquote(String value) {
  if (value.length >= 2) {
    final first = value[0];
    if ((first == '"' || first == "'") && value.endsWith(first)) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}
