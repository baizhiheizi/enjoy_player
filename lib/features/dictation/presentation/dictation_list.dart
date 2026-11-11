import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DictationList extends StatefulWidget {
  const DictationList({
    super.key,
    required this.attempts,
    required this.selectedAttempt,
    required this.onSelectAttempt,
  });

  final List<DictationRow> attempts;
  final DictationRow? selectedAttempt;
  final ValueChanged<DictationRow?> onSelectAttempt;

  @override
  State<DictationList> createState() => _DictationListState();
}

class _DictationListState extends State<DictationList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.attempts.isEmpty) return const SizedBox.shrink();

    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final count = widget.attempts.length;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.playerDictationPreviousAttempts(count) ??
                        'Previous dictations ($count)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: t.ink2,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: [
                  for (final attempt in widget.attempts)
                    _buildAttemptTile(attempt, t, l10n),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttemptTile(
    DictationRow attempt,
    EnjoyThemeTokens t,
    AppLocalizations? l10n,
  ) {
    final isSelected = widget.selectedAttempt?.id == attempt.id;
    final accuracy = attempt.accuracy;

    return InkWell(
      onTap: () => widget.onSelectAttempt(isSelected ? null : attempt),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? t.originalSoft.withValues(alpha: 0.3) : t.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? t.original : t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accuracy >= 80 ? t.originalSoft : t.sunk,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$accuracy%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accuracy >= 80 ? t.originalInk : t.ink,
                    ),
                  ),
                ),
                Text(
                  _formatDate(attempt.createdAt),
                  style: TextStyle(fontSize: 11, color: t.ink3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              attempt.userInput,
              style: TextStyle(fontSize: 13, color: t.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${attempt.correctWords} correct',
                  style: TextStyle(fontSize: 11, color: t.originalInk),
                ),
                const SizedBox(width: 8),
                Text(
                  '${attempt.missedWords} missed',
                  style: TextStyle(fontSize: 11, color: t.danger),
                ),
                const SizedBox(width: 8),
                Text(
                  '${attempt.extraWords} extra',
                  style: TextStyle(fontSize: 11, color: t.youInk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
