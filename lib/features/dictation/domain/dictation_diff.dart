import 'dart:math' as math;
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';

String dictationWordOf(String word) {
  return word
      .toLowerCase()
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[.,!?;:"()[\]{}<>—–-]'), '');
}

List<String> tokenizeDictationWords(String text) {
  return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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

  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }

  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final refNorm = dictationWordOf(refRawTokens[i - 1]);
      final userNorm = dictationWordOf(userRawTokens[j - 1]);
      if (refNorm == userNorm) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] =
            1 +
            math.min(dp[i - 1][j - 1], math.min(dp[i - 1][j], dp[i][j - 1]));
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
      final refNorm = dictationWordOf(refRawTokens[i - 1]);
      final userNorm = dictationWordOf(userRawTokens[j - 1]);
      if (refNorm == userNorm && dp[i][j] == dp[i - 1][j - 1]) {
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

    if (j > 0 && (i == 0 || dp[i][j] == dp[i][j - 1] + 1)) {
      reversedTokens.add(
        DictationDiffToken(
          word: userRawTokens[j - 1],
          op: DictationWordDiffOp.extra,
        ),
      );
      extra++;
      j--;
    } else if (i > 0 && (j == 0 || dp[i][j] == dp[i - 1][j] + 1)) {
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
