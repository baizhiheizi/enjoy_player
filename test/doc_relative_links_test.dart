import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('every relative markdown link under docs/ resolves to a real path', () {
    final broken = <String>[];

    for (final file in _markdownFiles()) {
      final text = file.readAsStringSync();
      for (final target in _relativeLinkTargets(text)) {
        final resolved = _resolve(file, target);
        if (!File(resolved).existsSync() && !Directory(resolved).existsSync()) {
          broken.add('${file.path.replaceAll(r'\', '/')} -> $target');
        }
      }
    }

    expect(
      broken,
      isEmpty,
      reason:
          'These relative links point at paths that do not exist in the '
          'repository. Either the target moved or the link is stale:\n'
          '${broken.join('\n')}',
    );
  });
}

List<File> _markdownFiles() {
  final files = <File>[File('README.md')];
  final docs = Directory('docs');
  if (!docs.existsSync()) {
    return files;
  }
  for (final entity in docs.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.md')) {
      files.add(entity);
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Iterable<String> _relativeLinkTargets(String text) sync* {
  final withoutFences = text.replaceAll(
    RegExp(r'```[\s\S]*?```|~~~[\s\S]*?~~~'),
    '',
  );
  final pattern = RegExp(r'\[[^\]\n]*\]\(([^)\s]+)\)');
  for (final match in pattern.allMatches(withoutFences)) {
    final target = match.group(1)!;
    if (target.startsWith('#') ||
        target.contains('://') ||
        target.startsWith('mailto:')) {
      continue;
    }
    yield target;
  }
}

String _resolve(File file, String target) {
  final withoutAnchor = target.split('#').first;
  var decoded = withoutAnchor;
  try {
    decoded = Uri.decodeComponent(withoutAnchor);
  } on ArgumentError {
    decoded = withoutAnchor;
  }
  return p.normalize(p.join(p.dirname(file.path), decoded));
}
