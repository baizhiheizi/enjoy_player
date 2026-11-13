import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _workflowPath = '.github/workflows/ci.yml';
const _mergeScriptPath = '.github/scripts/merge_shard_lcov.sh';
const _splitScriptPath = '.github/scripts/split_test_shards.sh';

void main() {
  final workflow = File(_workflowPath).readAsStringSync();
  final runLines = workflow
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .where((line) => line.contains('flutter test'))
      .toList();

  test('every flutter test leg carries the host lane cap', () {
    expect(runLines, isNotEmpty);
    for (final line in runLines) {
      expect(
        line,
        contains('--concurrency=6'),
        reason:
            '$line\nA leg without the cap falls back to cores/2 and '
            'oversubscribes the shared 24-core host beyond the 12-lane '
            'budget (ADR-0105).',
      );
      expect(
        line,
        isNot(contains('--total-shards')),
        reason:
            '$line\n--total-shards slices by case inside every file, so '
            'each shard still compiles the whole suite; shards must be '
            'explicit disjoint file lists.',
      );
    }
  });

  test('the shard matrix and the file split agree on four shards', () {
    final matrixMatch = RegExp(
      r'shard-index: \[0, 1, 2, 3\]',
    ).firstMatch(workflow);
    expect(
      matrixMatch,
      isNotNull,
      reason:
          'the test matrix must keep exactly four legs matching the '
          'split_test_shards.sh total',
    );
    expect(
      RegExp(
        r'split_test_shards\.sh "\$\{\{ matrix\.shard-index \}\}" 4',
      ).hasMatch(workflow),
      isTrue,
      reason: 'the split total must stay in sync with the four matrix legs',
    );
  });

  test('the gates job merges coverage by union, not concatenation', () {
    expect(workflow, contains('merge_shard_lcov.sh'));
    expect(File(_mergeScriptPath).existsSync(), isTrue);
    expect(File(_splitScriptPath).existsSync(), isTrue);
    expect(
      File(_mergeScriptPath).readAsStringSync(),
      contains('LH:%d'),
      reason:
          'the merge must recompute LH from the merged DA hits so the '
          'gate script sums true totals',
    );
  });

  test('the required aggregate only accepts success or skipped', () {
    final jobStart = workflow.indexOf('  analyze-test:');
    expect(
      jobStart,
      greaterThanOrEqualTo(0),
      reason: 'the zero-step aggregate keeps the required check name',
    );
    final block = workflow.substring(jobStart);
    expect(block, contains('needs: [analyze, test, path-packages, gates]'));
    expect(block, contains('join(needs.*.result'));
    expect(block, contains('[ "\$result" != success ]'));
    expect(block, contains('[ "\$result" != skipped ]'));
  });

  test(
    'merge_shard_lcov.sh unions records for a file two shards both cover',
    () async {
      if (Platform.isWindows) {
        return;
      }
      final dir = await Directory.systemTemp.createTemp('lcov_merge_test_');
      addTearDown(() => dir.delete(recursive: true));
      File('${dir.path}/a.info').writeAsStringSync('''
SF:lib/a.dart
DA:1,1
DA:2,0
DA:3,1
LF:3
LH:2
end_of_record
SF:lib/shared.dart
DA:10,1
DA:11,0
LF:20
LH:1
end_of_record
''');
      File('${dir.path}/b.info').writeAsStringSync('''
SF:lib/shared.dart
DA:10,1
DA:11,1
DA:12,0
LF:20
LH:2
end_of_record
SF:lib/b.dart
DA:5,1
LF:5
LH:1
end_of_record
''');

      final result = await Process.run('bash', [
        _mergeScriptPath,
        '${dir.path}/merged.info',
        '${dir.path}/a.info',
        '${dir.path}/b.info',
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final merged = File('${dir.path}/merged.info').readAsStringSync();
      expect('SF:lib/shared.dart'.allMatches(merged), hasLength(1));
      expect('SF:lib/a.dart'.allMatches(merged), hasLength(1));
      expect('SF:lib/b.dart'.allMatches(merged), hasLength(1));
      expect('DA:10,1'.allMatches(merged), hasLength(1));
      expect(merged, contains('DA:11,1'));
      expect(merged, contains('DA:12,0'));
      expect(merged, contains('LF:20'));

      var lf = 0;
      var lh = 0;
      for (final line in merged.split('\n')) {
        if (line.startsWith('LF:')) lf += int.parse(line.substring(3));
        if (line.startsWith('LH:')) lh += int.parse(line.substring(3));
      }
      expect(lf, 28);
      expect(lh, 5);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
