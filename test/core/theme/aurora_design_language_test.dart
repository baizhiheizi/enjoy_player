import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Walks [libDir] and returns every `.dart` source file, skipping generated
/// `.g.dart` / `.freezed.dart` output.
List<File> _dartSources(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !f.path.endsWith('.g.dart'))
    .where((f) => !f.path.endsWith('.freezed.dart'))
    .toList();

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (Directory('${dir.path}/lib').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('could not locate the repo root from ${dir.path}');
    }
    dir = parent;
  }
}

void main() {
  final root = Directory(_repoRoot());
  final lib = Directory('${root.path}/lib');
  final sources = _dartSources(lib);

  test('lib/ was discovered', () {
    expect(sources.length, greaterThan(200));
  });

  test('no Material ink ripple: InkWell is banned in lib/ (ADR-0089 §6)', () {
    final offenders = <String>[];
    for (final f in sources) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('InkWell(')) {
          offenders.add('${f.path.replaceFirst('${root.path}/', '')}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use EnjoyPressable / EnjoyTappableSurface instead of Material '
          'InkWell — the app paints no ink ripples.\n${offenders.join('\n')}',
    );
  });

  test('no Material Icons in lib/ (ADR-0089 §4)', () {
    final offenders = <String>[];
    for (final f in sources) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('Icons.')) continue;
        if (line.contains('EnjoyIcons.')) continue;
        if (line.trimLeft().startsWith('//') ||
            line.trimLeft().startsWith('*')) {
          continue;
        }
        offenders.add('${f.path.replaceFirst('${root.path}/', '')}:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use the EnjoyIcons facade, not Material Icons.\n'
          '${offenders.join('\n')}',
    );
  });

  test('mono text goes through enjoyMonoStyle, not a raw fontFamily', () {
    final offenders = <String>[];
    for (final f in sources) {
      if (f.path.contains('${lib.path}/core/theme/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains("fontFamily: 'monospace'")) {
          offenders.add('${f.path.replaceFirst('${root.path}/', '')}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          "Geist Mono is the app's only mono face (ADR-0089 §3) — use "
          'enjoyMonoStyle(context). lib/core/theme/ is exempt because the '
          'type system itself lives there: TranscriptTypographyTokens '
          'carries a last-resort generic mono default for the case where no '
          'theme extension is installed.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no hard-coded colors outside lib/core/theme/ (ADR-0089 §1)', () {
    final offenders = <String>[];
    for (final f in sources) {
      if (f.path.contains('${lib.path}/core/theme/')) continue;
      if (f.path.endsWith('${lib.path}/core/notices/app_notice.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Color(0x')) {
          offenders.add('${f.path.replaceFirst('${root.path}/', '')}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Address color by role on EnjoyThemeTokens instead of a literal. '
          'lib/core/theme/ is exempt because the palette itself lives there; '
          'app_notice.dart is exempt because ADR-0089 §9 sanctions the dark '
          'toast as its own surface, and appNoticeBackground() centralizes '
          'its two brightness values in one pure function.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no print() in lib/ (AGENTS.md logging rule)', () {
    final offenders = <String>[];
    for (final f in sources) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trimLeft();
        if (!trimmed.startsWith('print(')) continue;
        offenders.add('${f.path.replaceFirst('${root.path}/', '')}:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use logNamed from core/logging/log.dart.\n'
          '${offenders.join('\n')}',
    );
  });
}
