import 'dart:math' as math;
import 'dart:typed_data';

import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';

final RegExp _apostropheRegExp = RegExp(r"['’]");
final RegExp _punctRegExp = RegExp(r'[.,!?;:"()[\]{}<>—–-]');
final RegExp _whitespaceRegExp = RegExp(r'\s+');

String dictationWordOf(String word) {
  return word
      .toLowerCase()
      .replaceAll(_apostropheRegExp, '')
      .replaceAll(_punctRegExp, '');
}

List<String> tokenizeDictationWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  return trimmed
      .split(_whitespaceRegExp)
      .where((w) => w.isNotEmpty && dictationWordOf(w).isNotEmpty)
      .toList();
}

int countDictationWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  var count = 0;
  for (final token in trimmed.split(_whitespaceRegExp)) {
    if (token.isNotEmpty && dictationWordOf(token).isNotEmpty) {
      count++;
    }
  }
  return count;
}

DictationDiffResult computeDictationDiff(
  String referenceText,
  String userInput,
) {
  final refRawTokens = tokenizeDictationWords(referenceText);
  final userRawTokens = tokenizeDictationWords(userInput);

  final m = refRawTokens.length;
  final n = userRawTokens.length;

  if (m == 0 && n == 0) {
    return const DictationDiffResult(
      tokens: [],
      accuracy: 100,
      correctWords: 0,
      missedWords: 0,
      extraWords: 0,
    );
  }

  final refNorm = [for (final token in refRawTokens) dictationWordOf(token)];
  final userNorm = [for (final token in userRawTokens) dictationWordOf(token)];
  final stride = n + 1;
  final dp = Int32List((m + 1) * stride);

  for (var i = 0; i <= m; i++) {
    dp[i * stride] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[j] = j;
  }

  for (var i = 1; i <= m; i++) {
    final rowOffset = i * stride;
    final prevRowOffset = (i - 1) * stride;
    final refWord = refNorm[i - 1];
    for (var j = 1; j <= n; j++) {
      if (refWord == userNorm[j - 1]) {
        dp[rowOffset + j] = dp[prevRowOffset + j - 1];
      } else {
        dp[rowOffset + j] =
            1 +
            math.min(
              dp[prevRowOffset + j - 1],
              math.min(dp[prevRowOffset + j], dp[rowOffset + j - 1]),
            );
      }
    }
  }

  var i = m;
  var j = n;
  final reversedTokens = <DictationDiffToken>[];

  var correct = 0;
  var missed = 0;
  var extra = 0;

  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final diag = (i - 1) * stride + j - 1;
      if (refNorm[i - 1] == userNorm[j - 1] && dp[i * stride + j] == dp[diag]) {
        reversedTokens.add(
          DictationDiffToken(
            word: refRawTokens[i - 1],
            op: DictationWordDiffOp.correct,
          ),
        );
        correct++;
        i--;
        j--;
        continue;
      }
    }

    if (j > 0 && (i == 0 || dp[i * stride + j] == dp[i * stride + j - 1] + 1)) {
      reversedTokens.add(
        DictationDiffToken(
          word: userRawTokens[j - 1],
          op: DictationWordDiffOp.extra,
        ),
      );
      extra++;
      j--;
    } else if (i > 0 &&
        (j == 0 || dp[i * stride + j] == dp[(i - 1) * stride + j] + 1)) {
      reversedTokens.add(
        DictationDiffToken(
          word: refRawTokens[i - 1],
          op: DictationWordDiffOp.missed,
        ),
      );
      missed++;
      i--;
    } else {
      reversedTokens.add(
        DictationDiffToken(
          word: userRawTokens[j - 1],
          op: DictationWordDiffOp.extra,
        ),
      );
      extra++;
      reversedTokens.add(
        DictationDiffToken(
          word: refRawTokens[i - 1],
          op: DictationWordDiffOp.missed,
        ),
      );
      missed++;
      i--;
      j--;
    }
  }

  final tokens = reversedTokens.reversed.toList();
  final totalWords = m;
  final accuracy = (totalWords + extra) > 0
      ? ((correct / (totalWords + extra)) * 100).round().clamp(0, 100)
      : 0;

  return DictationDiffResult(
    tokens: tokens,
    accuracy: accuracy,
    correctWords: correct,
    missedWords: missed,
    extraWords: extra,
  );
}
