import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Walks [libDir] and returns every `.dart` source file, skipping generated
/// `.g.dart` / `.freezed.dart` output.
List<File> _dartSources(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !f.path.endsWith('.g.dart'))
    .where((f) => !f.path.endsWith('.freezed.dart'))
    .toList();

String _relativePosix(Directory root, File f) =>
    p.posix.joinAll(p.split(p.relative(f.path, from: root.path)));

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

  test('no Material ink ripple: InkWell is banned in lib/ (ADR-0093)', () {
    final offenders = <String>[];
    for (final f in sources) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('InkWell(')) {
          offenders.add('${_relativePosix(root, f)}:${i + 1}');
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

  test('no Material Icons in lib/ (ADR-0093)', () {
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
        offenders.add('${_relativePosix(root, f)}:${i + 1}');
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
      if (_relativePosix(root, f).startsWith('lib/core/theme/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains("fontFamily: 'monospace'")) {
          offenders.add('${_relativePosix(root, f)}:${i + 1}');
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
      if (_relativePosix(root, f).startsWith('lib/core/theme/')) continue;
      if (_relativePosix(root, f) == 'lib/core/notices/app_notice.dart') {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Color(0x')) {
          offenders.add('${_relativePosix(root, f)}:${i + 1}');
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

  test('no Material SegmentedButton in lib/ (ADR-0093)', () {
    const exempt = {
      'lib/features/ai/presentation/settings/widgets/llm_byok_form.dart',
      'lib/features/ai/presentation/settings/widgets/speech_byok_form.dart',
    };
    final offenders = <String>[];
    for (final f in sources) {
      final relative = _relativePosix(root, f);
      if (exempt.contains(relative)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'SegmentedButton(?!ThemeData)').hasMatch(lines[i])) {
          offenders.add('$relative:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use EnjoySegmentedControl / EnjoySegment — the Duet sliding-thumb '
          'primitive. The two AI BYOK pickers are exempt because their labels '
          'need the two lines a fixed-height Duet segment cannot give them.\n'
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
        offenders.add('${_relativePosix(root, f)}:${i + 1}');
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

  test(
    'no BackdropFilter or ImageFilter.blur in the player, transcript, or shadow reading',
    () {
      final scanned = <String>[
        'lib/features/player',
        'lib/features/transcript',
        'lib/features/shadow_reading',
      ];
      final offenders = <String>[];
      for (final dir in scanned) {
        for (final f in _dartSources(Directory('${root.path}/$dir'))) {
          final lines = f.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains('BackdropFilter') ||
                line.contains('ImageFilter.blur')) {
              offenders.add('${_relativePosix(root, f)}:${i + 1}');
            }
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Duet paints hidden text as shapes and flat surfaces; blur filters '
            'are banned.\n${offenders.join('\n')}',
      );
    },
  );

  test('no references to deleted Aurora symbols', () {
    const deleted = [
      'AuroraGlow',
      'GlassSurface',
      'PlayerAmbientBackdrop',
      'GlobalTransportBar',
      'TransportProgressStrip',
      'NarrowTransportBudget',
      'PlayerCollapseControl',
      'PlayerFrostedBackButton',
    ];
    final offenders = <String>[];
    for (final f in sources) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final symbol in deleted) {
          if (lines[i].contains(symbol)) {
            offenders.add(
              '${_relativePosix(root, f)}:${i + 1} '
              '$symbol',
            );
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
